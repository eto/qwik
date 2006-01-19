#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '..' unless $LOAD_PATH.include?('..')
require 'qwik/site-search'

module Qwik
  class Action
    D_search = {
      :dt => 'Search plugin',
      :dd => 'You can show a search form.',
      :dc => "* Example
 {{search}}
{{search}}
" }

    def plg_search_form(focus=false)
      return search_form(focus)
    end
    alias plg_search plg_search_form

    def search_form(focus=false)
      query_attr = {:name=>'q'}
      query_attr[:class] = 'focus' if focus
      return [:form, {:action=>'.search'},
	[:input, query_attr],
	[:input, {:type=>'submit', :value=>_('Search')}]]
    end

    def act_search
      query = @req.query['q']
      if query.nil? || query.empty?
	return search_form_page
      end

      ar = @site.search(query)
      if ar.empty?
	return search_notfound_page
      end

      return search_result(@site, ar)
    end

    def search_form_page(title=_('Search'), notice=nil)
      body = []
      body << [:h2, notice] if notice
      body << [:div, {:class=>'form'}, search_form(true)]
      return c_notice(title) { body }
    end

    def search_notfound_page
      return search_form_page(_('Search result'), _('No match.'))
    end

    def search_result(site, ar)
      ul = [:ul]
      ar.each {|key, line, i|
	page = site[key]
	url = page.url
	ul << [:li,
	  [:a, {:href=>url}, page.get_title], ' : ',
	  [:em, {:class=>'linenum'}, i.to_s], ' : ',
	  [:span, {:class=>'content'}, line]]
      }
      div = [:div, {:class=>'day'},
	[:div, {:class=>'section'},
	  [:div, {:class=>'search_result'}, ul]]]
      title = _('Search result')
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
		[:a, {:href=>'1.html'}, '1'], ' : ',
		[:em, {:class=>'linenum'}, '0'], ' : ',
		[:span, {:class=>'content'}, 'This is a keyword.']]],
	    "//div[@class='search_result']")

      page = @site.create_new	# 2.txt
      page.store("Š¿Žš")
      res = session("/test/.search?q=Žš")
      ok_in([:ul, [:li,
		[:a, {:href=>'2.html'}, '2'], ' : ',
		[:em, {:class=>'linenum'}, '0'], ' : ',
		[:span, {:class=>'content'}, "Š¿Žš"]]],
	    "//div[@class='search_result']")
    end
  end
end
