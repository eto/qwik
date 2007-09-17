#
# Copyright (C) 2002-2004 Satoru Takabayashi <satoru@namazu.org> 
# Copyright (C) 2003-2006 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'
require 'qwik/ml-gettext'
require 'qwik/mail'
require 'qwik/ml-exception'
#require 'qwik/util-basic'
require 'qwik/util-safe'
require 'qwik/util-string'
require 'qwik/util-time'
require 'time'

#require 'kconv'
#require 'net/smtp'
require 'socket'
require 'timeout'

class TCPSocket
  def address
    return peeraddr[3]
  end

  def hostname
    return peeraddr[2]
  end
end

module QuickML
  class TooLargeMail < StandardError; end

  class SmtpSession
    include GetText

    COMMAND_TABLE = [:helo, :ehlo, :noop, :quit, :rset, :rcpt, :mail, :data]

    def initialize (config, logger, catalog, socket)
      @config = config
      @logger = logger
      @catalog = catalog
      @socket = socket

      @server_name = 'QuickML'

      @hello_host = 'hello.host.invalid'
      @protocol = nil
      @peer_hostname = @socket.hostname
      @peer_address = @socket.address
      @remote_host = (@peer_hostname or @peer_address)

      @data_finished = false
      @my_hostname = 'localhost'
      @my_hostname = Socket.gethostname if @config.ml_port == 25
      @message_charset = nil
    end

    def start
      elapsed = calc_time {
	_start
      }
      @logger.vlog "Session finished: #{elapsed} sec."
    end

    private

    def calc_time
      start_time = Time.now
      yield
      elapsed = Time.now - start_time
      return elapsed
    end

    def _start
      begin
	def_puts(@socket)
	connect
	timeout(@config.timeout) {
	  process
	}
      rescue TimeoutError
	@logger.vlog "Timeout: #{@remote_host}"
      ensure
	close
      end
    end

    def def_puts(socket)
      def socket.puts(*objs)
	objs.each {|x|
	  begin
	    self.print x.xchomp, "\r\n"
	  rescue Errno::EPIPE
	  end
	}
      end
    end

    def connect
      @socket.puts "220 #{@my_hostname} ESMTP #{@server_name}"
      @logger.vlog "Connect: #{@remote_host}"
    end

    def process
      until @socket.closed?
	begin
	  mail = Mail.new
	  receive_mail(mail)
	  if mail.valid?
	    process_mail(@config, mail)
	  end
	rescue TooLargeMail
	  cleanup_connection
	  report_too_large_mail(mail) if mail.valid?
	  @logger.log "Too Large Mail: #{mail.from}"
	rescue TooLongLine
	  cleanup_connection
	  @logger.log "Too Long Line: #{mail.from}"
	end
      end
    end

    def receive_mail (mail)
      while line = @socket.safe_gets
	line = line.xchomp
	command, arg = line.split(/\s+/, 2)
	return if command.nil? || command.empty?
	command = command.downcase.intern  # 'HELO' => :helo
	if COMMAND_TABLE.include?(command)
	  @logger.vlog "Command: #{line}"
	  send(command, mail, arg)
	else
	  @logger.vlog "Unknown SMTP Command: #{command} #{arg}"
	  @socket.puts '502 Error: command not implemented'
	end
	break if command == :quit or command == :data
      end
    end

    # Abstract
    def process_mail(config, mail)
      # do nothing.
    end

    def helo (mail, arg)
      return if arg.nil?
      @hello_host = arg.split.first
      @socket.puts "250 #{@my_hostname}"
      @protocol = 'SMTP'
    end

    def ehlo (mail, arg)
      @hello_host = arg.split.first
      @socket.puts "250-#{@my_hostname}"
      @socket.puts '250 PIPELINING'
      @protocol = 'ESMTP'
    end

    def noop (mail, arg)
      @socket.puts '250 ok'
    end

    def quit (mail, arg)
      @socket.puts '221 Bye'
      close
    end

    def rset (mail, arg)
      mail.mail_from = nil
      mail.clear_recipients
      @socket.puts '250 ok'
    end

    def rcpt (mail, arg)
      if mail.mail_from.nil?
	@socket.puts '503 Error: need MAIL command'
      elsif /^To:\s*<(.*)>/i =~ arg or /^To:\s*(.*)/i =~ arg
	address = $1
	if Mail.address_of_domain?(address, @config.ml_domain)
	  mail.add_recipient(address)
	  @socket.puts '250 ok'
	else
	  @socket.puts "554 <#{address}>: Recipient address rejected"
	  @logger.vlog "Unacceptable RCPT TO:<#{address}>"
	end
      else
	@socket.puts "501 Syntax: RCPT TO: <address>"
      end
    end

    def mail (mail, arg)
      if @protocol.nil?
	@socket.puts '503 Error: send HELO/EHLO first'
      elsif /^From:\s*<(.*)>/i =~ arg or /^From:\s*(.*)/i =~ arg 
	mail.mail_from = $1
	@socket.puts '250 ok'
      else
	@socket.puts "501 Syntax: MAIL FROM: <address>"
      end
    end

    def data (mail, arg)
      if mail.recipients.empty?
	@socket.puts '503 Error: need RCPT command'
      else
	@socket.puts '354 send the mail data, end with .';
	begin
	  read_mail(mail)
	ensure
	  @message_charset = mail.charset
	end
	@socket.puts '250 ok'
      end
    end

    def read_mail (mail)
      len = 0
      lines = []
      while line = @socket.safe_gets
	break if end_of_data?(line)
	len += line.length
	if @config.max_mail_length < len
	  mail.read(lines.join('')) # Generate a header for an error report.
	  raise TooLargeMail 
	end
	line.sub!(/^\.\./, '.') # unescape
	line = line.normalize_eol
	lines << line
	# I do not know why but constructing mail_string with
	# String#<< here is very slow.
	# mail_string << line  
      end
      mail_string = lines.join('')
      @data_finished = true
      mail.read(mail_string)
      mail.unshift_field('Received', received_field)
    end

    def end_of_data? (line)
     #return line.xchomp == '.'
      return line == ".\r\n"
    end

    def received_field
      received_field_internal(@hello_host, @peer_hostname, @peer_address,
			      @my_hostname, @server_name, @protocol,
			      Time.now.rfc2822)
    end

    def received_field_internal(hello_host, peer_hostname, peer_address,
				my_hostname, server_name, protocol, time)
      "from #{hello_host} (#{peer_hostname} [#{peer_address}])
	by #{my_hostname} (#{server_name}) with #{protocol};
	#{time}%s"
    end

    def cleanup_connection
      unless @data_finished
	discard_data
      end
      @socket.puts '221 Bye'
      close
    end

    def discard_data
      begin
	while line = @socket.safe_gets
	  break if end_of_data?(line)
	end
      rescue TooLongLine
	retry
      end
    end

    # Abstract
    def report_too_large_mail (mail)
      # do nothing.
    end

    def close
      return if @socket.closed?
      @socket.close
      @logger.vlog "Closed: #{@remote_host}"
    end
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  require 'qwik/mock-socket'
  require 'qwik/mock-logger'
  require 'qwik/config'
  require 'qwik/qp'
  require 'pp'
  $test = true
end

if defined?($test) && $test
  class TestSmtpSession < Test::Unit::TestCase
    def test_all
      config = Qwik::Config.new
      logger = QuickML::MockLogger.new
      hash = {
	:logger		=> logger,
	:sites_dir	=> '.',
      }
      config.update(hash)

      socket = QuickML::MockSocket.new "HELO localhost
MAIL FROM: user@example.net
RCPT TO: test@example.com
DATA
To: test@example.com
From: user@example.net
Subject: create

create new ML.
.
QUIT
"
      session = QuickML::SmtpSession.new(config, logger, config.catalog, socket)
      session.start
    end
  end
end
