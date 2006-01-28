#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '..' unless $LOAD_PATH.include?('..')

module Qwik
  class Action
    def pre_act_logout
      return basicauth_logout if @req.auth == 'basicauth'

      confirm = @req.query['confirm']
      if confirm.nil? || confirm != 'yes'
	return logout_show_confirm
      end

      session_clear

      @res.clear_cookie('user') # remove cookies from browser
      @res.clear_cookie('pass')
      @res.clear_cookie('sid')

      return c_notice(_('Logout done.'), 'FrontPage.html') {
	[:p, [:a, {:href=>'FrontPage.html'}, _('Go back')]]
      }
    end

    def logout_show_confirm
      title = _('Logout')+' '+_('Confirm')
      c_notice(title) {
	[[:p, _("Push \"Do Logout\".")],
	  logout_form,
	  [:hr],
	  [:p, [:a, {:href=>'FrontPage.html'}, _('Go next')]]]
      }
    end

    def logout_form
      [:div, {:class=>'logout'},
	[:form, {:method=>'POST', :action=>'.logout'},
	  [:input, {:type=>'hidden', :name=>'confirm', :value=>'yes'}],
	  [:input, {:type=>'submit', :value=>_('Do Logout'), :class=>'focus'}]]]
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
      # test it in act-login.rb
    end
  end
end