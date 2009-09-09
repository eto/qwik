# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/site-search'
require 'qwik/site-index'

module Qwik
  class Action
    D_PluginSearch = {
      :dt => 'Search plugin',
      :dd => 'You can show a search form.',
      :dc => '* Example
 {{search}}
{{search}}
'
    }

    D_PluginSearch_ja = {
      :dt => '検索プラグイン',
      :dd => '検索窓を作れます。',
      :dc => '* 例
 {{search}}
{{search}}
'
    }

    # ============================== search
    def plg_side_search_form
      return [
	[:h2, _('Search')],
	plg_search_form,
#	plg_search_word_cloud
      ]
    end

    def plg_search_form(focus = false)
      return search_form(focus)
    end
    alias plg_search plg_search_form

    def search_form(focus = false, query = nil)
      query_attr = {:name=>'q'}
      query_attr[:class] = 'focus' if focus
      query_attr[:value] = query if query
      return [:form, {:action=>'.search'},
	[:input, query_attr],
	[:input, {:type=>'submit', :value=>_('Search')}]]
    end

    def act_search
      query = search_get_query
      if query.nil?
	return search_form_page
      end

      ar = @site.search(query)
      if ar.empty?
	return search_notfound_page(query)
      end

      return search_result(@site, ar, query)
    end
    alias ext_search act_search

    def search_get_query
      query = @req.query['q']
      return query if query && ! query.empty?

      query = @req.base
      return query if query && ! query.empty? && query != "FrontPage"
      #return query if query && ! query.empty?

      return nil
    end

    def search_form_page(title = _('Search'), notice = nil, query = nil)
      body = []
      body << [:h2, notice] if notice
      body << [:div, {:class => 'form'}, search_form(true, query)]
      return c_notice(title) { body }
    end

    # called also from act-isearch.rb
    def search_notfound_page(query)
      return search_form_page(_('Search result'), _('No match.'), query)
    end

    def search_result(site, ar, query = nil)
      ul = [:ul]
      ar.each {|key, line, i|
	page = site[key]
	url = page.url
	ul << [:li,
	  [:h3, [:a, {:href => url}, page.get_title]], 
	  [:span, {:class => 'content'}, line],
	  [:div, [:a, {:href => url}, url]]]
      }
      div = []
      div << [:div, {:class => 'day'},
	[:div, {:class => 'section'},
          [:div, {:class=>'form'}, search_form(true, query)]]]
      div << [:div, {:class => 'day'},
	[:div, {:class => 'section'},
	  [:div, {:class => 'search_result'}, ul]]]
      title = _('Search result') + ": " + query
      return c_plain(title) { div }
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActSearch < Test::Unit::TestCase
    include TestSession

    def test_plg_search_form
      ok_wi([:form, {:action=>'.search'},
	      [:input, {:name=>'q'}],
	      [:input, {:value=>'Search', :type=>'submit'}]],
	    "{{search_form}}")
      ok_wi([:form, {:action=>'.search'},
	      [:input, {:name=>'q', :class=>'focus'}],
	      [:input, {:value=>'Search', :type=>'submit'}]],
	    "{{search_form(true)}}")
    end

    def test_search
      t_add_user

      # test_act_search
      res = session('/test/.search')
      ok_xp([:form, {:action=>'.search'},
	      [:input, {:class=>'focus', :name=>'q'}],
	      [:input, {:value=>'Search', :type=>'submit'}]],
	    '//form')

      res = session("/test/.search?q=nosuchkey")
      assert_text('Search result', 'h1')
      ok_in(['No match.'], '//h2')

      page = @site.create_new
      page.store('This is a keyword.')
      res = session("/test/.search?q=keyword")
      ok_in([:ul, [:li,
		[:h3, [:a, {:href=>'1.html'}, '1']], 
		[:span, {:class=>'content'}, 'This is a keyword.'],
		[:div, [:a, {:href=>'1.html'},"1.html"]]]],
	    "//div[@class='search_result']")

      res = session("/test/keyword.search")	# Both OK.
      ok_in([:ul, [:li,
		[:h3, [:a, {:href=>'1.html'}, '1']],
		[:span, {:class=>'content'}, 'This is a keyword.'],
		[:div, [:a, {:href => '1.html'},"1.html"]]]],
	    "//div[@class='search_result']")

      page = @site.create_new	# 2.txt
      page.store("漢字")
      res = session("/test/.search?q=字")
      ok_in([:ul, [:li,
		[:h3, [:a, {:href=>'2.html'}, '2']], 
		[:span, {:class=>'content'}, "漢字"],
		[:div, [:a, {:href=>'2.html'}, '2.html']]]],
	    "//div[@class='search_result']")

      res = session("/test/字.search")		# Both OK.
      ok_in([:ul, [:li,
		[:h3, [:a, {:href=>'2.html'}, '2']],
		[:span, {:class=>'content'}, "漢字"],
		[:div, [:a, {:href=>'2.html'}, '2.html']]]],
	    "//div[@class='search_result']")
    end
  end
end
