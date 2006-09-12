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
require 'qwik/smtp-session'
require 'qwik/ml-processor'

module QuickML
  class Session < SmtpSession
    def process_mail(config, mail)
      processor = Processor.new(config, mail)
      processor.process
    end

    def report_too_large_mail (mail)
      header = []
      subject = Mail.encode_field(_("[QuickML] Error: %s", mail['Subject']))
      header.push(['To',	mail.from],
		  ['From',	@config.ml_postmaster],
		  ['Subject',	subject],
                  ['Content-Type', content_type])

      max  = @config.max_mail_length.commify
      body =   _("Sorry, your mail exceeds the limitation of the length.\n")
      body <<  _("The max length is %s bytes.\n\n", max)
      orig_subject = codeconv(Mail.decode_subject(mail['Subject']))
      body << "Subject: #{orig_subject}\n"
      body << "To: #{mail['To']}\n"
      body << "From: #{mail['From']}\n"
      body << "Date: #{mail['Date']}\n"

      mail = {
	:mail_from => '', 
	:recipient => mail.from,
	:header => header,
	:body => body,
      }
      Sendmail(@config.smtp_host, @config.smtp_port, @logger, mail)
    end

    # FIXME: this is the same method of QuickML#content_type
    def content_type
      return Mail.content_type(@config.content_type, @message_charset)
    end
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  require 'qwik/mock-socket'
  require 'qwik/mock-logger'
  require 'qwik/config'
  require 'qwik/server'
  require 'qwik/ml-memory'
  $test = true
end

if defined?($test) && $test
  class TestMLSession < Test::Unit::TestCase
    def test_all
      config = Qwik::Config.new
      logger = QuickML::MockLogger.new
      hash = {
	:logger		=> logger,
	:sites_dir	=> '.',
      }
      config.update(hash)

      QuickML::ServerMemory.init_mutex(config)
      QuickML::ServerMemory.init_catalog(config)
      old_test_memory = $test_memory
      $test_memory = Qwik::ServerMemory.new(config)	# FIXME: Ugly.
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
      session = QuickML::Session.new(config, logger, config.catalog, socket)
      session.start
      $test_memory = old_test_memory
    end
  end
end
