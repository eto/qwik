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

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/mail'
require 'qwik/util-charset'

module Qwik
  class Sendmail
    def initialize(host, port, test=false)
      @host, @port = host, port
      @test = test
    end

    def send(mail)
      Sendmail.send(@host, @port, mail[:from], mail[:to], mail[:subject],
		    mail[:content], @test)
    end

    # FIXME: This method is too ad hoc.
    def self.send(host, port, from, to, subject, body, test)
      efrom    = QuickML::Mail.encode_field(from.to_s)
      eto      = QuickML::Mail.encode_field(to.to_s)
      esubject = QuickML::Mail.encode_field(subject)
      body = body.set_sourcecode_charset.to_mail_charset
      message =
"From: #{efrom}
To: #{eto}
Subject: #{esubject}
Content-Type: text/plain; charset=\"ISO-2022-JP\"

#{body}
"
      if test
	$smtp_sendmail = [host, port, efrom, eto, message]
	return message	# for debug
      end

      require 'net/smtp'
      Net::SMTP.start(host, port) {|smtp|
	smtp.send_mail(message, from, to)
      }
      return nil
    end
  end
end

class Sendmail
  def self.send_mail (smtp_host, smtp_port, logger, mail)
    validate_mail(mail)

    msg = build_message(mail)

    result = nil
    begin
      config = Sendmail.prepare_config(smtp_host, smtp_port, true)
      s = Sendmail.open_socket(config)

      myhostname = config[:test] ? 'sender' : Socket.gethostname

      Sendmail.send_to_socket(config, s, myhostname, msg,
			      mail[:mail_from], mail[:recipient])
      result = s
    rescue => e
      logger.log "Error: Unable to send mail: #{e.class}: #{e.message}"
    end

    if $test
      $quickml_sendmail = [smtp_host, smtp_port,
	mail[:mail_from], mail[:recipient], msg]
    end

    return result	# Only for test
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
    config = {
      :smtp_port => smtp_port,
      :smtp_host => smtp_host,
      :use_xverp => use_xverp,
      :xverp_available => false,
      :test => test,
    }
    return config
  end

  def self.open_socket(c)
    klass = c[:test] ? MockSmtpServer : TCPSocket
    s = $ml_sm = klass.open(c[:smtp_host], c[:smtp_port]) # $ml_sm is for test
    return s
  end

  def self.send_to_socket(c, s, myhostname, message, mail_from, recipients)
    recipients = [recipients] if recipients.kind_of?(String)

    send_command(c, s, nil, 220)

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

def Sendmail(*args)
  Sendmail.send_mail(*args)
end

if $0 == __FILE__
  require 'test/unit'
  require 'qwik/testunit'
  require 'qwik/mock-sendmail'
  require 'pp'
  $test = true
end

if defined?($test) && $test
  class TestSendmail < Test::Unit::TestCase
    def test_all
      sm = Qwik::Sendmail.new('127.0.0.1', '25', true)
      mail = {
	:from    => 'from@example.com',
	:to      => 'to@example.com',
	:subject => 'subject',
	:content => 'content',
      }
      assert_equal "From: from@example.com
To: to@example.com
Subject: subject
Content-Type: text/plain; charset=\"ISO-2022-JP\"

content
",
	sm.send(mail)

      mail = {
	:from    => 'from@example.com',
	:to      => 'to@example.com',
	:subject => '‘è–¼',
	:content => '–{•¶',
      }
      assert_equal "From: from@example.com
To: to@example.com
Subject: =?ISO-2022-JP?B?GyRCQmpMPhsoQg==?=
Content-Type: text/plain; charset=\"ISO-2022-JP\"

\e$BK\\J8\e(B
",
	sm.send(mail)
    end
  end
end

if defined?($test) && $test
  class TestSendmail < Test::Unit::TestCase
    def test_all
      c = Sendmail

      # test_build_message
      is "\n", c.build_message(:header=>[], :body=>'')
      is "a: b\n\nc", c.build_message(:header=>[['a', 'b']], :body=>'c')
      is "a: b\n\nc", c.build_message(:header=>[[:a, 'b']], :body=>'c')

      # test_send
      mail = {
	:mail_from => '',
	:recipient => '',
	:header => [],
	:body => '',
      }
      so = Sendmail('localhost', 25, nil, mail)
      is "EHLO sender
MAIL FROM: <>
RCPT TO: <>
DATA

.
QUIT",
	so.buffer.join("\n")

      mail = {
	:mail_from => 'alice@example.com',
	:recipient => 'bob@example.com',
	:header => [
	  ['To', 'bob@example.com'],
	  ['From', 'alice@example.com'],
	  ['Subject', 'test'],
	],
	:body => 'This is a test.',
      }
      so = Sendmail('localhost', 25, false, mail)
      is "EHLO sender
MAIL FROM: <alice@example.com>
RCPT TO: <bob@example.com>
DATA
To: bob@example.com
From: alice@example.com
Subject: test

This is a test.
.
QUIT",
	so.buffer.join("\n")
    end
  end
end
