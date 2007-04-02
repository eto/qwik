#
# Copyright (C) 2003-2006 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/wabisabi-template'

module Qwik
  class Site
    # Make index before call this method.  Use parent.
    def resolve_all_ref(wabisabi)
      wabisabi.index_each_tag(:a) {|e|
	resolve_ref(e)
      }
      return wabisabi
    end

    def resolve_ref(w)
      attr = w.attr
      return w if attr.nil?

      href = attr[:href]
      return w if href.nil? || href.empty?

      # External link.
      if /^(?:http|https|ftp|file):\/\// =~ href
	w.set_attr(:class=>'external')

	# Make it redirect link.
	if self.siteconfig['redirect'] == 'true'
	  w.set_attr(:href=>".redirect?url=#{href}")
	end
	
	return w
      end

      # Error check.
      return w if href.include?('?')	# ignore command link
      return w if href[0] == ?/	# already resolved
      return w if /\.html\z/ !~ href	# ignore not html file

      linkbase = href.sub(/\.html\z/, '')
      text = w[2]

      t = linkbase
      page = self.get_by_title(t)
      if page && page.key != t
	w.set_attr(:href=>page.key+'.html')
	return w
      end

      # Create a new page link.
      if ! self.exist?(linkbase)
	newlinkbase = linkbase.escape
	edithref = ".new?t=#{newlinkbase}"

	return [:span, {:class=>'new'}, text,
	  [:a, {:href=>edithref},
	    [:img, {:src=>'.theme/i/new.png', :alt=>'create'}]]]

      end

      # Rewrite inside to the page title.
      if linkbase == text
	t = self[linkbase].get_title
	return w if t == linkbase
	w[2] = t
	return w
      end

      return w
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestSiteResolve < Test::Unit::TestCase
    include TestSession

    def ok(e, w)
      ok_eq(e, @site.resolve_ref(w))
    end

    def test_all
      res = session

      ok([:a], [:a])
      ok([:a, {:href=>''}, 't'], [:a, {:href=>''}, 't'])

      # test_external
      ok([:a, {:href=>'http://e/', :class=>'external'}, 't'],
	 [:a, {:href=>'http://e/'}, 't'])

      # test_redirect
      page = @site['_SiteConfig']
      page.store(':redirect:true')
      ok([:a, {:href=>'.redirect?url=http://e/', :class=>'external'}, 't'],
	 [:a, {:href=>'http://e/'}, 't'])
      page.store('')

      ok([:a, {:href=>'a?b'}, 't'],
	 [:a, {:href=>'a?b'}, 't'])
      ok([:a, {:href=>'/t'}, 't'],
	 [:a, {:href=>'/t'}, 't'])
      ok([:a, {:href=>'t'}, 't'],
	 [:a, {:href=>'t'}, 't'])

      # test_new
      ok([:span, {:class=>'new'}, 't',
	   [:a, {:href=>'.new?t=t'},
	     [:img, {:alt=>'create', :src=>'.theme/i/new.png'}]]],
	 [:a, {:href=>'t.html'}, 't'])

      page = @site.create('t')
      ok([:a, {:href=>'t.html'}, 't'], [:a, {:href=>'t.html'}, 't'])
      page = @site.create_new
      page.store('t')
      ok([:a, {:href=>'1.html'}, '1'], [:a, {:href=>'1.html'}, '1'])
      ok([:a, {:href=>'1.html'}, 't'], [:a, {:href=>'1.html'}, 't'])
      page.store('*t')
      ok([:a, {:href=>'1.html'}, 't'], [:a, {:href=>'1.html'}, '1'])
      ok([:a, {:href=>'1.html'}, 't'], [:a, {:href=>'1.html'}, 't'])
      ok([:a, {:href=>'1.html'}, 's'], [:a, {:href=>'1.html'}, 's'])

      # test_error
      ok([:a, {:href=>"\"D_R\", \"/v/w\""}, 't'],
	 [:a, {:href=>"\"D_R\", \"/v/w\""}, 't'])

      # test_act
      ok([:a, {:href=>'.attach'}, '.attach'],
	 [:a, {:href=>'.attach'}, '.attach'])

      # test_plusplus
      ok([:a, {:href=>'t.html'}, 't'],
	 [:a, {:href=>'t.html'}, 't'])
      ok([:span, {:class=>'new'}, 'C++',
	   [:a, {:href=>'.new?t=C%2B%2B'},
	     [:img, {:alt=>'create', :src=>'.theme/i/new.png'}]]],
	 [:a, {:href=>'C++.html'}, 'C++'])
      page.store('* C++')
      ok([:a, {:href=>'1.html'}, 'C++'],
	 [:a, {:href=>'C++.html'}, 'C++'])
    end

    def test_japanese
      res = session
      page = @site.create_new
      page.store('*‚ ')

      ok([:a, {:href=>'1.html'}, '‚ '],
	 [:a, {:href=>'‚ .html'}, '‚ '])
      
      ok([:span, {:class=>'new'}, '‚¢',
	   [:a, {:href=>'.new?t=%82%A2'},
	     [:img, {:alt=>'create', :src=>'.theme/i/new.png'}]]],
	 [:a, {:href=>'‚¢.html'}, '‚¢'])
    end
  end

  class TestSiteResolveAll < Test::Unit::TestCase
    include TestSession

    def ok_all(e, w)
      ok_eq(e, @site.resolve_all_ref(w))
    end

    def test_all
      res = session
      # test_ref
      ok_all([[:span, {:class=>'new'}, 't',
		 [:a, {:href=>'.new?t=t'},
		   [:img, {:alt=>'create', :src=>'.theme/i/new.png'}]]]],
	     [[:a, {:href=>'t.html'}, 't']])
      page = @site.create('t')
      ok_all([[:a, {:href=>'t.html'}, 't']],
	     [[:a, {:href=>'t.html'}, 't']])
      page = @site.create_new
      page.store('t')
      ok_all([[:a, {:href=>'1.html'}, '1']],
	     [[:a, {:href=>'1.html'}, '1']])
      page.store('*t')
      ok_all([[:a, {:href=>'1.html'}, 't']],
	     [[:a, {:href=>'1.html'}, '1']])
      ok_all([[:a, {:href=>'.attach'}, '.attach']],
	     [[:a, {:href=>'.attach'}, '.attach']])
    end

    def test_all1
      res = session

      # test_newpage
      ok_wi([:p, [:span, {:class=>'new'}, 'test',
		[:a, {:href=>'.new?t=test'},
		  [:img, {:alt=>'create', :src=>'.theme/i/new.png'}]]]],
	    '[[test]]')
      ok_wi([:p, [:span, {:class=>'new'}, '‚¢',
		[:a, {:href=>'.new?t=%82%A2'},
		  [:img, {:alt=>'create', :src=>'.theme/i/new.png'}]]]],
	    '[[‚¢]]')
    end

    def test_all2
      res = session

      # test_act
      ok_wi([:p, 't', [:a, {:href=>'.attach'}, '.attach']],
	    't[[.attach]]')
      ok_wi([:p, [:a, {:href=>'.attach'}, '.attach']], '[[.attach]]')
      ok_wi([:p, [:a, {:href=>'.attach'}, 'FileAttach']],
	    '[[FileAttach|.attach]]')
      ok_wi([:p, [:a, {:href=>'.attach'}, 'ƒtƒ@ƒCƒ‹“Y•t']],
	    '[[ƒtƒ@ƒCƒ‹“Y•t|.attach]]')

      # test_mojibake
      ok_wi([:p, 't'], 't')
      ok_wi([:p, '450‰~'], '450‰~')
    end

  end
end
