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
require 'qwik/group'
require 'qwik/util-sendmail'
require 'qwik/util-basic'

module QuickML
  class Group
    def report_ml_close_soon
      return if @members.active_empty?

      name = @name

      subject = Mail.encode_field(_("[%s] ML will be closed soon", name))

      header = [
	['To',	@address],
	['From',	@address],
	['Subject',	subject],
	['Reply-To',	@address],
	['Content-Type', content_type]
      ]
      header.concat(quickml_fields)

      time_to_close = @db.last_article_time + @group_config[:ml_life_time]
      ndays = ((time_to_close - Time.now) / 86400.0).ceil
      datefmt = __('%Y-%m-%d %H:%M')

      body =  _("ML will be closed if no article is posted for %d days.\n\n",
		ndays)
      body << _("Time to close: %s.\n\n", time_to_close.strftime(datefmt))
      body << generate_footer(true)

      mail = {
	:mail_from => '', 
	:recipient => get_active_members,
	:header => header,
	:body => body,
      }
      Sendmail(@config.smtp_host, @config.smtp_port, @logger, mail)
      @logger.log "[#{@name}]: Alert: ML will be closed soon"
      close_alertedp_file
    end

    def submit (mail)
      #p 'ml.submit ' if $ml_debug

      return if @members.active_empty?

      if @group_config[:max_mail_length] < mail.body.length
        report_too_large_mail(mail)
        @logger.log "[#{@name}]: Too Large Mail: #{mail.from}"
        return
      end

      reset_error_member(mail.from)
      start_time = Time.now
      _submit(mail)
      elapsed = Time.now - start_time
      msg = "[#{@name}:#{@count}]: Send:"
      msg += " #{@config.smtp_host} #{elapsed} sec." if ! $test
      @logger.log msg
    end

    private

    def _submit(mail)
      site_post(mail)
      _org_submit(mail)
    end

    def _org_submit (mail)
      inc_count
      save_charset(@message_charset)
      remove_alertedp_file

      subject = Mail.rewrite_subject(mail['Subject'], @name, @count)

      body = rewrite_body(mail)

      header = []
      mail.each_field {|key, value|
	k = key.downcase
	next if k == 'subject' or k == 'reply-to'
	header.push([key, value])
      }
      header.push(['Subject',	subject],
		  ['Reply-To',	@address],
		  ['X-Mail-Count',@count])
      header.concat(quickml_fields)

      mail = {
	:mail_from => @return_address, 
	:recipient => get_active_members,
	:header => header,
	:body => body
      }
      Sendmail(@config.smtp_host, @config.smtp_port, @logger, mail)
    end

    def send_confirmation (creator_address)
      header = []
      subject = Mail.encode_field(_("[%s] Confirmation: %s", @name, @address))
      header.push(['To',	creator_address],
		  ['From',	confirmation_address],
		  ['Subject',	subject],
                  ['Content-Type', content_type])
      body = confirmation_message(@address)
      mail = {
	:mail_from => '', 
	:recipient => creator_address,
	:header => header,
	:body => body,
      }
      Sendmail(@config.smtp_host, @config.smtp_port, @logger, mail)
      @logger.log "[#{@name}]: Send confirmation: #{confirmation_address} #{creator_address}"
    end

    # FIXME: too similar to report_too_large_mail in ml-session.rb
    def report_too_large_mail (mail)
      header = []
      subject = Mail.encode_field(_("[QuickML] Error: %s", mail['Subject']))
      header.push(['To',	mail.from],
		  ['From',	@address],
		  ['Subject',	subject],
		  ['Content-Type', content_type])
      max  = @group_config[:max_mail_length].commify
      body =   _("Sorry, your mail exceeds the length limitation.\n")
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

    def report_removed_member (error_address)
      return if @members.active_empty?
      subject = Mail.encode_field(_("[%s] Removed: <%s>", 
				    @name, error_address))
      header = [
	['To',	@address],
	['From',	@address],
	['Subject',	subject],
	['Reply-To',	@address],
	['Content-Type', content_type]
      ]
      header.concat(quickml_fields)
      body =  _("<%s> was removed from the mailing list:\n<%s>\n", 
		error_address, @address)
      body << _("because the address was unreachable.\n")
      body << generate_footer(true)

      mail = {
	:mail_from => '', 
	:recipient => get_active_members,
	:header => header,
	:body => body,
      }
      Sendmail(@config.smtp_host, @config.smtp_port, @logger, mail)
      @logger.log "[#{@name}]: Notify: Remove #{error_address}"
    end

    def content_type
      return Mail.content_type(@config.content_type, @message_charset)
    end

    def quickml_fields
      return [
	['Precedence',   'bulk'],
        ['X-ML-Address', @address],
	['X-ML-Name',	 @name],
	['X-ML-Info',	 @config.public_url],
	['X-QuickML',	 'true']
      ]
    end

    def confirmation_message(address)
      body = ''
      body += _("First, please read the agreement of this service.\n")

     #body += _("http://example.com/qwikjpAgreementE.html\n")
      body += _("http://qwik.jp/qwikjpAgreementE.html\n")
     #body += "http://#{@cnfig.domain}/"+_('AgreementE.html')+"\n"

      body += _("You must agree with this agreement to use the service.\n")
      body += _("If you agree, then,\n")
      body += _("Please simply reply to this mail to create ML <%s>.\n", address)
      body
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-module-ml'
  $test = true
end

if defined?($test) && $test
  class TestGroupSendMail < Test::Unit::TestCase
    include TestModuleML

    def setup_qml
      return QuickML::Group.new(@ml_config, 'test@example.com')
    end

    def test_class_method
      c = QuickML::Group
    end

    def test_all
    end
  end
end
