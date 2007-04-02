# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/parser-emode'
require 'qwik/act-include'

module Qwik
  class Action
    def plg_emode_date_link
      years = []
      months = {}

      emode_each_month {|y, m|
	years << y unless years.include?(y)
	months[y] = [] if months[y].nil?
	months[y] << m
      }

      list = [:ul]
      years.each {|y|
	ar = [:li]
	ar << "20#{y} "
	months[y].each {|m|
	  ar << [:a, {:href=>y+m+'.html'}, m]
	  ar << ' '
	}
	ar.pop
	list << ar
      }

      return [:div, list]
    end

    def plg_emode_include_recent
      max = 0
      emode_each_month {|y, m|
	ym = (y+m).to_i
	max = ym if max < ym
      }
      str = sprintf('%04d', max)
      return plg_include(str)
    end

    def emode_each_month
      @site.to_a.sort.each {|page|
	title = page.key
	if /\A(\d\d)([0-1]\d)\z/ =~ title
	  y = $1
	  m = $2
	  yield(y, m)
	end
      }
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActEmode < Test::Unit::TestCase
    include TestSession

    def test_emode_date_link
      page = @site.create('0002')
      page = @site.create('0003')
      page = @site.create('0101')
      page = @site.create('0110')
      ok_wi([:div, [:ul,
		[:li, '2000 ',
		  [:a, {:href=>'0002.html'}, '02'], ' ',
		  [:a, {:href=>'0003.html'}, '03']],
		[:li, '2001 ',
		  [:a, {:href=>'0101.html'}, '01'], ' ',
		  [:a, {:href=>'0110.html'}, '10']]]],
	    '{{emode_date_link}}')
    end

    def test_emode_include_recent
      page = @site.create('0002')
      page = @site.create('0003')
      page = @site.create('0101')
      page = @site.create('0110')
      page.store('01/10')
      ok_wi([:div, {:class=>'day'}, '',
	      [:div, {:class=>'body'},
		[:div, {:class=>'section'},
		  [[:p, '01/10']]]]],
	    '{{emode_include_recent}}')
    end

    def ok(e, w, user=DEFAULT_USER)	# assert_body_main
      assert_path(e, w, user, "//div[@class='body_main']")
    end

    def test_emode_include
      page = @site.create_new
      page.store("* t
* t")
      page2 = @site.create_new
      page2.store("* t2
* t2")
      key = page2.key

      config = @site['_SiteConfig']
      config.store(':emode_titlelink:true')
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
		       "Å°"],
		     't2'],
		   [:div, {:class=>'body'},
		     [:div, {:class=>'section'}, []]]]]]]],
	 "{{include(#{key})}}")

      config.store('')
    end

    def test_emode_include_with_titlelink
      t_add_user

      page = @site.create('t1')
      page.store("* t1
{{include(t2)}}")
      page2 = @site.create('t2')
      page2.store("* t2!
* t2!")

      config = @site['_SiteConfig']
      config.store(':emode_titlelink:true')
      res = session('/test/t1.html')
      ok_in([[:a, {:href=>"t2.html#Xb_M6_lBLMaGGH88jpd-rQ",
		  :name=>'Xb_M6_lBLMaGGH88jpd-rQ',
		  :class=>'label'}, "Å°"], "t2!"],
	    "//div[@class='day']/h2")
    end
  end
end
