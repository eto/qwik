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
require 'qwik/ml-exception'
require 'qwik/group'
require 'qwik/mail'
require 'qwik/util-kconv'

module QuickML
  class Processor
    include GetText

    def initialize (config, mail)
      @config = config
      @mail = mail
      @logger = @config.logger
      @catalog = @config.catalog
      if mail.multipart?
	sub_mail = Mail.new
	sub_mail.read(mail.parts.first)
	@message_charset = sub_mail.charset
      else
	@message_charset = mail.charset
      end
    end

    def process
      mail_log
      if @mail.looping?
	@logger.log "Looping Mail: from #{@mail.from}"
	return
      end

      #qp 'start process_recipient' if $ml_debug

      @mail.recipients.each {|recipient|
        #qp 'process_recipient '+recipient if $ml_debug
	process_recipient(recipient)
      }
    end

    private

    def mail_log
      @logger.vlog "MAIL FROM:<#{@mail.mail_from}>"
      @mail.recipients.each {|recipient|
	@logger.vlog "RCPT TO:<#{recipient}>"
      }
      @logger.vlog 'From: ' + @mail.from
      @logger.vlog 'Cc: ' + @mail.collect_cc.join(', ')
      @logger.vlog 'bare From: ' + @mail['From']
      @logger.vlog 'bare Cc: ' + @mail['Cc']
    end

    def process_recipient (recipient)
      mladdress = recipient

      # Error mail handling.
      if to_return_address?(mladdress)
	handler = ErrorMailHandler.new(@config, @message_charset)
	handler.handle(@mail)
	return
      end

      # Confirm to create a new mailing list.
      if @config.confirm_ml_creation && to_confirmation_address?(mladdress)
        validate_confirmation(mladdress)
	return
      end

      begin
        #qp "before mutex #{mladdress}" if $ml_debug

	ServerMemory.ml_mutex(@config, mladdress).synchronize {
          #qp "start in mutex #{mladdress}" if $ml_debug
	  ml = Group.new(@config, mladdress, @mail.from, @message_charset)
	  @message_charset ||= ml.charset

          if unsubscribe_requested?
            unsubscribe(ml)
            return
          end

	  submit(ml)
	}

      rescue InvalidMLName
	report_invalid_mladdress(mladdress)
      end
    end

    def to_return_address? (recipient)
      # "return=" for XVERP, 'return@' for without XVERP.
      return /^[^=]*=return[=@]/ =~ recipient
    end

    def to_confirmation_address? (address)
      return /\Aconfirm\+/.match(address)
    end

    def validate_confirmation (confirmation_address)
      m = /\Aconfirm\+(\d+)\+(.*)/.match(confirmation_address)
      return if m.nil?
      time = m[1]
      mladdress = m[2]
      ml = Group.new(@config, mladdress)
      if ml.validate_confirmation(time)
        ml.accept_confirmation
      end
    end

    def unsubscribe_requested?
      return @mail.empty_body? || 
        (@mail.body.length < 500 &&
         (/\A\s*(unsubscribe|bye|#\s*bye|quit|‘Þ‰ï|’E‘Þ)\s*$/s).match(@mail.body.tosjis))
    end

    def submit (ml)
      #qp 'submit ', ml.name if $ml_debug

      if Group.exclude?(@mail.from, @config.ml_domain)
	@logger.log "Invalid From Address: #{@mail.from}"
	return
      end

      if ml.forward? 
	@logger.log "Forward Address: #{ml.address}"
	ml.submit(@mail)
	return
      end

      if confirmation_required?(ml)
        ml.prepare_confirmation(@mail)
	return
      end

      if acceptable_submission?(ml)
	submit_article(ml)
	return
      end

      report_rejection(ml)
    end

    def report_invalid_mladdress (mladdress)
      header = []
      subject = Mail.encode_field(_("[QuickML] Error: %s", @mail['Subject']))
      header.push(['To',	@mail.from],
		  ['From',	@config.ml_postmaster],
		  ['Subject',	subject],
                  ['Content-type', content_type])

      body =   _("Invalid mailing list name: <%s>\n", mladdress)
      body <<  _("You can only use 0-9, a-z, A-Z,  `-' for mailing list name\n")

      body << generate_footer
      Sendmail.send_mail(@config.smtp_host, @config.smtp_port, @logger,
		     :mail_from => '', 
		     :recipient => @mail.from,
		     :header => header,
		     :body => body)
      @logger.log "Invalid ML Address: #{mladdress}"
    end

    def content_type
      return Mail.content_type(@config.content_type, @message_charset)
    end

    def generate_footer
      return "\n-- \n" + _("Info: %s\n", @config.public_url)
    end

    def report_rejection (ml)
      header = []
      subject = Mail.encode_field(_("[QuickML] Error: %s", @mail['Subject']))
      header.push(['To',	@mail.from],
		  ['From',	ml.address],
		  ['Subject',	subject])

      body =  _("You are not a member of the mailing list:\n<%s>\n",
		ml.address)
      body << "\n"
      body <<  _("Did you send a mail with a different address from the address registered in the mailing list?\n")
      body <<  _("Please check your 'From:' address.\n")
      body << generate_footer
      body << "\n"

      body << _("----- Original Message -----\n")
      orig_subject = codeconv(Mail.decode_subject(@mail['Subject']))
      body << "Subject: #{orig_subject}\n"
      body << "To: #{@mail['To']}\n"
      body << "From: #{@mail['From']}\n"
      body << "Date: #{@mail['Date']}\n"
      body << "\n"

      if @mail.multipart?
        ['Content-Type', 'Mime-Version', 
          'Content-Transfer-Encoding'].each {|key|
          header.push([key, @mail[key]]) unless @mail[key].empty?
        }
        sub_mail = Mail.new
        parts = @mail.parts
        sub_mail.read(parts.first)
        body << sub_mail.body
        sub_mail.body = body
        parts[0] = sub_mail.to_s
        body = Mail.join_parts(parts, @mail.boundary)
      else
        unless @mail['Content-type'].empty?
          header.push(['Content-Type', @mail['Content-type']]) 
        end
        body << @mail.body
      end

      Sendmail.send_mail(@config.smtp_host, @config.smtp_port, @logger,
		     :mail_from => '', 
		     :recipient => @mail.from,
		     :header => header,
		     :body => body)
      @logger.log "[#{ml.name}]: Reject: #{@mail.from}"
    end

    def report_unsubscription (ml, member, requested_by = nil)
      header = []
      subject = Mail.encode_field(_("[%s] Unsubscribe: %s",
				    ml.name, ml.address))
      header.push(['To',	member],
		  ['From',	ml.address],
		  ['Subject',	subject],
                  ['Content-type', content_type])

      if requested_by
	body =  _("You are removed from the mailing list:\n<%s>\n",
		  ml.address)
	body << _("by the request of <%s>.\n", requested_by)
      else
	body = _("You have unsubscribed from the mailing list:\n<%s>.\n", 
		 ml.address)
      end
      body << generate_footer
      Sendmail.send_mail(@config.smtp_host, @config.smtp_port, @logger,
		     :mail_from => '', 
		     :recipients => member,
		     :header => header,
		     :body => body)
      @logger.log "[#{ml.name}]: Unsubscribe: #{member}"
    end

    def report_too_many_members (ml, unadded_addresses)
      header = []
      subject = Mail.encode_field(_("[QuickML] Error: %s", @mail['Subject']))
      header.push(['To',	@mail.from],
		  ['From',	ml.address],
		  ['Subject',	subject],
                  ['Content-type', content_type])

      body =  _("The following addresses cannot be added because <%s> mailing list reaches the max number of members (%d persons)\n\n",
		ml.address,
                ml.get_max_members)
      unadded_addresses.each {|address|
        body << sprintf("<%s>\n", address)
      }

      body << generate_footer
      Sendmail.send_mail(@config.smtp_host, @config.smtp_port, @logger,
		     :mail_from => '', 
		     :recipient => @mail.from,
		     :header => header,
		     :body => body)

      str = unadded_addresses.join(',')
      @logger.log "[#{ml.name}]: Too Many Members: #{str}"
    end

    def sender_knows_an_active_member? (ml)
      return @mail.collect_cc.find {|address|
	ml.active_members_include?(address)
      }
    end

    def add_member (ml, address)
      begin
	ml.add_member(address)
      rescue TooManyMembers
        @unadded_addresses.push(address)
      end
    end

    def ml_address_in_to? (ml)
      return @mail.collect_to.find {|address|
        address == ml.address
      }
    end

    def submit_article (ml)
      @unadded_addresses = []

      if ml_address_in_to?(ml)
        add_member(ml, @mail.from)
        @mail.collect_cc.each {|address| 
          add_member(ml, address)
        }
      end

      if ! @unadded_addresses.empty?
        report_too_many_members(ml, @unadded_addresses)
      end

      ml.submit(@mail)
    end

    def unsubscribe_self (ml)
      if ml.active_members_include?(@mail.from)
	ml.remove_member(@mail.from)
	report_unsubscription(ml, @mail.from)
      else
	report_rejection(ml)
      end
    end

    def unsubscribe_other (ml, cc)
      if ml.active_members_include?(@mail.from)
	cc.each {|other|
	  if ml.active_members_include?(other)
	    ml.remove_member(other) 
	    report_unsubscription(ml, other, @mail.from)
	  end
	}
      else
	@logger.vlog 'rejected'
      end
    end

    def unsubscribe (ml)
      cc = @mail.collect_cc
      if cc.empty?
	unsubscribe_self(ml)
      else
	unsubscribe_other(ml, cc)
      end
    end

    def acceptable_submission? (ml)
      ml.newly_created? ||
        ml.active_members_include?(@mail.from) ||
        ml.former_members_include?(@mail.from) ||
        sender_knows_an_active_member?(ml)
    end

    def confirmation_required? (ml)
      @config.confirm_ml_creation and ml.newly_created?
    end
  end

  class ErrorMailHandler
    def initialize (config, message_charset)
      @config = config
      @logger = config.logger
      @message_charset = message_charset
    end

    def handle (mail)
      if /\A(.*)=return=(.*?)@(.*?)\z/ =~ mail.recipients.first
	mladdress = $1 + '@' + $3
	error_address = $2.sub(/=/, '@')

	ServerMemory.ml_mutex(@config, mladdress).synchronize {
	  ml = Group.new(@config, mladdress, nil, @message_charset)
 	  handle_error(ml, error_address)
 	}

      else
	@logger.vlog "Error: Use Postfix with XVERP to handle an error mail!"
      end
    end

    private

    def handle_error (ml, error_address)
      @logger.log "ErrorMail: [#{ml.name}] #{error_address}"
      ml.add_error_member(error_address)
    end
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  require 'qwik/test-module-ml'
  require 'qwik/config'
  require 'qwik/mail'
  $test = true
end

if defined?($test) && $test
  class TestMLProcessor < Test::Unit::TestCase
    include TestModuleML

    def ok_file(e, file)
      str = ('./test/'+file).path.read
      ok_eq(e, str)
    end

    def ok_config(e)
      file = '_GroupConfig.txt'
      str = ('./test/'+file).path.read
      hash = QuickML::GroupConfig.parse_hash(str)
      ok_eq(e, hash)
    end

    def test_all
      mail = QuickML::Mail.generate {
'From: "Test User" <user@e.com>
To: "Test Mailing List" <test@example.com>
Subject: Test Mail
Date: Mon, 3 Feb 2001 12:34:56 +0900

This is a test.
' }
      processor = QuickML::Processor.new(@ml_config, mail)
      processor.process

      ok_file("user@e.com\n", '_GroupMembers.txt')
      ok_config({
		  :auto_unsubscribe_count=>5,
		  :max_mail_length=>102400,
		  :max_members=>100,
		  :ml_alert_time=>2073600,
		  :ml_life_time=>2678400,
		  :forward=>false,
		  :permanent=>false,
		  :unlimited=>false,
		})
    end

    def nu_test_with_confirm
      str = 'From: "Test User" <user@e.com>
To: "Test Mailing List" <test@example.com>
Subject: Test Mail
Date: Mon, 3 Feb 2001 12:34:56 +0900

This is a test.
'
      mail = QuickML::Mail.generate { str }

      processor = QuickML::Processor.new(@ml_config, mail)
      processor.process

      ok_file('', '_GroupMembers.txt')
      ok_file("user@e.com\n", '_GroupWaitingMembers.txt')
      ok_file(str, '_GroupWaitingMessage.txt')
      h = {
	:max_members => 100,
	:max_mail_length => 2097152,
	:ml_life_time => 2678400,
	:ml_alert_time => 2073600,
	:auto_unsubscribe_count => 5,
      }
      ok_config(h)
    end

  end
end
