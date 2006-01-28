#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '..' unless $LOAD_PATH.include?('..')
require 'qwik/mail'
require 'qwik/password'
require 'qwik/act-httpauth'
require 'qwik/act-typekey'
require 'qwik/act-logout'

module Qwik
  class Action
    # ============================== show status
    def plg_login_status
      if @req.user
	return [:span, {:class=>'loginstatus'},
	  'user', ' | ', plg_login_user,
	  " (", [:a, {:href=>'.logout'}, ('Logout')], ")"]
      else
	return login_create_login_link
      end
    end

    def nu_login_create_login_link(msg='Login')
      sitename = @site.sitename
      pagename = @req.base
      href = '/.login'
      href += "?site="+sitename if sitename
      href += "&page="+pagename if pagename
      return [:a, {:href=>href}, msg]
    end

    def login_create_login_link
      return [:a, {:href=>'.login'}, 'Login']
    end

    def plg_login_user
      return [:em, @req.user]
    end

    # ============================== verify
    # called from action.rb
    def login_get_user
      check_session	# act-session: Check session id.
      return if @req.user

      check_cookie	# Get user from cookie.
      return if @req.user

      check_basicauth	# Get user from basicauth.
      return if @req.user
    end

    def check_cookie
      userpass = @req.cookies['userpass']
      if userpass
	#qp userpass
	user, pass = userpass.split(',', 2)
      else
	user = @req.cookies['user']
	pass = @req.cookies['pass']
	#qp user, pass
      end

      if user
	#qp user, pass

	return if user.nil? || user.empty?
	#return unless MailAddress.new(user).valid?
	return unless MailAddress.valid?(user)
	gen = @memory.passgen
	#qp gen.match?(user, pass)
	return unless gen.match?(user, pass)

	@req.user = user
	@req.auth = 'cookie'

	# Do not move to session id for now.
	# sid = session_store(user)	# Move to session id.
	# @res.set_cookie('sid', sid)	# Set Session id by cookie
      end
    end

    # called from action.rb
    def login_invalid_user
      c_nerror(_('Login Error')){[
	  [:p, [:strong, _("Invalid ID(E-mail) or Password.")]],
	  [:p, {:class=>'warning'},
	    _("If you don't have password, "), _('access here'), [:br],
	    [:a, {:href=>'.getpass'}, [:em, _('Get Password')]]],
	  login_page_form,
	  login_page_menu,
	]}
    end

    # ============================== login
    def pre_act_login
      if @req.user
	return login_already_logged_in(@req.user)
      end

      user = @req.query['user'] # login from query
      pass = @req.query['pass']

      if !user
	return c_notice(_('Login')) {
	  login_show_login_page(@site.site_url) # show login page
	}
      end

      begin
	raise InvalidUserError if user.nil? || user.empty?
	#raise InvalidUserError unless MailAddress.new(user).valid?
	raise InvalidUserError unless MailAddress.valid?(user)
	gen = @memory.passgen
	raise InvalidUserError unless gen.match?(user, pass)

      rescue InvalidUserError
	@res.clear_cookies	# important
	return login_invalid_user	# password does not match
      end

      sid = session_store(user)
      @res.set_cookie('sid', sid) # Set Session id by cookie.

      return login_show_login_suceed_page
    end

    def login_already_logged_in(user)
      ar = []
      ar << [:p, _('You are now logged in as this user id.'), [:br],
	[:strong, user]]
      ar << [:p, _('If you would like to login as another account,'), [:br],
	_('do logout at the first.')]
      ar << logout_form
      ar << [:hr]
      ar << login_go_frontpage
      return c_nerror(_('Already logged in')){ar}
    end

    def login_go_frontpage
      style = "
 margin: 8px;
 padding: 2px;
 background: #eee;
 border: 2px solid #66c;
"
      style = ''
      return [:div, {:class=>'go_frontpage',:style=>''},
#	[:a, {:href=>"/#{@req.sitename}/FrontPage.html", :style=>"
	[:a, {:href=>'FrontPage.html', :style=>style}, 'FrontPage']]
    end

    def login_show_login_page(url)
      login_msg = ''
      page = @site['_LoginMessage']
      if page
	login_msg = [:div, {:class=>'warning'}, c_res(page.load)]
      end
      div = [:div, {:class=>'login_page'},
	[:p, _('Login to '), [:em, url], [:br],
	  _("Please input ID(E-mail) and password.")]]
      div << login_msg
      div << login_page_form
      div << login_page_menu
      return div
    end

    def login_show_login_suceed_page
     #url = "/#{@req.sitename}/FrontPage.html"
      url = 'FrontPage.html'
      title = _('Login') + ' ' + _('succeed')
      return c_notice(title, url) {
	[login_go_frontpage]
      }
    end

    private

    def login_page_form
      return [:div, {:class=>'login'},
	[:form, {:method=>'POST', :action=>'.login'},
	  [:dl,
	    [:dt, _('ID'), "(E-mail)", ': '],
	    [:dd, [:input, {:name=>'user', :istyle=>'3', :class=>'focus'}]],
	    [:dt, _('Password'), ': '],
	    [:dd, [:input, {:type=>'password', :name=>'pass'}]]],
	  [:p,
	    [:input, {:type=>'submit', :value=>_('Login')}]]]]
    end

    def login_page_menu
      return [:ul,
	[:li, _("If you don't have password"), ' : ',
	  [:a, {:href=>'.getpass'}, [:em, _('Get Password')]]],
	[:li, _('For mobile phone user'), ' : ',
	  [:a, {:href=>'.basicauth'}, _('Login by Basic Auth')]],
	[:li,
	  [:a, {:href=>'.typekey'}, _('Login by TypeKey')]]]
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActLogin < Test::Unit::TestCase
    include TestSession

    def assert_cookie(hash, cookies)
      cookies.each {|cookie|
	ok_eq(cookie.value, hash[cookie.name])
      }
    end

    def test_private_site
      t_add_user

      # See FrontPage.
      res = session('/test/') {|req|
	req.cookies.clear
      }
      ok_title('Login')
      ok_xp([:meta, {:content=>"1; url=/test/.login",
		'http-equiv'=>'Refresh'}],
	    "//meta[2]")

      # See login page.
      res = session('/test/.login') {|req|
	req.cookies.clear
      }
      ok_title('Login')
      ok_xp([:input, {:istyle=>'3', :name=>'user', :class=>'focus'}],
	    '//input')
      ok_xp([:a, {:href=>'.getpass'}, [:em, 'Get Password']], '//a')
      assert_cookie({'user'=>'', 'pass'=>''}, @res.cookies)

      # Get password by e-mail.  See act-getpass.

      # Invalid mail address
      res = session("/test/.login?user=test@example") {|req|
	req.cookies.clear
      }
      assert_text("Invalid ID(E-mail) or Password.", 'p')

      # Invalid password
      res = session("/test/.login?user=user@e.com&pass=wrongpassword") {|req|
	req.cookies.clear
      }
      assert_text("Invalid ID(E-mail) or Password.", 'p')

      # Login by GET method. Set cookies and redirect to FrontPage.
      res = session("/test/.login?user=user@e.com&pass=95988593") {|req|
	req.cookies.clear
      }
      ok_title('Login succeed')
      #assert_cookie({'user'=>'user@e.com', 'pass'=>'95988593'}, @res.cookies)
      ok_eq('sid', @res.cookies[0].name)
      ok_eq(32, @res.cookies[0].value.length)
      #pw('//head')
      ok_xp([:meta, {:content=>"0; url=FrontPage.html",
		'http-equiv'=>'Refresh'}],
	    "//meta[2]") # force redirect for security reason.

      # Set the cookie
      res = session('/test/') {|req|
	req.cookies.update({'user'=>'user@e.com', 'pass'=>'95988593'})
      }
      ok_title('FrontPage')
      assert_cookie({'user'=>'user@e.com', 'pass'=>'95988593'},
		    @res.cookies)
      #      ok_eq('sid', @res.cookies[0].name)
      #      ok_eq(32, @res.cookies[0].value.length)

      # Use POST method to set user and pass by queries.
      res = session("POST /test/.login?user=user@e.com&pass=95988593") {|req|
	req.cookies.clear
      }
      ok_title('Login succeed')
      ok_eq(200, @res.status)
      #assert_cookie({'user'=>'user@e.com', 'pass'=>'95988593'}, @res.cookies)
      ok_eq('sid', @res.cookies[0].name)
      ok_eq(32, @res.cookies[0].value.length)
      ok_xp([:meta, {:content=>"0; url=FrontPage.html",
		'http-equiv'=>'Refresh'}],
	    "//meta[2]") # force redirect for security reason.

      # test_login_status
      res = session('/test/')
      ok_in(['user', ' | ', [:em, 'user@e.com'],
	      " (", [:a, {:href=>'.logout'}, 'Logout'], ")"],
	    "//span[@class='loginstatus']")

      # See TextFormat
      res = session('/test/TextFormat.html')

      # See the Logout page.
      res = session('/test/.logout')
      ok_title('Logout Confirm')
      ok_xp([:form, {:action=>'.logout', :method=>'POST'},
	      [:input, {:value=>'yes', :type=>'hidden',
		  :name=>'confirm'}], [:input, {:value=>'Do Logout',
		  :type=>'submit', :class=>'focus'}]], '//form')
      ok_xp([:input, {:value=>'yes', :type=>'hidden', :name=>'confirm'}],
	    '//input')
      ok_xp([:input, {:value=>'Do Logout',
		:type=>'submit', :class=>'focus'}], "//input[2]")

      # Confirm Logout.
      res = session("/test/.logout?confirm=yes")
      ok_title('Logout done.')
      assert_text('Logout done.', 'h1')
      ok_xp([:p, [:a, {:href=>'FrontPage.html'}, 'Go back']],
	    "//div[@class='section']/p")
      assert_cookie({'user'=>'', 'pass'=>'', 'sid'=>''}, @res.cookies)
      #ok_eq('sid', @res.cookies[0].name)
      #ok_eq(32, @res.cookies[0].value.length)
    end

    def test_open_site
      t_add_user
      t_site_open # OPEN site

      # See FrontPage. Check login_status before login.
      res = session('/test/') {|req|
	req.cookies.clear
      }
      ok_title('FrontPage')
      ok_in(['Login'], "//div[@class='adminmenu']//a")
      ok_in([[:a, {:href=>'.login'}, 'Login'],
	      ["\n"], ["\n"]],
	    "//div[@class='adminmenu']")

      # You can see login page before login.
      res = session('/test/.login') {|req|
	req.cookies.clear
      }
      ok_title('Login')
    end
  end
end