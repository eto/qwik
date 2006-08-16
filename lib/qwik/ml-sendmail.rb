#
# Copyright (C) 2002-2004 Satoru Takabayashi <satoru@namazu.org> 
# Copyright (C) 2003-2006 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

require 'socket'

$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'

module QuickML
  class Sendmail
    def self.send_mail (smtp_host, smtp_port, logger, mail)
      validate_mail(mail)

      msg = build_message(mail)

      result = nil
      begin
	#sender = Sendmail.new(smtp_host, smtp_port, true)
	#result = sender.send(msg, mail[:mail_from], mail[:recipient])

	config = Sendmail.prepare_config(smtp_host, smtp_port, true)
	s = Sendmail.open_socket(config)
	Sendmail.send_to_socket(config, s, msg,
				mail[:mail_from], mail[:recipient])
	result = s
      rescue => e
	logger.log "Error: Unable to send mail: #{e.class}: #{e.message}"
      end

      return result	# Only for test
    end

    def initialize (smtp_host, smtp_port, use_xverp = false, test = false)
      @config = Sendmail.prepare_config(smtp_host, smtp_port, use_xverp, test)
    end

    def send (message, mail_from, recipients)
      s = Sendmail.open_socket(@config)
      Sendmail.send_to_socket(@config, s, message, mail_from, recipients)
      return s		# Only for test.
    end

    private

    def self.validate_mail(mail)
      if mail[:mail_from].nil? ||
	  mail[:recipient].nil? ||
	  mail[:header].nil? ||
	  mail[:body].nil?
	raise "Missing mail header."
      end

      mail[:recipient] = [mail[:recipient]] if mail[:recipient].kind_of?(String)
    end

    def self.build_message(mail)
      return mail[:header].map {|field|
	key, value = field
	"#{key}: #{value}\n"
      }.join+"\n"+mail[:body]
    end

    def self.prepare_config(smtp_host, smtp_port,
			    use_xverp = false, test = false)
      test = true if defined?($test) && $test
      return {
	:smtp_port => smtp_port,
	:smtp_host => smtp_host,
	:use_xverp => use_xverp,
	:xverp_available => false,
	:test => test,
      }
    end

    def self.open_socket(c)
      klass = c[:test] ? MockSendmail : TCPSocket
      s = $ml_sm = klass.open(c[:smtp_host], c[:smtp_port]) # $ml_sm is for test
      return s
    end

    def self.send_to_socket(c, s, message, mail_from, recipients)
      recipients = [recipients] if recipients.kind_of?(String)

      send_command(c, s, nil, 220)

      myhostname = c[:test] ? 'sender' : Socket.gethostname

      send_command(c, s, "EHLO #{myhostname}", 250)

      if c[:use_xverp] and c[:xverp_available] and (not mail_from.empty?)
        send_command(c, s, "MAIL FROM: <#{mail_from}> XVERP===", 250)
      else
        send_command(c, s, "MAIL FROM: <#{mail_from}>", 250)
      end

      recipients.each {|recipient|
        send_command(c, s, "RCPT TO: <#{recipient}>", 250)
      }

      send_command(c, s, 'DATA', 354)

      message.each_line {|line|
        line.sub!(/\r?\n/, "")
        line.sub!(/^\./, '..')
        line << "\r\n"
        s.print(line)
      }

      send_command(c, s, '.', 250)
      send_command(c, s, 'QUIT', 221)

      s.close
    end

    def self.send_command (c, s, command, code)
      s.print(command + "\r\n") if command
      begin
        line = s.gets
        c[:xverp_available] = true if /^250-XVERP/.match(line)
      end while line[3] == ?-

      return_code = line[0, 3].to_i
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
  require 'pp'
  $test = true
end

if defined?($test) && $test
  class TestMLSendmail < Test::Unit::TestCase
    def sm(*args)
      return QuickML::Sendmail.send_mail(*args)
    end

    def test_all
      c = QuickML::Sendmail

      # test_build_message
      eq "\n", c.build_message(:header=>[], :body=>'')
      eq "a: b\n\nc", c.build_message(:header=>[['a', 'b']], :body=>'c')
      eq "a: b\n\nc", c.build_message(:header=>[[:a, 'b']], :body=>'c')

      # test_send
      s = QuickML::Sendmail.new('localhost', 25, false, true)
      so = s.send('', '', '')
      is ["EHLO sender", "MAIL FROM: <>", "RCPT TO: <>",
	'DATA', '.', 'QUIT'], so.buffer

      message =
'To: bob@example.com
From: alice@example.com
Subject: test

This is a test.
'
      s = QuickML::Sendmail.new('localhost', 25, false, true)
      so = s.send(message, 'alice@example.com', 'bob@example.com')
      is ["EHLO sender", "MAIL FROM: <alice@example.com>",
	"RCPT TO: <bob@example.com>", 'DATA',
	'To: bob@example.com', 'From: alice@example.com',
	'Subject: test', '', 'This is a test.', '.', 'QUIT'],
	so.buffer

      so = sm('localhost', 25, nil,
	      :mail_from => '', :recipient => '', :header => [], :body => '')
      is ["EHLO sender", "MAIL FROM: <>", "RCPT TO: <>",
	'DATA', '', '.', 'QUIT'], so.buffer

      so = sm('localhost', 25, nil,
	      :mail_from => 'alice@example.com',
	      :recipient => 'bob@example.com', :header => [], :body => message)
      is ["EHLO sender", "MAIL FROM: <alice@example.com>",
	"RCPT TO: <bob@example.com>", 'DATA', '',
	'To: bob@example.com', 'From: alice@example.com',
	'Subject: test', '', 'This is a test.', '.', 'QUIT'],
	so.buffer
    end
  end
end
