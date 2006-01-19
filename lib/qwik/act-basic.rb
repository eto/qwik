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
    D_basic = {
      :dt => 'Basic plugins',
      :dd => "Simple and Basic plugins.",
      :dc => "* Description
** BR plugin
You can input <br> inline.
 This is {{br}} a test.
This is {{br}} a test.

** Window plugin
Open with new window plugin

You can make a link to show the page in a new window.
 {{window(http://qwik.jp/)}}
{{window(http://qwik.jp/)}}
Open the link in a new window.

** Comment out plugin
You can comment it out.
 {{com
 You can not see this line.
 You can not see this line also.
 }}
{{com
You can not see this line.
You can not see this line also.
}}
You see nothing here.

** Last modified plugin
You can show last modified date by this plugin.
 {{last_modified}}
{{last_modified}}

** Information only for guests and only for members
You can specify the content is only for guests or only for members.
 {{only_guest
 This string is '''only for guest'''.
 }}
{{only_guest
This string is '''only for guest'''.
}}
If you are a guest, you see \"This string is '''only for guest'''.\"

 {{only_member
 This string is '''only for member'''.
 }}
{{only_member
This string is '''only for member'''.
}}
If you are a member, you see \"This string is '''only for member'''.\"
" }

    # ==============================
    def plg_qwik_null
      return ''
    end

    def plg_qwik_test
      return 'test'
    end

    # ==============================
    def plg_br
      return [:br]
    end

    # ==============================
    def plg_window(url, text=nil)
      text = url if text.nil?
      return [:a, {:href=>url, :target=>'_blank'}, text]
    end

    # ==============================
    def plg_com(*args)	# commentout
      #str = yield if block_given?
      return nil	# ignore all
    end

    # ==============================
    def plg_sitemenu
      return page_attribute('html', _('SiteMenu'), '_SiteMenu')
    end
    alias plg_show_sitemenu plg_sitemenu
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActBasic < Test::Unit::TestCase
    include TestSession

    def test_all
      # test_br
      ok_wi([:br], "{{br}}")

      # test_window
      ok_wi([:a, {:target=>'_blank', :href=>'url'}, 't'], "{{window(url,t)}}")
      ok_wi([:a, {:target=>'_blank', :href=>'url'}, 'url'], "{{window(url)}}")

      # test_show_sitemenu
      ok_wi([:span, {:class=>'attribute'},
	      [:a, {:href=>'_SiteMenu.html'}, 'SiteMenu']],
	    "{{show_sitemenu}}")
    end
  end
end
