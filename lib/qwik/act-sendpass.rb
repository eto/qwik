# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/act-getpass'
require 'qwik/mailaddress'

module Qwik
  class Action
    def act_sendpass
      c_require_member

      return sendpass_show_form if ! @req.is_post?

      status = {}
      members = @site.member.list
      @req.query.each {|mail, v|
	if ! MailAddress.valid?(mail) || v != 'on'
	  status[mail] = _('Wrong format.')
	  next
	end

	if ! members.include?(mail)
	  status[mail] = _('Not a member.')
	  next
	end

	passmail = generate_password_mail(mail)
	sendmail = Sendmail.new(@config.smtp_host, @config.smtp_port,
				@config.test)
	begin
	  sendmail.send(passmail)
	  status[mail] = _('Succeeded.')
	rescue
	  status[mail] = _('Failed.')
	end
      }

      ar = []
      status.each {|mail, result|
	ar << [:li, mail, ' : ', result.to_s]
      }
      return c_notice(_('Send Password done')) {
	[:ul, ar]
      }
    end

    def sendpass_show_form
      members = @site.member.list.sort
      return c_notice(_('Send Password')) {
	[[:h2, _('You can send password for the members.')],
	  [:p, _('Please select members to send password.')],
	  [:form, {:action=>'.sendpass', :method=>'post',
	      :style=>'text-align: center; margin: 32px 0 48px;'},
	    [:ul, members.map {|member|
		[:li, [:input, {:type=>'checkbox', :name=>member}, ' '+member]]
	      }
	    ],
	    [:input, {:type=>'submit', :value=>_('Send Password')}]]]
      }
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  require 'qwik/test-module-public'
  $test = true
end

if defined?($test) && $test
  class TestActSendPass < Test::Unit::TestCase
    include TestSession

    def test_all
      t_add_user

      res = session '/test/.sendpass'
      ok_title 'Send Password'
    end
  end
end
