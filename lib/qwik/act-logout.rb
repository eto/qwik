# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    def pre_act_logout
      return basicauth_logout if @req.auth == 'basicauth'

      confirm = @req.query['confirm']
      if confirm.nil? || confirm != 'yes'
	return logout_show_confirm
      end

      session_clear

      @res.clear_cookie('user')		# Remove cookies from browser.
      @res.clear_cookie('pass')
      @res.clear_cookie('sid')

      return c_notice(_('Log out done.'), 'FrontPage.html') {
	[:p, [:a, {:href=>'FrontPage.html'}, _('Go back')]]
      }
    end

    def logout_show_confirm
      title = _('Log out')+' '+_('Confirm')
      c_notice(title) {
	[[:p, _('Push "Log out".')],
	  logout_form,
	  [:hr],
	  [:p, [:a, {:href=>'FrontPage.html'}, _('Go next')]]]
      }
    end

    def logout_form
      return [:div, {:class=>'logout'},
	[:form, {:method=>'POST', :action=>'.logout'},
	  [:input, {:type=>'hidden', :name=>'confirm', :value=>'yes'}],
	  [:input, {:type=>'submit', :value=>_('Log out'), :class=>'focus'}]]]
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActLogout < Test::Unit::TestCase
    include TestSession

    def test_all
      # The test for logout is already done in act-login.rb
    end
  end
end
