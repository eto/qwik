#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '..' unless $LOAD_PATH.include?('..')
require 'qwik/act-ring-common'
require 'qwik/act-ring-user'
require 'qwik/act-ring-msg'

module Qwik
  class Action
    # ============================== make user page from template
    # http://colinux:9190/ring.sfc.keio.ac.jp/_TestActRingMaker.html
    def plg_ring_make_form(dest=nil)
      action = @req.base+'.ring_make'
      mail = @req.user
      return [:div, {:class=>'form'},
	[:form, {:action=>action, :method=>'POST'},
	  [:table,
	    [:tr,
	      [:th, _r(:BULLET)+_r(:MAIL)],
	      [:td, mail]],
	    [:tr,
	      [:th, _r(:BULLET)+_r(:USER_NAME)],
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
      href = @req.base+'.html'
      mail = @req.user

      ring_member_page = c_get_superpage(RING_MEMBER)
      ring_member_page = @site.create('_'+RING_MEMBER) if ring_member_page.nil?
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
      template_page = c_get_superpage(RING_PAGE_TEMPLATE)

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
	[[:h3, "登録されました"],
	  [:dl,
	    [:dt, "ユーザ名"], [:dd, username],
	    [:dt, "本名"], [:dd, realname]],
	  [:p, [:a, {:href=>newkey+'.html'}, "作ったページ"], "を見る。"]]
      }
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActRingMaker < Test::Unit::TestCase
    include TestSession

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
	      [[:h3, "登録されませんでした。"],
		[:p, "もう一度入力を確認してください。"],
		[:p, [:a, {:href=>'1.html'}, 'Go back']]]],
	    "//div[@class='section']")

      res = session("/test/1.ring_make?username=u&realname=r&faculty=f&year=1990")
      ok_xp([:div, {:class=>'section'},
	      [[:h3, "登録されました"],
		[:dl, [:dt, "ユーザ名"], [:dd, 'u'], [:dt, "本名"], [:dd, 'r']],
		[:p, [:a, {:href=>'2.html'}, "作ったページ"], "を見る。"]]],
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
      ok_in(["登録されました"], "//div[@class='section']//h3")
      ok_in(["ゲスト"], "//div[@class='section']//dd[1]")
      ok_in(["山田太郎"], "//div[@class='section']//dd[2]")
      ok_in(["作ったページ"], "//div[@class='section']//a")
      ok_xp([:a, {:href=>'1.html'}, "作ったページ"], "//div[@class='section']//a")
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
  end
end
