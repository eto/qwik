#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

require 'net/smtp'

$LOAD_PATH << '../../lib' unless $LOAD_PATH.include?('../../lib')
require 'qwik/mail'
require 'qwik/util-kconv'

module Qwik
  class Sendmail
    def initialize(host, port, test=false)
      @host, @port = host, port
      @test = test
    end

    def send(mail)
      Sendmail.send(@host, @port,
		    mail.from, mail.to, mail.subject, mail.content, @test)
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

      mail = Qwik::Mail.new
      mail.from = 'from@example.com'
      mail.to = 'to@example.com'
      mail.subject = 'subject'
      mail.content = 'content'
      ok_eq("From: from@example.com\nTo: to@example.com\nSubject: subject\nContent-Type: text/plain; charset=\"ISO-2022-JP\"\n\ncontent\n", sm.send(mail))

      mail = Qwik::Mail.new
      mail.from = 'from@example.com'
      mail.to = 'to@example.com'
      mail.subject = '‘è–¼'
      mail.content = '–{•¶'
      ok_eq("From: from@example.com\nTo: to@example.com\nSubject: =?ISO-2022-JP?B?GyRCQmpMPhsoQg==?=\nContent-Type: text/plain; charset=\"ISO-2022-JP\"\n\n\e$BK\\J8\e(B\n", sm.send(mail))

    end
  end
end
