#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '../../lib' unless $LOAD_PATH.include?('../../lib')
require 'qwik/act-ring-common'
require 'qwik/act-ring-user'

module Qwik
  class Action
    # ============================== invite
    # Show invite form
    # http://colinux:9190/ring.sfc.keio.ac.jp/_TestActRingInvite.html
    def plg_ring_invite_form(dest=nil)
      action = @req.base+'.ring_invite'
      your_mail = plg_ring_show('mail')
      your_username = plg_ring_show('user')
      your_name = plg_ring_show('name')
      guest_mail = 'guest@example.com'
      w = [:div, {:class=>'form'},
	[:form, {:method=>'POST', :action=>action},
	  [:table,
	    [:tr,
	      [:th, _r(:BULLET)+_r(:YOUR_MAIL)],
	      [:td, your_mail]],
	    [:tr,
	      [:th, _r(:BULLET)+_r(:YOUR_USER)],
	      [:td, your_username]],
	    [:tr,
	      [:th, _r(:BULLET)+_r(:YOUR_NAME)],
	      [:td, your_name]],
	    [:tr,
	      [:th, _r(:BULLET)+_r(:MAIL)],
	      [:td, [:textarea, {:cols=>'40', :rows=>'4', :name=>'guest_mail'},
		  guest_mail]]],
	    [:tr,
	      [:td, {:class=>'msg', :colspan=>2},
		_r(:INVITE_INPUT_GUEST_MAIL)]],
	    [:tr,
	      [:th, _r(:BULLET)+_r(:MESSAGE)],
	      [:td, [:textarea, {:cols=>'40', :rows=>'7', :name=>'message'},
		  _r(:INVITE_MESSAGE_DUMMY_TEXT)]]],
	    [:tr,
	      [:td, {:class=>'msg', :colspan=>2}, _r(:INVITE_DESC)]],
	    [:tr,
	      [:th, ''],
	      [:td, [:input, {:type=>'submit', :class=>'submit',
		    :value=>_r(:INVITE_DO_INVITE)}]]]]]]
      return w
    end

    def plg_ring_invite_go(arg=nil)	# obsolete
      return
    end

    def ext_ring_invite
      page = @site[@req.base]
      href = page.url

      guest_mails = @req.query['guest_mail']
      message = @req.query['message']
      #qp guest_mails, message
      if guest_mails.nil? || guest_mails.empty? || message.nil?
	return ring_invite_goback(href)
      end

      #qp guest_mails, message
      if guest_mails.to_s == 'guest@example.com' 
	return ring_invite_goback(href)
      end

      guest_mail_ar = Action.ring_invite_parse_guest_mails(guest_mails)
      if guest_mail_ar.length == 0
	return ring_invite_goback(href)
      end

      ring_invite_guest(guest_mail_ar, message)

      return c_notice(_r(:INVITE_MAIL_IS_SENT)) {
	[[:h3, _r(:INVITE_MAIL_IS_SENT)],
	  [:dl,
	    [:dt, _r(:MESSAGE)],
	    [:dd, message]],
	  [:p, _r(:THANKYOU)],
	  [:p, [:a, {:href=>href}, _('Go back')]]]
      }
    end

    def ring_invite_goback(href)
      return c_nerror(_r(:INVITE_NOSEND)) {
	[[:h3, _r(:INVITE_NOSEND)],
	  [:p, _r(:CONFIRM_YOUR_INPUT)],
	  [:p, [:a, {:href=>href}, _('Go back')]]]
      }
    end

    def self.ring_invite_parse_guest_mails(guest_mails)
      guest_mail_ar = []
      guest_mails.each {|line|
	line.chomp!
	line.sub!(/\A\s+/, "")
	line.sub!(/\s+\z/, "")
	line.sub!(/,\z/, "")
	guest_mail = line
	next unless MailAddress.valid?(guest_mail)
	guest_mail_ar << guest_mail
      }
      return guest_mail_ar
    end

    # In this method, we actually add the guest user.
    def ring_invite_guest(guest_mail_ar, message)
      host_mail = @req.user
      page = c_get_superpage(RING_INVITE_MEMBER)
      page = @site.create('_'+RING_INVITE_MEMBER) if page.nil?
      now = @req.start_time

      member = @site.member
      guest_mail_ar.each {|guest_mail|
	next if member.exist_qwik_members?(guest_mail)
	member.add(guest_mail, host_mail)
	page.wikidb.add(guest_mail, '', host_mail, message, now.to_i)
	ring_invite_sendmail(host_mail, guest_mail, '', message)
      }
    end

    def ring_dummy_template
      str = '#{guest_mail}
#{message}
#{host_name}
#{host_mail}
http://ring.sfc.keio.ac.jp/.getpass?mail=#{guest_mail}
'
      return str
    end

    def ring_invite_sendmail(host_mail, guest_mail, guest_name, message)
      host_name = plg_ring_user(host_mail, 'name')
      host_name ||= ''
      host_from = host_name+" <"+host_mail+">"
      guest_to = guest_mail
      subject = _r(:INVITE_SUBJECT)
      template_page = c_get_superpage(RING_INVITE_MAIL_TEMPLATE)

      if template_page
	content = template_page.load
      else
	content = ring_dummy_template
      end

      #qp content
      content.gsub!(/\#\{host_name\}/, host_name)
      content.gsub!(/\#\{host_mail\}/, host_mail)
      content.gsub!(/\#\{guest_mail\}/, guest_mail)
      content.gsub!(/\#\{message\}/, message)

      mail = Mail.new(host_from, guest_to, subject, content)
      sm = Sendmail.new(@config.smtp_host, @config.smtp_port, @config.test)
      sm.send(mail)
    end

    def plg_ring_invite_list(arg=nil)
      page = c_get_superpage(RING_INVITE_MEMBER)
      ar = page.wikidb.hash.to_a

      dl = [:dl]
      ar.reverse.each {|k, v|
	guest_mail = k
	guest_name, host_mail, message, time = v
	ymd = ''
	if time.is_a? String
	  time = Time.at(time.to_i)
	  ymd = time.ymd
	end

	userlink = plg_ring_ul(host_mail)
	dt = [:dt, userlink, _r(:RIGHT_ARROW)+guest_name+" ("+guest_mail+") "+ymd]
	dd = [:dd, message]
	dl << dt
	dl << dd
      }

      return [:div, {:class=>'ring_invite_list'}, dl]
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActRingInvite < Test::Unit::TestCase
    include TestSession

    def test_plg_ring_invite_form
      t_add_user

      page = @site.create_new
      page.store("{{ring_invite_form}}")
      res = session('/test/1.html')
      assert_rattr({:action=>'1.ring_invite', :method=>'POST'},
		   "//div[@class='section']/form")
      ok_xp([:textarea, {:cols=>'40', :name=>'guest_mail', :rows=>'4'},
		     'guest@example.com'],
		   "//div[@class='section']/textarea")
    end

    def test_ext_ring_invite
      t_add_user

      template_page = @site.create('_'+Qwik::Action::RING_INVITE_MAIL_TEMPLATE)
      template_page.store("
\#{guest_mail}
\#{message}
\#{host_name}
\#{host_mail}
")

      page = @site.create_new
      page.store('')

      res = session('/test/1.ring_invite')
      ok_xp([:div, {:class=>'section'},
	      [[:h3, "招待状は送られませんでした"],
		[:p, "もう一度入力を確認してください。"],
		[:p, [:a, {:href=>'1.html'}, 'Go back']]]],
	    "//div[@class='section']")

      res = session("/test/1.ring_invite?guest_mail=g@e.com&message=hi")
      ok_xp([:div, {:class=>'section'},
	      [[:h3, "招待状が送られました"],
		[:dl, [:dt, "メッセージ"], [:dd, 'hi']],
		[:p, "どうもありがとうございました。"],
		[:p, [:a, {:href=>'1.html'}, 'Go back']]]],
	    "//div[@class='section']")

      ok_eq('', page.load)

      invite_member_page = @site['_'+Qwik::Action::RING_INVITE_MEMBER]
      ok_eq(",g@e.com,,user@e.com,hi,0\n", invite_member_page.load)

      member_page = @site['_SiteMember']
      ok_eq(",user@e.com,
,g@e.com,user@e.com
", member_page.load)
    end

    def test_plg_ring_invite_list
      t_add_user

      invite_member_page = @site.create('_'+Qwik::Action::RING_INVITE_MEMBER)
      invite_member_page.store(",g@e.com,,user@e.com,hi,0\n")

      page = @site.create_new
      page.store("{{ring_invite_list}}")
      res = session('/test/1.html')
      ok_xp([:dl,
 [:dt, [:span, {:class=>'ring_ul'}, 'user@e.com'], "→ (g@e.com) 1970-01-01"],
 [:dd, 'hi']],
		   "//div[@class='ring_invite_list']/dl")
    end

  # http://colinux:9190/ring.sfc.keio.ac.jp/
  def test_ring_invite
    t_add_user

    page = @site.create('_RingMember')
    page.store(',user@e.com,Test User,Alan Smithy,ei,1990,1,0')

    page = @site.create_new
    page.store("{{ring_invite_form}}")

    # See invite page.
    res = session('/test/1.html')
    assert_rattr({:action=>'1.ring_invite', :method=>'POST'}, '//form')
    ok_in(['user@e.com'], '//table/tr/td')
    ok_in(['guest@example.com'], "//form/table/tr[4]/td/textarea")

    # Try to invite, but it cause error.
    res = session("/test/1.ring_invite?guest_mail=invalid@mailaddress")
    ok_in(["招待状は送られませんでした"], '//h3')

    # Try to invite again.
    res = session("/test/1.ring_invite?guest_mail=gu@e.com&message=invite")
    ok_in(["招待状が送られました"], '//h3')
    ok_eq(",gu@e.com,,user@e.com,invite,0\n", @site['_RingInvitedMember'].load)
    ok_eq("Alan Smithy <user@e.com>", $smtp_sendmail[2])
    ok_eq('gu@e.com', $smtp_sendmail[3])
    assert_match(/^From/, $smtp_sendmail[4])
    url = "http://ring.sfc.keio.ac.jp/.getpass?mail=gu@e.com"
    assert_match(Regexp.new(Regexp.escape(url)), $smtp_sendmail[4])

    # Try to invite another person.
    res = session("/test/1.ring_invite?guest_mail=fe@e.com&message=youtoo")
    ok_in(["招待状が送られました"], '//h3')
    ok_eq(",gu@e.com,,user@e.com,invite,0\n,fe@e.com,,user@e.com,youtoo,0\n",
	  @site['_RingInvitedMember'].load)
    ok_eq("Alan Smithy <user@e.com>", $smtp_sendmail[2])
    ok_eq('fe@e.com', $smtp_sendmail[3])
    assert_match(/^From/, $smtp_sendmail[4])
    url = "http://ring.sfc.keio.ac.jp/.getpass?mail=fe@e.com"
    assert_match(Regexp.new(Regexp.escape(url)), $smtp_sendmail[4])

    # See invited member list.
    page = @site.create_new
    page.store("{{ring_invite_list}}")

    res = session('/test/2.html')
    ok_in([:dl,
 [:dt, [:span, {:class=>'ring_ul'}, [:a, {:href=>'1.html'}, 'Test User']],
  "→ (gu@e.com) 1970-01-01"],
 [:dd, 'invite'],
 [:dt, [:span, {:class=>'ring_ul'}, [:a, {:href=>'1.html'}, 'Test User']],
  "→ (fe@e.com) 1970-01-01"],
 [:dd, 'youtoo']],
 "//div[@class='ring_invite_list']")

    page = @site['_RingMember']
    ok_eq(',user@e.com,Test User,Alan Smithy,ei,1990,1,0', page.load)
    page = @site['_SiteMember']
    ok_eq(",user@e.com,\n,gu@e.com,user@e.com\n,fe@e.com,user@e.com\n",
	  page.load)
  end

  end
end
