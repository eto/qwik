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

module Qwik
  class Action
    # ============================== manage user information.
    def ring_user_info(key, mail)
      # Get member database page.
      page = c_get_superpage(key)
      return nil if page.nil?

      # Get the correspondig record to the mail.
      ar = page.wikidb[mail]
      return nil if ar.nil?	# No record.

      return ar
    end

    # ============================== show user information
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

    # ============================== show my own information
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
      page = c_get_superpage(RING_MEMBER)
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
	[:dt, _r(:USER_NAME)+' E-mail'],
	[:dd, plg_ring_see(:name), " <", plg_ring_see(:mail), ">"],
	[:dt, _r(:USER_NYUGAKU)],
	[:dd, plg_ring_see(:year), _r(:USER_YEAR)+' ', plg_ring_see(:faculty)]]
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
      
      return span << [:a, {:href=>userpage+".html"}, user]
    end
  end
end

if $0 == __FILE__
  $LOAD_PATH << '../../lib' unless $LOAD_PATH.include?('../../lib')
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActRingUser < Test::Unit::TestCase
    include TestSession

    def ok_ui(e, mail, type)
      ok_eq(e, @action.plg_ring_user(mail, type))
    end

    def test_all
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
	      [:dt, "–¼‘O E-mail"],
	      [:dd, "Alan Smithy", " <", "user@e.com", ">"],
	      [:dt, "“üŠw"],
	      [:dd, '1990', "”N ", 'ei']],
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
