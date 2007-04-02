# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    D_PluginInclude = {
      :dt => 'Include plugin',
      :dd => 'You can include other page.',
      :dc => "* Example
You can see the FrontPage is included here.
{{include('FrontPage')}}
 {{include('FrontPage')}}
"
    }

    D_PluginInclude_ja = {
      :dt => '取り込みプラグイン',
      :dd => '他のページの内容をとりこみます。',
      :dc => "* 例
FrontPageの内容を埋め込んでみます。
{{include('FrontPage')}}
 {{include('FrontPage')}}
"
    }

    def plg_include(pagename)
      pagename = pagename.to_s
      page = @site[pagename]
      return nil if page.nil?

      org_base = @req.base
      @req.base = pagename

      body = surface_get_body(page)

      @req.base = org_base

      return body
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActInlcude < Test::Unit::TestCase
    include TestSession

    def ok(e, w, user=DEFAULT_USER)	# assert_body_main
      assert_path(e, w, user, "//div[@class='body_main']")
    end

    def ok_day(e, w, user=DEFAULT_USER)
      assert_path(e, w, user, "//div[@class='day']")
    end

    def test_include
      page = @site.create_new
      page.store("* t
* t")
      page2 = @site.create_new
      page2.store("* t2
* t2")
      key = page2.key
      ok_day(['',
	       [:div,
		 {:class=>'body'},
		 [:div,
		   {:class=>'section'},
		   [[:div,
		       {:class=>'day'},
		       [:h2, {:id=>'t2'}, 't2'],
		       [:div, {:class=>'body'},
			 [:div, {:class=>'section'}, []]]]]]]],
	     "{{include(#{key})}}")

      ok([:div,
	   {:class=>'day'},
	   '',
	   [:div,
	     {:class=>'body'},
	     [:div,
	       {:class=>'section'},
	       [[:div,
		   {:class=>'day'},
		   [:h2, {:id=>'t2'}, 't2'],
		   [:div, {:class=>'body'},
		     [:div, {:class=>'section'}, []]]]]]]],
	 "{{include(#{key})}}")

      config = @site['_SiteConfig']
      config.store(':titlelink:true')
      ok([:div,
	   {:class=>'day'},
	   '',
	   [:div,
	     {:class=>'body'},
	     [:div,
	       {:class=>'section'},
	       [[:div,
		   {:class=>'day'},
		   [:h2,
		     [:a, {:href=>"2.html#t2", :name=>'t2', :class=>'label'},
		       "■"],
		     't2'],
		   [:div, {:class=>'body'},
		     [:div, {:class=>'section'}, []]]]]]]],
	 "{{include(#{key})}}")

      config.store('')
    end

    def test_include_with_titlelink
      t_add_user

      page = @site.create('t1')
      page.store("* t1
{{include(t2)}}")
      page2 = @site.create('t2')
      page2.store("* t2!
* t2!")

      res = session('/test/t1.html')
      ok_in(['t1'], 'title')
      ok_in(["t2!"], "//div[@class='day']/h2")

      config = @site['_SiteConfig']
      config.store(':titlelink:true')
      res = session('/test/t1.html')
      ok_in([[:a, {:href=>"t2.html#6b9e49fa28900683969f489ac35161e6",
		  :name=>'6b9e49fa28900683969f489ac35161e6',
		  :class=>'label'}, "■"], "t2!"],
	    "//div[@class='day']/h2")
    end
  end
end
