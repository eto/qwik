#
# Copyright (C) 2002-2004 Satoru Takabayashi <satoru@namazu.org> 
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

require 'socket'

$LOAD_PATH << '..' unless $LOAD_PATH.include?('..')

module QuickML
  class Sendmail
    def self.send_mail (smtp_host, smtp_port, logger, optional = {})
      mail_from = optional[:mail_from]
      recipients = optional[:recipients]
      header = optional[:header]
      body = optional[:body]
      if optional[:recipient]
	raise unless optional[:recipient].kind_of?(String)
	recipients = [optional[:recipient]] 
      end
      raise if mail_from.nil? or recipients.nil? or body.nil? or header.nil?

      contents = ''
      header.each {|field|
	key = field.first
	value = field.last
	contents << "#{key}: #{value}\n" if key.kind_of?(String)
      }
      contents << "\n"
      contents << body
      so = nil
      begin
	sender = Sendmail.new(smtp_host, smtp_port, true)
	so = sender.send(contents, mail_from, recipients)
      rescue => e
	logger.log "Error: Unable to send mail: #{e.class}: #{e.message}"
      end

      return so		# Only for test
    end

    def initialize (smtp_host, smtp_port, use_xverp = false, test = false)
      @smtp_port = smtp_port
      @smtp_host = smtp_host
      @use_xverp = use_xverp
      @xverp_available = false
      @test = test
      @test = true if defined?($test) && $test
    end

    def send (message, mail_from, recipients)
      s = open_socket
      send_to_socket(s, message, mail_from, recipients)
      return s		# for test
    end

    def open_socket(test=false)
      test = true if @test
      host, port = @smtp_host, @smtp_port
      if test
	s = MockSendmail.open(host, port)
	$ml_sm = s	# only for test
      else
	s = TCPSocket.open(host, port)
      end
      return s
    end

    def send_to_socket(s, message, mail_from, recipients)
      recipients = [recipients] if recipients.kind_of?(String)

      send_command(s, nil, 220)

      if @test
	myhostname = 'sender'
      else
	myhostname = Socket.gethostname
      end

      send_command(s, "EHLO #{myhostname}", 250)

      if @use_xverp and @xverp_available and (not mail_from.empty?)
        send_command(s, "MAIL FROM: <#{mail_from}> XVERP===", 250)
      else
        send_command(s, "MAIL FROM: <#{mail_from}>", 250)
      end

      recipients.each {|recipient|
        send_command(s, "RCPT TO: <#{recipient}>", 250)
      }

      send_command(s, 'DATA', 354)

      message.each_line {|line|
        line.sub!(/\r?\n/, "")
        line.sub!(/^\./, '..')
        line << "\r\n"
        s.print(line)
      }

      send_command(s, '.', 250)
      send_command(s, 'QUIT', 221)

      s.close
    end

    private

    def send_command (s, command, code)
      s.print(command + "\r\n") if command
      begin
        line = s.gets
        @xverp_available = true if /^250-XVERP/.match(line)
      end while line[3] == ?-

      return_code = line[0,3].to_i
      if return_code == code
        line
      else
        raise "smtp-error: #{command} => #{line}"
      end
    end

  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  require 'qwik/mock-sendmail'
  $test = true
end

if defined?($test) && $test
  class TestMLSendmail < Test::Unit::TestCase
    def sm(*args)
      return QuickML::Sendmail.send_mail(*args)
    end

    def test_all
      s = QuickML::Sendmail.new('localhost', 25, false, true)
      so = s.send('', '', '')
      ok_eq(["EHLO sender", "MAIL FROM: <>", "RCPT TO: <>",
	      'DATA', '.', 'QUIT'], so.buffer)

      message =
'To: bob@example.com
From: alice@example.com
Subject: test

This is a test.
'
      s = QuickML::Sendmail.new('localhost', 25, false, true)
      so = s.send(message, 'alice@example.com', 'bob@example.com')
      ok_eq(["EHLO sender", "MAIL FROM: <alice@example.com>",
	      "RCPT TO: <bob@example.com>", 'DATA',
	      'To: bob@example.com', 'From: alice@example.com',
	      'Subject: test', '', 'This is a test.', '.', 'QUIT'],
	    so.buffer)

      so = sm('localhost', 25, nil,
	      :mail_from => '', :recipient => '', :header => [], :body => '')
      ok_eq(["EHLO sender", "MAIL FROM: <>", "RCPT TO: <>",
	      'DATA', '', '.', 'QUIT'], so.buffer)

      so = sm('localhost', 25, nil,
	      :mail_from => 'alice@example.com',
	      :recipient => 'bob@example.com', :header => [], :body => message)
      ok_eq(["EHLO sender", "MAIL FROM: <alice@example.com>",
	      "RCPT TO: <bob@example.com>", 'DATA', '',
	      'To: bob@example.com', 'From: alice@example.com',
	      'Subject: test', '', 'This is a test.', '.', 'QUIT'],
	    so.buffer)
    end
  end
end
