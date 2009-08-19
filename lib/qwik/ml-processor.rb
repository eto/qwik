# -*- coding: shift_jis -*-
#
# Copyright (C) 2002-2004 Satoru Takabayashi <satoru@namazu.org> 
# Copyright (C) 2003-2006 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/ml-gettext'
require 'qwik/ml-exception'
require 'qwik/group'
require 'qwik/mail'
require 'qwik/util-charset'

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

      # FIXME: too ad-hoc
      @rejection_ignore_list = %w(info ajax study test)
      if $test
	@rejection_ignore_list = []
	if $test_rejection_ignore_list
	  @rejection_ignore_list = $test_rejection_ignore_list
	end
      end
    end

    def process
      mail_log
      if @mail.looping?
	@logger.log "Looping Mail: from #{@mail.from}"
	return
      end

      @mail.recipients.each {|recipient|
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
	ServerMemory.ml_mutex(@config, mladdress).synchronize {
	  ml = Group.new(@config, mladdress, @mail.from, @message_charset)
	  @message_charset ||= ml.charset

	  #qp @mail.body
          if Processor.unsubscribe_requested?(@mail.body)
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

    UNSUBSCRIBE_THRESHOLD = 500
    UNSUBSCRIBE_RE = /\A\s*(unsubscribe|bye|#\s*bye|quit|退会|脱退)\s*$/s
    def self.unsubscribe_requested?(body)
      return true if body.empty?
      return true if Mail.empty_body?(body)
      return false if UNSUBSCRIBE_THRESHOLD <= body.length
      return true if UNSUBSCRIBE_RE.match(body.tosjis)
      return false
    end

    def submit (ml)
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
      mail = {
	:mail_from => '', 
	:recipient => @mail.from,
	:header => [
	  ['To',	@mail.from],
	  ['From',	@config.ml_postmaster],
	  ['Subject',
	    Mail.encode_field(_("[QuickML] Error: %s", @mail['Subject']))],
	  ['Content-Type', content_type]
	],
	:body => _("Invalid mailing list name: <%s>\n", mladdress) +
	_("You can only use 0-9, a-z, A-Z,  `-' for mailing list name\n") +
	generate_footer,
      }
      Sendmail.send_mail(@config.smtp_host, @config.smtp_port, @logger, mail)
      @logger.log "Invalid ML Address: #{mladdress}"
    end

    def content_type
      return Mail.content_type(@config.content_type, @message_charset)
    end

    def generate_footer
      return "\n-- \n" + _("Info: %s\n", @config.public_url)
    end

    def report_rejection (ml)
      # FIXME: too ad-hoc
      if @rejection_ignore_list.include?(ml.name)
	@logger.log "[#{ml.name}]: Reject quietly: #{@mail.from}"

	# do nothing
	return 
      end

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

=begin
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
        unless @mail['Content-Type'].empty?
          header.push(['Content-Type', @mail['Content-Type']]) 
        end
        body << @mail.body
      end
=end

      body <<  _("The original body is omitted to avoid spam trouble.\n")

      mail = {
	:mail_from => '', 
	:recipient => @mail.from,
	:header => header,
	:body => body,
      }
      Sendmail.send_mail(@config.smtp_host, @config.smtp_port, @logger, mail)
      @logger.log "[#{ml.name}]: Reject: #{@mail.from}"
    end

    def report_unsubscription (ml, member, requested_by = nil)
      header = []
      subject = Mail.encode_field(_("[%s] Unsubscribe: %s",
				    ml.name, ml.address))
      header.push(['To',	member],
		  ['From',	ml.address],
		  ['Subject',	subject],
                  ['Content-Type', content_type])

      if requested_by
	body =  _("You are removed from the mailing list:\n<%s>\n",
		  ml.address)
	body << _("by the request of <%s>.\n", requested_by)
      else
	body = _("You have unsubscribed from the mailing list:\n<%s>.\n", 
		 ml.address)
      end
      body << generate_footer

      mail = {
	:mail_from => '', 
	:recipient => member,
	:header => header,
	:body => body,
      }
      Sendmail.send_mail(@config.smtp_host, @config.smtp_port, @logger, mail)
      @logger.log "[#{ml.name}]: Unsubscribe: #{member}"
    end

    def report_too_many_members (ml, unadded_addresses)
      header = [
	['To',	@mail.from],
	['From',	ml.address],
	['Subject',
	  Mail.encode_field(_("[QuickML] Error: %s", @mail['Subject']))],
	['Content-Type', content_type]
      ]
      body =  _("The following addresses cannot be added because <%s> mailing list reaches the maximum number of members (%d persons)\n\n",
		ml.address,
                ml.get_max_members)
      unadded_addresses.each {|address|
        body << sprintf("<%s>\n", address)
      }

      body << generate_footer

      mail = {
	:mail_from => '', 
	:recipient => @mail.from,
	:header => header,
	:body => body,
      }
      Sendmail(@config.smtp_host, @config.smtp_port, @logger, mail)

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

    def test_class_method
      c = QuickML::Processor
      eq true, c.unsubscribe_requested?('')
      eq false, c.unsubscribe_requested?('unsubscribe'+' '*489)
      eq false, c.unsubscribe_requested?(' '*499)
      eq false, c.unsubscribe_requested?(' '*500)
      eq true, c.unsubscribe_requested?(' ')
      eq true, c.unsubscribe_requested?("\n")
      eq true, c.unsubscribe_requested?('unsubscribe')
      eq true, c.unsubscribe_requested?(' unsubscribe')
      eq true, c.unsubscribe_requested?('bye')
      eq true, c.unsubscribe_requested?('#bye')
      eq true, c.unsubscribe_requested?('# bye')
      eq true, c.unsubscribe_requested?('退会')
      eq true, c.unsubscribe_requested?('unsubscribe'+' '*488)
      eq false, c.unsubscribe_requested?('unsubscribe desu.')
      eq false, c.unsubscribe_requested?('I want to unsubscribe.')
    end

    def test_instance_method
      mail = QuickML::Mail.generate {
'From: "Test User" <user@e.com>
To: "Test Mailing List" <test@example.com>
Subject: Test Mail
Date: Mon, 3 Feb 2001 12:34:56 +0900

This is a test.
'
      }
      pro = QuickML::Processor.new(@ml_config, mail)

      # test_to_return_address
      t_make_public(QuickML::Processor, :to_return_address?)
      eq nil, pro.to_return_address?('t@example.com')
      assert pro.to_return_address?('t=return@example.com')

      # test_to_confirmation_address
      t_make_public(QuickML::Processor, :to_confirmation_address?)
      eq nil, pro.to_confirmation_address?('t@example.com')
      assert pro.to_confirmation_address?('confirm+t@example.com')
    end

    def ok_file(e, file)
      dir = @config.sites_dir.path
      str = (dir + "test/#{file}").path.read
      ok_eq(e, str)
    end

    def ok_config(e)
      dir = @config.sites_dir.path
      str = (dir + 'test/_GroupConfig.txt').path.read
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
'
      }
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

    def test_with_confirm
      message = 'From: "Test User" <user@e.com>
To: "Test Mailing List" <test@example.com>
Subject: Test Mail
Date: Mon, 3 Feb 2001 12:34:56 +0900

This is a test.
'
      mail = QuickML::Mail.generate { message }
      org_confirm_ml_creation = @ml_config[:confirm_ml_creation]
      @ml_config[:confirm_ml_creation] = true

      ".test/data/test".path.rmtree

      processor = QuickML::Processor.new(@ml_config, mail)
      processor.process

      eq "ply to this mail to create ML <test@example.com>.\n",
	$quickml_sendmail[4][-50..9999]

      ok_file('', '_GroupMembers.txt')
      ok_file("user@e.com\n", '_GroupWaitingMembers.txt')
      ok_file(message, '_GroupWaitingMessage.txt')
      h = {
	:auto_unsubscribe_count=>5,
	:max_mail_length=>102400,
	:max_members=>100,
	:ml_alert_time=>2073600,
	:ml_life_time=>2678400,
	:forward=>false,
	:permanent=>false,
	:unlimited=>false,
      }
      ok_config(h)
      @ml_config[:confirm_ml_creation] = org_confirm_ml_creation
    end

    def test_invalid_mlname
      message = 'From: user@e.com
To: invalid_mlname@example.com
Subject: Test Mail
Date: Mon, 3 Feb 2001 12:34:56 +0900

This is a test.
'
      mail = QuickML::Mail.generate { message }
      processor = QuickML::Processor.new(@ml_config, mail)
      processor.process
      eq "To: user@e.com\nFrom: postmaster@q.example.com\nSubject: [QuickML] Error: Test Mail\nContent-Type: text/plain\n\nInvalid mailing list name: <invalid_mlname@example.com>\nYou can only use 0-9, a-z, A-Z,  `-' for mailing list name\n\n-- \nInfo: http://example.com/\n", $quickml_sendmail[4]
    end

    def test_ignore_list
      $test_rejection_ignore_list = ["test"]

      # 
      # normal case
      # 
      send_normal_mail('bob@example.net')		# Bob creates a new ML.

      sendmail('bob@example.net', 'test@q.example.com', 'test mail') {
	"This is a test."
      }
      eq true, @site.exist?('1')
      eq 'test mail', @site['1'].get_title
      eq "* test mail\n{{mail(bob@example.net,0)\nThis is a test.\n}}\n",
      @site['1'].load

      # 
      # sent from alien
      # 

      # clear probe
      $quickml_sendmail = nil

      # rejection message should be null
      expected = nil

      input = []
      input << 'alice@example.net' # from
      input << 'test@q.example.com' # to
      input << 'spam mail'	# subject
      inputBody =  'This is spam.'

      sendmail(*input) {
	inputBody
      }
      actual = $quickml_sendmail

      ok_eq(expected, actual)

      # clean up for test suite
      $test_rejection_ignore_list = nil
    end

  end
end
