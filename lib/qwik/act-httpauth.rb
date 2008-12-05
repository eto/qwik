# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH << 'compat' unless $LOAD_PATH.include? 'compat'
require 'base64'

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    # ref: webrick/httpauth.rb
    def check_basicauth
      auth = @req['Authorization']
      return if auth.nil?
      return unless /^Basic\s+(.*)/o =~ auth

      user, pass = Base64.decode64($1).split(':', 2)
      return if user.nil?

      raise InvalidUserError if user.nil? || user.empty?
      raise InvalidUserError unless MailAddress.valid?(user)
      gen = @memory.passgen
      raise InvalidUserError if !gen.match?(user, pass)
      @req.user = user
      @req.auth = 'basicauth'
      return
    end

    # ref: webrick/httpauth.rb
    def pre_act_basicauth
      if ! @req.user	# Try to Login by using Basic Auth.
	realm = 'qwik'
	@res['WWW-Authenticate'] = "Basic realm=\"#{realm}\""
	# status code must be 401
	return c_notice(_('Log in by Basic Authentication.'), nil, 401) {
	  [[:h2, _('Logging in by Basic Authentication.')],
	    [:p, _("Please input ID (E-mail) and password.")],
	    [:hr],
	    [:p, [:a, {:href=>'FrontPage.html'}, _('Go back')]]]
	}
      end

      # Already logged in.
      if @req.auth != 'basicauth'	# But, the method is not Basic Auth.
	return c_notice(_('Login by cookie')) {
	  [[:h2, _('You are already login by cookie.')],
	    [:hr],
	    [:p, [:a, {:href=>'FrontPage.html'}, _('Go back')]]]
	}
      end

      return c_notice(_('Log in by Basic Authentication.')) {
	[[:h2, _('Log in using Basic Authentication.')],
	  [:hr],
	  [:p, [:a, {:href=>'FrontPage.html'}, _('Go back')]]]
      }
    end

    def basicauth_logout
      return c_notice(_('Basic Authentication') + ' ' + _('Log out')) {
	[[:h2, _('Can not log out.')],
	  [:p, _('You can not log out in Basic Authentication mode.'), [:br],
	    _('Please close browser and access again.')],
	  [:hr],
	  [:p, [:a, {:href=>'FrontPage.html'}, _('Go back')]]]
      }
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActHttpAuth < Test::Unit::TestCase
    include TestSession

    def test_all
      t_add_user

      # See the FrontPage.
      res = session '/test/'
      ok_title 'FrontPage'

      # See the FrontPage before Login.
      res = session('/test/') {|req|
	req.cookies.clear
      }
      ok_title 'Login'
      ok_xp [:meta, {:content=>"1; url=/test/.login", 'http-equiv'=>'Refresh'}],
	    "//meta[2]"

      # See the Login page.
      res = session('/test/.login') {|req|
	req.cookies.clear
      }
      ok_title 'Login'
#      ok_xp [:a, {:href=>'.getpass'}, [:em, 'Get Password']],
#	    "//div[@class='section']/a"
#      ok_xp [:a, {:href=>'.basicauth'}, 'Log in by Basic Authentication.'],
#	    "//div[@class='section']/a[2]"

      # See the Basic Auth Login page.
      res = session('/test/.basicauth') {|req|
	req.cookies.clear
      }
      ok_title('Log in by Basic Authentication.')
      ok_eq(401, @res.status)
      ok_eq("Basic realm=\"qwik\"", @res['WWW-Authenticate'])

      # test base64
      ok_eq("dXNlckBlLmNvbTo5NTk4ODU5Mw==\n",
	    Base64.encode64(DEFAULT_USER+':95988593'))

      # Try to Login by Basic Authenticate.
      res = session('/test/.basicauth') {|req|
	req.cookies.clear
	req.header['authorization'] =
	  ["Basic dGVzdEBleGFtcGxlLmNvbTo0NDQ4NDEyNQ=="]
      }
      ok_title('Log in by Basic Authentication.')
      ok_eq(200, @res.status)
      ok_eq(nil, @res['WWW-Authenticate'])
      ok_xp([:a, {:href=>'FrontPage.html'}, 'Go back'], '//a')

      # Try to see FrontPage
      res = session('/test/') {|req|
	req.cookies.clear
	req.header['authorization'] =
	  ["Basic dXNlckBlLmNvbTo5NTk4ODU5Mw=="]
      }
      ok_title('FrontPage')

      # test_logout
      res = session('/test/.logout') {|req|
	req.cookies.clear
	req.header['authorization'] =
	  ["Basic dXNlckBlLmNvbTo5NTk4ODU5Mw=="]
      }
      ok_title('Basic Authentication Log out')
      assert_text('Can not log out.', 'h2')
    end
  end
end
