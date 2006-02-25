$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'
require 'qwik/site-index'
require 'qwik/act-search'

module Qwik
  class Action
    def plg_isearch(focus=false)
      form = search_form(focus)
      form[1][:action] = '.isearch'
      return form
    end

    def act_isearch
      query = @req.query['q']
      if query.nil? || query.empty?
	search_form_page
	isearch_patch(@res.body)
	return
      end

      ar = @site.isearch(query)
      if ar.nil? || ar.empty?
	search_notfound_page(query)
	isearch_patch(@res.body)
	return
      end

      return isearch_result(@site, ar)
    end

    def isearch_patch(body)	# Destructive for the body
      form = body.get_path('//form')
      form[1][:action] = '.isearch'
    end

    def isearch_result(site, ar)
      ul = [:ul]
      ar.each {|key|
	page = site[key]
	url = page.url
	ul << [:li, [:a, {:href=>url}, key]]
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
  class TestActISearch < Test::Unit::TestCase
    include TestSession

    def test_plg_isearch
      ok_wi([:form, {:action=>'.isearch'},
	      [:input, {:name=>'q'}],
	      [:input, {:value=>'Search', :type=>'submit'}]],
	    "{{isearch}}")
    end

    def test_act_isearch
      t_add_user

      res = session '/test/.isearch'
      ok_xp [:form, {:action=>'.isearch'},
	      [:input, {:class=>'focus', :name=>'q'}],
	      [:input, {:value=>'Search', :type=>'submit'}]],
	    '//form'

      res = session "/test/.isearch?q=nosuchkey"
      assert_text 'Search result', 'h1'
      ok_in ['No match.'], '//h2'

      page = @site.create_new
      page.store 'This is a keyword.'
      res = session "/test/.isearch?q=keyword"
#      ok_in [:ul, [:li, [:a, {:href=>'1.html'}, '1']]],
#	    "//div[@class='search_result']"

      page = @site.create_new	# 2.txt
      page.store "Š¿Žš"
      res = session "/test/.isearch?q=Žš"
#      ok_in [:ul, [:li, [:a, {:href=>'2.html'}, '2']]],
#	    "//div[@class='search_result']"
    end
  end
end
