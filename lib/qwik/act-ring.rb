# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

# Special mode for Ring.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

$KCODE = 's'

module Qwik
  class Action
    NotUse_D_ExtRing = {
      :dt => 'Ring mode',
      :dd => 'This is a special mode for Ring.',
      :dc => "* How to
* invite
{{ring_invite_form}}
** invite list
{{ring_invite_list}}
* maker
{{ring_make_form}}
* msg
{{ring_message_form}}
** date
{{ring_date(1)}}
* user
{{ring_user(guest@example.com, mail)}}
{{ring_show(mail)}}
{{ring_link(guest@example.com)}}
{{ring_get_user_from_pagename(1)}}
{{ring_see(1)}}
{{ring_personal_info}}
{{ring_ul(guest@example.com)}}

"
    }

    # ============================== common
    RING_MEMBER = 'RingMember'
    RING_INVITE_MEMBER = 'RingInvitedMember'
    RING_INVITE_MAIL_TEMPLATE = 'RingInviteMailTemplate'
    RING_PAGE_TEMPLATE = 'RingPageTemplate'
    RING_CATALOG = 'RingCatalog'

    # ============================== catalog
    def _r(text)
      catalog = ring_catalog
      t = catalog[text]
      return t if t

      # Try to reload.
      @memory[:ring_catalog] = ring_generate_catalog
      catalog = ring_catalog
      t = catalog[text]
      return t if t

      #raise if @config.test	# Only for test.

      return text.to_s		# abandon
    end

    def ring_catalog
      if @memory[:ring_catalog].nil?
	@memory[:ring_catalog] = ring_generate_catalog
      end
      return @memory[:ring_catalog]
    end

    def ring_generate_catalog
      catalog = {}
      page = @site.get_superpage(RING_CATALOG)
      if page.nil?
	page = @site.create("_#{RING_CATALOG}")
	page.store(RING_CATALOG_CONTENT)
      end
      if page
	wdb = page.wikidb
	wdb.hash.each {|k, v|
	  catalog[k.intern] = v
	}
      end
      return catalog
    end

    RING_CATALOG_CONTENT = '
:TEST:テスト
:RIGHT_ARROW:→
:BULLET:●
:USER:ユーザ名
:YOUR_MAIL:あなたのメール
:YOUR_USER:あなたのユーザ名
:YOUR_NAME:あなたの名前
:MAIL:メール
:USER_NAME:ユーザネーム
:MESSAGE:メッセージ
:REALNAME:本名
:THANKYOU:どうもありがとうございました。
:CONFIRM_YOUR_INPUT:もう一度入力を確認してください。
:NAME:名前
:NYUGAKU:入学
:YEAR:年
'

    # ============================== invite
    # Show invite form
    def plg_ring_invite_form(dest=nil)
      action = "#{@req.base}.ring_invite"
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
      if guest_mails.nil? || guest_mails.empty? || message.nil?
	return ring_invite_goback(href)
      end

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
      page = @site.get_superpage(RING_INVITE_MEMBER)
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
      host_from = "#{host_name} <#{host_mail}>"
      guest_to = guest_mail
      subject = _r(:INVITE_SUBJECT)
      template_page = @site.get_superpage(RING_INVITE_MAIL_TEMPLATE)

      if template_page
	content = template_page.load
      else
	content = ring_dummy_template
      end

      content.gsub!(/\#\{host_name\}/, host_name)
      content.gsub!(/\#\{host_mail\}/, host_mail)
      content.gsub!(/\#\{guest_mail\}/, guest_mail)
      content.gsub!(/\#\{message\}/, message)

      mail = {
	:from => host_from,
	:to => guest_to,
	:subject => subject,
	:content => content,
      }
      sm = Sendmail.new(@config.smtp_host, @config.smtp_port, @config.test)
      sm.send(mail)
    end

    def plg_ring_invite_list(arg=nil)
      page = @site.get_superpage(RING_INVITE_MEMBER)
      return if page.nil?
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
	dt = [:dt, userlink,
	  "#{_r(:RIGHT_ARROW)}#{guest_name} (#{guest_mail}) #{ymd}"]
	dd = [:dd, message]
	dl << dt
	dl << dd
      }

      return [:div, {:class=>'ring_invite_list'}, dl]
    end

    # ============================== maker
    # ========== make user page from template
    # http://colinux:9190/ring.sfc.keio.ac.jp/_TestActRingMaker.html
    def plg_ring_make_form(dest=nil)
      action = "#{@req.base}.ring_make"
      mail = @req.user
      return [:div, {:class=>'form'},
	[:form, {:action=>action, :method=>'POST'},
	  [:table,
	    [:tr,
	      [:th, _r(:BULLET)+_r(:MAIL)],
	      [:td, mail]],
	    [:tr,
	      [:th, _r(:BULLET)+_r(:NAME)],
	      [:td, [:input, {:name=>'username'}]]],
	    [:tr,
	      [:td, {:class=>'msg', :colspan=>2}, _r(:MAKER_USER_NAME_DESC)]],
	    [:tr,
	      [:th, _r(:BULLET)+_r(:REALNAME)],
	      [:td, [:input, {:name=>'realname'}]]],
	    [:tr,
	      [:th, _r(:BULLET)+_r(:NYUUGAKU_GAKUBU)],
	      [:td, [:select, {:name=>'faculty'},
		  [:option, {:name=>_r(:FACULTY_SS)}, _r(:FACULTY_SS)],
		  [:option, {:name=>_r(:FACULTY_EI)}, _r(:FACULTY_EI)],
		  [:option, {:name=>_r(:FACULTY_KI)}, _r(:FACULTY_KI)],
		  [:option, {:name=>_r(:FACULTY_SM)}, _r(:FACULTY_SM)]]]],
	    [:tr,
	      [:th, _r(:BULLET)+_r(:NYUUGAKU_NENDO)],
	      [:td, [:select, {:name=>'year'},
		  [:option, {:name=>'1990'}, '1990'],
		  [:option, {:name=>'1991'}, '1991'],
		  [:option, {:name=>'1992'}, '1992'],
		  [:option, {:name=>'1993'}, '1993'],
		  [:option, {:name=>'1994'}, '1994'],
		  [:option, {:name=>'1995'}, '1995'],
		  [:option, {:name=>'1996'}, '1996'],
		  [:option, {:name=>'1997'}, '1997'],
		  [:option, {:name=>'1998'}, '1998'],
		  [:option, {:name=>'1999'}, '1999'],
		  [:option, {:name=>'2000'}, '2000'],
		  [:option, {:name=>'2001'}, '2001'],
		  [:option, {:name=>'2002'}, '2002'],
		  [:option, {:name=>'2003'}, '2003']]]],
	    [:tr,
	      [:th, ''],
	      [:td, [:input, {:value=>_r(:MAKER_REGISTER),
		    :type=>'submit', :class=>'submit'}]]]]]]
    end

    def plg_ring_make_go(arg=nil)
      return	# obsolete
    end

    def ext_ring_make
      href = "#{@req.base}.html"
      mail = @req.user

      ring_member_page = @site.get_superpage(RING_MEMBER)
      ring_member_page = @site.create("_#{RING_MEMBER}") if ring_member_page.nil?
      if ring_member_page.wikidb.exist?(mail)
	return ring_make_already_exist(href)
      end

      username = @req.query['username']
      realname = @req.query['realname']
      faculty  = @req.query['faculty']
      year     = @req.query['year']

      if username.nil? || username.empty? || realname.nil? || realname.empty?
	return ring_make_not_registerd(href)
      end

      newpage = ring_make_create_newpage(username)
      newkey = newpage.key

      now = @req.start_time
      ring_member_page.wikidb.add(mail, username, realname,
				  faculty, year, newkey, now.to_i)

      return ring_make_registerd(href, username, realname, newkey)
    end

    def ring_maker_dummy_template
      str = '* #{username}
* profile
{{ring_personal_info}}
* message
{{ring_message_form}}
'
      return str
    end

    def ring_make_create_newpage(user)
      template_page = @site.get_superpage(RING_PAGE_TEMPLATE)

      if template_page
	content = template_page.load
      else
	content = ring_maker_dummy_template
      end

      content.sub!(/\#\{username\}/, user)
      page = @site.create_new	# Create new file.
      page.store(content)
      return page
    end

    def ring_make_not_registerd(href)
      return c_nerror(_r(:MAKER_NOT_REGISTERD)) {
	[[:h3, _r(:MAKER_NOT_REGISTERD)],
	  [:p, _r(:CONFIRM_YOUR_INPUT)],
	  [:p, [:a, {:href=>href}, _('Go back')]]]
      }
    end

    def ring_make_already_exist(href)
      return c_nerror(_r(:MAKER_ALREADY_REGISTERD)) {
	[[:h3, _r(:MAKER_ALREADY_REGISTERD)],
	  [:p, _r(:CONFIRM_YOUR_INPUT)],
	  [:p, [:a, {:href=>href}, _('Go back')]]]
      }
    end

    def ring_make_registerd(href, username, realname, newkey)
      return c_notice(_r(:MAKER_REGISTERD)) {
	[[:h3, _r(:MAKER_REGISTERD)],
	  [:dl,
	    [:dt, _r(:USER)], [:dd, username],
	    [:dt, _r(:REALNAME)], [:dd, realname]],
	  [:p, [:a, {:href=>"#{newkey}.html"}, _r(:MAKER_THE_PAGE)],
	    _r(:MAKER_SEE)]]
      }
    end

    # ============================== msg
    # ========== write a message
    # http://colinux:9190/ring.sfc.keio.ac.jp/_TestActRingMsg.html
    def plg_ring_message_form(arg=nil)
      action = "#{@req.base}.ring_msg"
      username = @req.user
      div = [:div, {:class=>'form'},
	[:form, {:method=>'POST', :action=>action},
	  [:table,
	    [:tr,
	      [:th, _r(:BULLET)+_r(:USER)],
	      [:td, username]],
	    [:tr,
	      [:th, _r(:BULLET)+_r(:MESSAGE)],
	      [:td, [:textarea, {:name=>'message', :cols=>'40', :rows=>'7'},
		  _r(:MSG_INPUT_HERE)]]],
	    [:tr,
	      [:th, ''],
	      [:td, [:input, {:type=>'submit', :class=>'submit',
		    :value=>" POST! "}]]]]]]
      return div
    end

    def plg_ring_message_go(arg=nil)
      return	# obsolete
    end

    # Append a a message to the page.
    def ext_ring_msg
      c_require_page_exist

      href = "#{@req.base}.html"
      message = @req.query['message']

      # Check error.
      if ! message || message.empty? || message == _r(:MSG_INPUT_HERE)
	return ring_msg_input_message(href)
      end

      mail = @req.user
      datenum = @req.start_time.to_i.to_s

      # Add a message.
      content = ":{{ring_ul(#{mail})}} ({{ring_date(#{datenum})}}):#{message}\n"
      page = @site[@req.base]
      page.add(content)

      return c_notice(_r(:MSG_MESSAGE_IS_ADDED), href){
	[[:h3, _r(:MSG_MESSAGE_IS_ADDED)],
	  [:p, _r(:THANKYOU)],
	  [:p, [:a, {:href=>href}, _('Go back')]]]
      }
    end

    def ring_msg_input_message(href)
      return c_notice(_r(:MSG_INPUT_MESSAGE), href, 200, 3) { # 3sec.
	[[:h3, _r(:MSG_INPUT_MESSAGE)],
	  [:p, [:a, {:href=>href}, _('Go back')]]]
      }
    end

    def plg_ring_date(n)
      time = Time.at(n.to_i)
      return [:span, {:class=>'ring_date'}, time.ymdx]
    end

    # ============================== new
    def pre_act_ring_new
      id   = @req.query['id']
      mail = @req.query['mail']

      # We need the id and mail.
      if id.nil? || mail.nil?
	return c_nerror('No id nor mail')
      end

      res = ring_new_create_account(id, mail)
      if res == 'exist'
	return c_nerror('Already exist')
      end

      div = [:div,
	[:p, 'id is ', id],
	[:p, 'mail is ', mail]]

      return c_notice(_r(:NEW_CREATED)) { div }
    end

    def ring_new_create_account(id, mail)
      message = _r(:NEW_FROM_SFCNEJP)

      host_mail = 'info@ring.sfc.ne.jp'		# dummy
      page = @site.get_superpage(RING_INVITE_MEMBER)
      page = @site.create('_'+RING_INVITE_MEMBER) if page.nil?
      now = @req.start_time

      guest_mail = id
      member = @site.member
      return 'exist' if member.exist_qwik_members?(guest_mail)
      member.add(guest_mail, host_mail)
      page.wikidb.add(guest_mail, '', host_mail, message, now.to_i)
      #ring_invite_sendmail(host_mail, guest_mail, '', message)
      return nil
    end

    # ============================== user
    # ========== manage user information.
    def ring_user_info(key, mail)
      # Get member database page.
      page = @site.get_superpage(key)
      return nil if page.nil?

      # Get the correspondig record to the mail.
      ar = page.wikidb[mail]
      return nil if ar.nil?	# No record.

      return ar
    end

    # ========== show user information
    def plg_ring_user(mail, type)
      ar = ring_user_info(RING_MEMBER, mail)
      return nil if ar.nil?

      type = type.to_s

      # Primary key is the mail address.
      return mail if type == 'mail'

      # You can select the values from these types.
      types = %w(user name faculty year pagename time)
      typenum = types.index(type)
      return nil if typenum.nil?
      return ar[typenum]
    end

    # ========== show my own information
    def plg_ring_show(arg)
      user = @req.user
      return plg_ring_user(user, arg)
    end

    def plg_ring_link(mail)
      user = plg_ring_user(mail, 'user')
      if user.nil? || user.empty?
	doc = c_res("[[anonymous]]")
	return doc[0][1]
      end

      pagename = plg_ring_user(mail, 'pagename')
      if pagename.nil? || pagename.empty?
	key = "[[#{user}]]"
      else
	key = "[[#{user}|#{pagename}]]" if pagename
      end

      doc = c_res(key)
      return doc[0][1]
    end

    def plg_ring_get_user_from_pagename(pagename)
      page = @site.get_superpage(RING_MEMBER)
      return if page.nil?

      page.wikidb.each {|k, ar|
	if ar[4] == pagename
	  return k
	end
      }

      return ''
    end

    # see the information of the owner of this page
    def plg_ring_see(arg)
      pagename = @req.base
      user = plg_ring_get_user_from_pagename(pagename)
      return '' if user.nil?
      return plg_ring_user(user, arg)
    end

    # see the personal information of this page
    def plg_ring_personal_info
      return [:dl,
	[:dt, _r(:NAME)+' E-mail'],
	[:dd, plg_ring_see(:name), " <", plg_ring_see(:mail), ">"],
	[:dt, _r(:NYUGAKU)],
	[:dd, plg_ring_see(:year), _r(:YEAR)+' ', plg_ring_see(:faculty)]]
    end

    # ring_user_link
    def plg_ring_ul(mail)
      span = [:span, {:class=>'ring_ul'}]

      user = plg_ring_user(mail, 'user')
      if user.nil?
	return span << mail
      end

      userpage = plg_ring_user(mail, 'pagename')
      if userpage.nil?
	return span << user
      end
      
      return span << [:a, {:href=>"#{userpage}.html"}, user]
    end

  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActRing < Test::Unit::TestCase
    include TestSession

    # ============================== catalog
    def test_catalog
      res = session
      eq "テスト", @action._r(:TEST)
    end

    # ============================== invite
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
	      [[:h3, "INVITE_NOSEND"],
		[:p, "もう一度入力を確認してください。"],
		[:p, [:a, {:href=>'1.html'}, 'Go back']]]],
	    "//div[@class='section']")

      res = session("/test/1.ring_invite?guest_mail=g@e.com&message=hi")
      ok_xp([:div, {:class=>'section'},
	      [[:h3, "INVITE_MAIL_IS_SENT"],
		[:dl, [:dt, "メッセージ"], [:dd, 'hi']],
		[:p, "どうもありがとうございました。"],
		[:p, [:a, {:href=>'1.html'}, 'Go back']]]],
	    "//div[@class='section']")

      eq '', page.load

      invite_member_page = @site['_'+Qwik::Action::RING_INVITE_MEMBER]
      eq ",g@e.com,,user@e.com,hi,0\n", invite_member_page.load

      member_page = @site['_SiteMember']
      eq ",user@e.com,
,g@e.com,user@e.com
", member_page.load
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
      ok_in(["INVITE_NOSEND"], '//h3')

      # Try to invite again.
      res = session("/test/1.ring_invite?guest_mail=gu@e.com&message=invite")
      ok_in(["INVITE_MAIL_IS_SENT"], '//h3')
      eq ",gu@e.com,,user@e.com,invite,0\n", @site['_RingInvitedMember'].load
      eq "Alan Smithy <user@e.com>", $smtp_sendmail[2]
      eq 'gu@e.com', $smtp_sendmail[3]
      assert_match(/^From/, $smtp_sendmail[4])
      url = "http://ring.sfc.keio.ac.jp/.getpass?mail=gu@e.com"
      assert_match(Regexp.new(Regexp.escape(url)), $smtp_sendmail[4])

      # Try to invite another person.
      res = session("/test/1.ring_invite?guest_mail=fe@e.com&message=youtoo")
      ok_in(["INVITE_MAIL_IS_SENT"], '//h3')
      eq ",gu@e.com,,user@e.com,invite,0\n,fe@e.com,,user@e.com,youtoo,0\n",
	@site['_RingInvitedMember'].load
      eq "Alan Smithy <user@e.com>", $smtp_sendmail[2]
      eq 'fe@e.com', $smtp_sendmail[3]
      assert_match(/^From/, $smtp_sendmail[4])
      url = "http://ring.sfc.keio.ac.jp/.getpass?mail=fe@e.com"
      assert_match(Regexp.new(Regexp.escape(url)), $smtp_sendmail[4])

      # See invited member list.
      page = @site.create_new
      page.store("{{ring_invite_list}}")

      res = session('/test/2.html')
      ok_in([:dl,
	      [:dt, [:span, {:class=>'ring_ul'},
		  [:a, {:href=>'1.html'}, 'Test User']],
		"→ (gu@e.com) 1970-01-01"],
	      [:dd, 'invite'],
	      [:dt, [:span, {:class=>'ring_ul'},
		  [:a, {:href=>'1.html'}, 'Test User']],
		"→ (fe@e.com) 1970-01-01"],
	      [:dd, 'youtoo']],
	    "//div[@class='ring_invite_list']")

      page = @site['_RingMember']
      eq ',user@e.com,Test User,Alan Smithy,ei,1990,1,0', page.load
      page = @site['_SiteMember']
      eq ",user@e.com,\n,gu@e.com,user@e.com\n,fe@e.com,user@e.com\n", page.load
    end

    # ============================== maker
    def test_plg_ring_make_form
      t_add_user

      page = @site.create_new
      page.store("{{ring_make_form}}")
      res = session('/test/1.html')
      assert_rattr({:action=>'1.ring_make', :method=>'POST'},
		   "//div[@class='section']/form")
    end

    def test_ext_ring_make
      t_add_user

      ring_member_page = @site.create('_'+Qwik::Action::RING_MEMBER)
      template_page = @site.create('_'+Qwik::Action::RING_PAGE_TEMPLATE)
      template_page.store("\#{username}")

      page = @site.create_new

      res = session('/test/1.ring_make')
      ok_xp([:div, {:class=>'section'},
	      [[:h3, "MAKER_NOT_REGISTERD"],
		[:p, "もう一度入力を確認してください。"],
		[:p, [:a, {:href=>'1.html'}, 'Go back']]]],
	    "//div[@class='section']")

      res = session("/test/1.ring_make?username=u&realname=r&faculty=f&year=1990")
      ok_xp([:div, {:class=>'section'},
	      [[:h3, "MAKER_REGISTERD"],
		[:dl, [:dt, "ユーザ名"], [:dd, 'u'], [:dt, "本名"], [:dd, 'r']],
		[:p, [:a, {:href=>'2.html'}, "MAKER_THE_PAGE"], "MAKER_SEE"]]],
	    "//div[@class='section']")
      page = @site['2']
      ok_eq('u', page.load)
      ok_eq(",user@e.com,u,r,f,1990,2,0\n", ring_member_page.load)
    end

    def ok_guest(e, w)
      user = 'gu@e.com'
      assert_path(e, w, user, "//div[@class='section']")
    end

    def test_make_page
      t_add_user

      page = @site['_SiteMember']
      page.store(",user@e.com,\n,gu@e.com,user@e.com\n")

      page = @site.create('r')
      page.store("{{ring_make_form}}")

      # Login as guest.
      res = session('/test/r.html') {|req|
	req.cookies.clear		# login as the guest
	pass = @memory.passgen.generate('gu@e.com')
	req.cookies.update({'user'=>'gu@e.com', 'pass'=>pass})
      }
      assert_rattr({:action=>'r.ring_make', :method=>'POST'}, '//form')

      # Make my page.
      res = session("/test/1.ring_make?page=RingMakePage&username=ゲスト&realname=山田太郎&faculty=総合政策&year=1990") {|req|
	req.cookies.clear		# login as the guest
	pass = @memory.passgen.generate('gu@e.com')
	req.cookies.update({'user'=>'gu@e.com', 'pass'=>pass})
      }
      ok_in(["MAKER_REGISTERD"], "//div[@class='section']//h3")
      ok_in(["ゲスト"], "//div[@class='section']//dd[1]")
      ok_in(["山田太郎"], "//div[@class='section']//dd[2]")
      ok_in(["MAKER_THE_PAGE"], "//div[@class='section']//a")
      ok_xp([:a, {:href=>'1.html'}, "MAKER_THE_PAGE"], "//div[@class='section']//a")
      ok_eq("* ゲスト
* profile
{{ring_personal_info}}
* message
{{ring_message_form}}
", @site["1"].load)

      # See my page.
      res = session('/test/1.html') {|req|
	req.cookies.clear		# login as the guest
	pass = @memory.passgen.generate('gu@e.com')
	req.cookies.update({'user'=>'gu@e.com', 'pass'=>pass})
      }
      assert_text("ゲスト", 'h1')
      assert_text('profile', 'h2')
      assert_rattr({:method=>'POST', :action=>'1.ring_msg'}, '//form')
      assert_match(/,gu@e.com,ゲスト,山田太郎,総合政策,1990,1,/,
		   @site['_RingMember'].load)
      ok_eq('gu@e.com', @action.plg_ring_user('gu@e.com', 'mail'))
      # @action.user = 'gu@e.com'
      #ok_eq('gu@e.com', @action.plg_ring_show('mail'))
      #ok_eq('gu@e.com', @action.plg_ring_show('mail'))
      ok_guest('gu@e.com', "{{ring_show(mail)}}")
      ok_guest("ゲスト",     "{{ring_show(user)}}")
      ok_guest("山田太郎",   "{{ring_show(name)}}")
      ok_guest("総合政策",   "{{ring_show(faculty)}}")
      ok_guest('1990',       "{{ring_show(year)}}")
      ok_guest('1',          "{{ring_show(pagename)}}")
      ok_guest(%r|\d+|,      "{{ring_show(time)}}")

      # See my page again.
      res = session('/test/1.html') # login as test again.

      # @action.user = 'user@e.com'
      # @action.pagename = '1'
=begin
      ok_wi('gu@e.com', "{{ring_user(guest@example.com, mail)}}")
      ok_wi('gu@e.com', "{{ring_see(mail)}}")
      ok_wi("ゲスト",     "{{ring_see(user)}}")
      ok_wi("山田太郎",   "{{ring_see(name)}}")
      ok_wi("総合政策",   "{{ring_see(faculty)}}")
      ok_wi('1990',       "{{ring_see(year)}}")
      ok_wi('1',          "{{ring_see(pagename)}}")
      ok_wi(%r|\d+|,      "{{ring_see(time)}}")
      ok_wi("<dl><dt>名前、E-mail</dt><dd>山田太郎 &lt;gu@e.com&gt;</dd><dt>入学</dt><dd>1990年 総合政策</dd></dl>", "{{ring_personal_info}}")
      ok_eq("* ゲスト\n{{ring_personal_info}}\n\n* profile\n# ここにprofileを記述してください。\n:研究会:\n:職業:\n:最近のマイブーム:\n\n* SEND MESSAGE\n{{ring_message_form}}\n\n* MESSAGE\n", @site['1'].load)
      ok_wi(/山田太郎/, @site['1'].load)
=end

      page = @site['1']
      ok_eq("{{ring_show(time)}}", page.load)

      page = @site['_RingMember']
      ok_eq(",gu@e.com,ゲスト,山田太郎,総合政策,1990,1,0\n", page.load)

      page = @site['_SiteMember']
      ok_eq(",user@e.com,\n,gu@e.com,user@e.com\n", page.load)
    end

    # ============================== msg
    def test_plg_ring_message_form
      t_add_user

      page = @site.create_new
      page.store("{{ring_message_form}}")

      # See the message form.
      res = session('/test/1.html')
      div = res.body.get_path("//div[@class='form']/form")
      ok_eq({:method=>'POST', :action=>'1.ring_msg'}, div.attr)
      ok_eq([:tr, [:th, "●ユーザ名"], [:td, 'user@e.com']],
	    div.get_path('/table/tr'))
      ok_xp([:input, {:value=>" POST! ", :type=>'submit', :class=>'submit'}],
	    "//div[@class='form']/input")
    end

    def test_ext_ring_msg
      t_add_user

      page = @site.create_new
      page.store('')

      # Try to write, but it cause error.
      res = session('/test/1.ring_msg')
      ok_in(["MSG_INPUT_MESSAGE"], '//h3')

      # Try to write, but it cause error.
      res = session("/test/1.ring_msg?message=")
      ok_in(["MSG_INPUT_MESSAGE"], '//h3')

      # Send a message.
      res = session("/test/1.ring_msg?message=Hi")
      ok_in(["MSG_MESSAGE_IS_ADDED"], '//h3')

      # Check the content.
      ok_eq(":{{ring_ul(user@e.com)}} ({{ring_date(0)}}):Hi\n", page.load)
    end

    def test_ring_link
      page = @site.create('_RingMember')
      page.store(",gu@e.com,gugu,T Y,ei,1990,1,0\n")

      ok_wi([:p, [:a, {:href=>'1.html'}, "ゲスト"]], "[[ゲスト|1]]")
      ok_wi([:a, {:href=>'1.html'}, 'gugu'], "{{ring_link('gu@e.com')}}")
      ok_wi([:span, {:class=>'ring_ul'}, [:a, {:href=>'1.html'}, 'gugu']],
	    "{{ring_ul('gu@e.com')}}")
    end

    # ============================== new
    def test_act_ring_new
      #t_add_user	# before login

      res = session('/test/.ring_new') {|req|
	req.cookies.clear	# before login
      }
      ok_title 'No id nor mail'

      res = session("/test/.ring_new?id=d@1990.sfc.ne.jp&mail=d@g.jp")
      ok_title 'NEW_CREATED'

      invite_member_page = @site['_'+Qwik::Action::RING_INVITE_MEMBER]
      ok_eq(",d@1990.sfc.ne.jp,,info@ring.sfc.ne.jp,NEW_FROM_SFCNEJP,0\n", invite_member_page.load)

      member_page = @site['_SiteMember']
      ok_eq(",d@1990.sfc.ne.jp,info@ring.sfc.ne.jp\n", member_page.load)
   end

    # ============================== user
    def ok_ui(e, mail, type)
      ok_eq(e, @action.plg_ring_user(mail, type))
    end

    def test_user
      t_add_user

      res = session

      # test_get_userinfo
      ok_ui(nil, 'user@e.com', 'mail')	# No record.

      # Store user infomation.
      page = @site.create('_RingMember')
      page.store(',user@e.com,Test User,Alan Smithy,ei,1990,1,0')

      ok_ui('user@e.com',	'user@e.com', 'mail')
      ok_ui('Test User',	'user@e.com', 'user')
      ok_ui('Alan Smithy',	'user@e.com', 'name')
      ok_ui('ei',		'user@e.com', 'faculty')
      ok_ui('1990',		'user@e.com', 'year')
      ok_ui('1',		'user@e.com', 'pagename')
      ok_ui('0',		'user@e.com', 'time')

      # test_plg_ring_user
      ok_wi(['user@e.com'], "{{ring_user(user@e.com,mail)}}")
      ok_wi(['Test User'], "{{ring_user(user@e.com,user)}}")
      ok_wi(['Alan Smithy'], "{{ring_user(user@e.com,name)}}")
      ok_wi(['ei'],	"{{ring_user(user@e.com,faculty)}}")
      ok_wi(['1990'],	"{{ring_user(user@e.com,year)}}")
      ok_wi(['1'],	"{{ring_user(user@e.com,pagename)}}")
      ok_wi(['0'],	"{{ring_user(user@e.com,time)}}")

      # test plg_ring_show
      ok_wi(['user@e.com'], "{{ring_show(mail)}}")
      ok_wi(['Test User'], "{{ring_show(user)}}")
      ok_wi(['Alan Smithy'], "{{ring_show(name)}}")
      ok_wi(['ei'],	"{{ring_show(faculty)}}")
      ok_wi(['1990'],	"{{ring_show(year)}}")
      ok_wi(['1'],	"{{ring_show(pagename)}}")
      ok_wi(['0'],	"{{ring_show(time)}}")

      # test plg_ring_link
      ok_wi([:a, {:href=>'1.html'}, 'Test User'],
	    "{{ring_link(user@e.com)}}")

      # test plg_ring_get_user_from_pagename
      ok_wi(['user@e.com'],
	    "{{ring_get_user_from_pagename(1)}}")

      # test plg_ring_see
      ok_wi(['user@e.com'], "{{ring_see(mail)}}")
      # same as ring_show in this page.

      # test plg_ring_personal_info
      ok_wi([:dl,
	      [:dt, "名前 E-mail"],
	      [:dd, "Alan Smithy", " <", "user@e.com", ">"],
	      [:dt, "入学"],
	      [:dd, '1990', "年 ", 'ei']],
	    "{{ring_personal_info}}")
    end

    def test_ring_link
      t_add_user

      page = @site.create_new
      page.store("{{ring_link('t@e.com')}}")
      res = session('/test/1.html')

      ringmember = @site.create('RingMember')
      ringmember.store(',t@e.com')

      page.store("{{ring_link('t@e.com')}}")
      res = session('/test/1.html')
      ok_in([:span, {:class=>'new'}, 'anonymous',
	      [:a, {:href=>".new?t=anonymous"},
		[:img, {:alt=>'create', :src=>'.theme/i/new.png'}]]],
	    "//div[@class='section']")

      ringmember.store(',t@e.com,t,Mr. T,EI,2004,1,0')

      page.store("{{ring_link('t@e.com')}}")
      res = session('/test/1.html')
      ok_xp([:a, {:href=>'1.html'}, 't'], "//div[@class='section']/a")

      page.store(":{{ring_link('t@e.com')}}:m")
      res = session('/test/1.html')
      ok_xp([:dl, [:dt, [:a, {:href=>'1.html'}, 't']], [:dd, 'm']],
	    "//div[@class='section']/dl")
    end

    def test_ring_loginstatus
      t_add_user
      res = session('/test/')	# You are logged in as user@e.com
      ok_in(['user@e.com'], "//div[@class='loginstatus']/em")
    end
  end
end
