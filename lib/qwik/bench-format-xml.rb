# -*- coding: shift_jis -*-
# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/bench-module-session'
require 'qwik/wabisabi-format-xml'

class BenchFormatXml
  XML_FORMATTER_EXAMPLE =
    [[:'!DOCTYPE', 'html', 'PUBLIC', '-//W3C//DTD HTML 4.01 Transitional//EN', 'http://www.w3.org/TR/html4/loose.dtd'],
    [:html,
      [:head, {:id=>'header'},
	[[:title, 'TestPage - example.com/test'],
	  [:link, {:type=>'text/css', :rel=>'stylesheet', :media=>'screen,tv,print', :href=>'/.theme/qwikgreen/qwikgreen.css'}],
	  [:link, {:type=>'text/css', :rel=>'stylesheet', :media=>'screen,tv,print', :href=>'/.theme/base.css'}]]],
      [:body,
	[:div, {:class=>'container'},
	  [:div, {:class=>'main'},
	    [:div, {:id=>'adminmenu', :class=>'adminmenu'},
	      [[:span, {:class=>'loginstatus'}, 'user | ', [:em, 'user@e.com'], ' (', [:a, {:href=>'.logout'}, 'logout'], ')'],
		[:ul,
		  [:li, [:a, {:href=>'.new'}, '新規作成']],
		  [:li, [:a, {:href=>'TestPage.edit'}, '編集']]]]],
	    [:h1, {:id=>'view_title'}, 'TestPage'],
	    [:div, {:id=>'body'},
	      [[:div, {:class=>'day'},
		  [:h2, 'h2'],
		  [:div, {:class=>'body'},
		    [:div, {:class=>'section'}, [[:p, 'text']]]]]]],
	    [:div, {:id=>'body_leave'},
	      [:div, {:class=>'day'},
		[:div, {:class=>'comment'},
		  [:div, {:class=>'caption'},
		    [:div, {:class=>'page_attribute'},
		      [:div, {:class=>'qrcode'},
			[:a, {:href=>'http://example.com/test/'},
			  [:img, {:src=>'.attach/qrcode-test.png', :alt=>'http://example.com/test/'}],
			  [:br], 'http://example.com/test/']],
		      [:div, 'last modified: 2004-10-05'],
		      [:a, {:href=>'TestPage.backup'}, 'Backup list']]]],
		[:div, {:class=>'body_leave'}, '']]]],
	  [:div, {:id=>'sidemenu', :class=>'sidebar'},
	    [[:h2, 'menu'],
	      [:ul,
		[:li, [:a, {:href=>'/test/FrontPage.html'}, 'FrontPage']],
		[:li, [:a, {:href=>'/test/TitleList.html'}, 'TitleList']],
		[:li, [:a, {:href=>'/test/RecentList.html'}, 'RecentList']],
		[:li, [:a, {:href=>'/test/TextFormat.html'}, 'TextFormat']],
		[:li, [:a, {:href=>'/test/_SiteMenu.html'}, '_SiteMenu']]],
	      [:h2, 'recent change'],
	      [:h3, '2004-10-05'],
	      [:ul, [:li, [:a, {:href=>'/test/TestPage.html'}, 'TestPage']]]]],
	  [:div, {:id=>'footer', :class=>'footer'},
	    [[:p, 'powered by ',
		[:a, {:class=>'external', :href=>'http://example.com/'}, 'qwikWeb']]]]]]]]

  def self.main
    ws = XML_FORMATTER_EXAMPLE
    n = 10000
    BenchmarkModule::benchmark {
      n.times {
	dummy = ws.format_xml
      }
    }
  end
end

BenchFormatXml.main
