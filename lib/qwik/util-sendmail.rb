require 'net/smtp'

$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'
require 'qwik/mail'
require 'qwik/util-kconv'

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

    private

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

      Net::SMTP.start(host, port) {|smtp|
	smtp.send_mail(message, from, to)
      }
      return nil
    end
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
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
      eq("From: from@example.com
To: to@example.com
Subject: subject
Content-Type: text/plain; charset=\"ISO-2022-JP\"

content
", sm.send(mail))

      mail = {
	:from    => 'from@example.com',
	:to      => 'to@example.com',
	:subject => '‘è–¼',
	:content => '–{•¶',
      }
      eq("From: from@example.com
To: to@example.com
Subject: =?ISO-2022-JP?B?GyRCQmpMPhsoQg==?=
Content-Type: text/plain; charset=\"ISO-2022-JP\"

\e$BK\\J8\e(B
", sm.send(mail))

    end
  end
end
