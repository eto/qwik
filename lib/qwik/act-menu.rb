# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    D_PluginMenu = {
      :dt => 'Menu plugin',
      :dd => 'You can show a pull down menu.',
      :dc => "* Example
{{hmenu
- [[Yahoo!|http://www.yahoo.co.jp/]]
-- [[map|http://map.yahoo.co.jp/]]
-- [[auctions|http://aunctions.yahoo.co.jp/]]
- [[Google|http://www.google.co.jp/]]
-- [[news|http://news.google.com/]]
-- [[map|http://map.google.com/]]
- [[qwik|http://qwik.jp/]]
-- [[hello|http://qwik.jp/HelloQwik/]]
}}

{{br}}
{{br}}
{{br}}
{{br}}

{{{
{{hmenu
- [[Yahoo!|http://www.yahoo.co.jp/]]
-- [[map|http://map.yahoo.co.jp/]]
-- [[auctions|http://aunctions.yahoo.co.jp/]]
- [[Google|http://www.google.co.jp/]]
-- [[news|http://news.google.com/]]
-- [[map|http://map.google.com/]]
- [[qwik|http://qwik.jp/]]
-- [[hello|http://qwik.jp/HelloQwik/]]
}}
}}}
"
    }

    D_PluginMenu_ja = {
      :dt => 'メニュー・プラグイン',
      :dd => 'プルダウン型メニューを作れます。',
      :dc => "* 例
{{hmenu
- [[Yahoo!|http://www.yahoo.co.jp/]]
-- [[map|http://map.yahoo.co.jp/]]
-- [[auctions|http://aunctions.yahoo.co.jp/]]
- [[Google|http://www.google.co.jp/]]
-- [[news|http://news.google.com/]]
-- [[map|http://map.google.com/]]
- [[qwik|http://qwik.jp/]]
-- [[hello|http://qwik.jp/HelloQwik/]]
}}

{{br}}
{{br}}
{{br}}
{{br}}

{{{
{{hmenu
- [[Yahoo!|http://www.yahoo.co.jp/]]
-- [[map|http://map.yahoo.co.jp/]]
-- [[auctions|http://aunctions.yahoo.co.jp/]]
- [[Google|http://www.google.co.jp/]]
-- [[news|http://news.google.com/]]
-- [[map|http://map.google.com/]]
- [[qwik|http://qwik.jp/]]
-- [[hello|http://qwik.jp/HelloQwik/]]
}}
}}}
"
    }

    def plg_hmenu
      ar = []

      menu_define_style(ar)	# Define style first.

      content = yield
      w = c_res(content)

      w.each {|e|
	if e.is_a?(Array) && e[0] == :ul
	  e.set_attr(:class=>'m1')
	  e.each {|ee|
	    if ee.is_a?(Array) && ee[0] == :li
	      ee.set_attr(:class=>'off')
	      ee.set_attr(:onmouseover=>"this.className='on'")
	      ee.set_attr(:onmouseout=>"this.className='off'")
	    elsif ee.is_a?(Array) && ee[0] == :ul
	      ee.set_attr(:class=>'m2')
	    end
	  }
	end
      }

      div = [:div, {:class=>'hmenu'}] + w
      ar << div
      return ar
    end

    def menu_define_style(ar)
      if ! defined?(@menu_defined)
	@menu_defined = true
	ar << [:style, "@import '.theme/css/menu.css';"]
      end
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActMenu < Test::Unit::TestCase
    include TestSession

    def test_plg_hmenu
      t_add_user
      page = @site.create_new
      page.store("{{hmenu
- t
-- s
}}")
      res = session('/test/1.html')
      menu = [:div, {:class=>'hmenu'},
	[:ul, {:class=>'m1'},
	  [:li, {:onmouseover=>"this.className='on'",
	      :onmouseout=>"this.className='off'",
	      :class=>'off'}, 't'],
	  [:ul, {:class=>'m2'}, [:li, 's']]]]
      ok_xp(menu, "//div[@class='hmenu']")
    end
  end
end
