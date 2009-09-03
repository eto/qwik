# -*- coding: shift_jis -*-
# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/act-monitor'
#require 'qwik/act-rrefs'
require 'qwik/page-title'

module Qwik
  class Action
    def act_new
      c_require_login

      # Check if the title is specified.
      title = @req.query['t']
      return new_input_title if title.nil? || title.empty?

      # Parse page title.
      page_title, tags = Page.parse_title(title)

      # Check if the page title is here.
      return new_input_title if page_title.nil? || page_title.empty?

      # Check if the title is already exist.
      page = @site.get_by_title(page_title)
      return new_already_exist(page_title, page.key) if page

      # Check if the request is GET.
      return new_confirm(title) if ! @req.is_post?

      if Page.valid_as_pagekey?(page_title)
	key = page_title
      else
	key = @site.get_new_id
      end

      begin
	page = @site.create(key)	# CREATE
      rescue PageExistError
	# FIXME: should retry?
	return new_already_exist(page_title, key)
      end

      c_make_log('create', key)		# CREATE
      c_monitor("create#{key}")		# CREATE

      page.store("* #{title}\n")	# with tag

      url = "#{key}.edit"

#      create_rrefs(key)
      site_updated

      return c_notice(_('New page'), url, 201) {	# 201, Created
	[[:h2, _('Created.')],
	  [:p, [:a, {:href=>url}, _('Edit new page')]]]
      }
    end

    def new_input_title
      ar = []
      form = new_form
      return new_tail(ar, form)
    end

    def new_already_exist(title, key)
      ar = []
      ar << [:h2, _('Already exists')]
      form = new_form(title) {
	[:p, [:a, {:href=>key+'.html'}, [:strong, title]],
	  _(' already exists.'), [:br],
	  _('Please specify another title.')]
      }
      return new_tail(ar, form)
    end

    def new_confirm(title)
      ar = []
      ar << [:h2, _('Confirm')]
      form = new_form(title) {
	[:p, _('Push create.')]
      }
      return new_tail(ar, form)
    end

    def new_form(title=nil)
      form = [:form, {:action=>'.new', :method=>'POST'},
	[:dl, [:dt, _('Title')],
	  [:dd, [:input, {:name=>'t', :value=>title, :class=>'focus'}]]]]
      form << yield if block_given?
      form << [:p, [:input, {:type=>'submit', :value=>_("New page")}]]
    end

    def new_tail(ar, form)
      ar << [:div, {:class=>'form'}, form]
      ar << [:hr]
      ar << [:p, [:a, {:href=>"FrontPage.html"}, _("Go back")]]
      return c_notice(_('New page')) { ar }
    end

    def action_page_not_found
      # Assert that the title is encoded in UTF8.
      # @req.base.charset is already set to 'UTF-8' in request-path.rb
      title = @req.base.to_page_charset
      c_notfound(_('Page not found.')) {
	[[:h2, _('Page not found.')],
	  [:p, [:a, {:href=>'FrontPage.html'}, _('Go back')]],
	  [:hr],
	  new_form(title) {
	    [:p,  _('Push create if you would like to create the page.')]
	  }
	]
      }
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActNew < Test::Unit::TestCase
    include TestSession

    def test_create_new
      t_add_user

      # See .new page
      res = session('/test/.new')
      assert_attr({:action=>'.new', :method=>'POST'}, 'form')
      ok_xp([:input, {:value=>nil, :class=>'focus', :name=>'t'}], '//input')
      ok_xp([:input, {:value=>'New page', :type=>'submit'}], "//input[2]")

      # Create a new page.
      res = session("POST /test/.new?t=FirstPage")
      ok_title('New page')
      ok_in(['Edit new page'], "//div[@class='section']//a")
      ok_xp([:a, {:href=>'FirstPage.edit'}, 'Edit new page'],
	    "//div[@class='section']//a")
    end

    def test_with_tag
      t_add_user

      res = session("POST /test/.new?t=[tag] t")
      ok_xp([:a, {:href=>'t.edit'}, 'Edit new page'],
	    "//div[@class='section']//a")
      page = @site['t']
      ok_eq("* [tag] t\n", page.load)
    end

    def test_opensite_new
      t_add_user
      t_site_open	# OPEN site

      res = session('/test/') {|req|
	req.cookies.clear
      }
      ok_title('FrontPage')	# You can see the FrontPage.
      ok_in(['Login'], "//div[@class='adminmenu']//a")	# But, not logged in.

      # Try to see the .new page
      res = session('/test/.new') {|req|
	req.cookies.clear
      }
      ok_title('Please log in.') # You can't see the form.
      ok_in(['You need to log in to use this function.'], 'p')
    end
  end

  class TestActNewWithEmbed < Test::Unit::TestCase
    include TestSession

    def test_embeded_new
      t_add_user
      page = @site['FrontPage']
      page.store("[[FirstPage]]")

      # See FrontPage
      res = session('/test/')
      ok_title('FrontPage')
      ok_in([:span, {:class=>'new'}, 'FirstPage',
	      [:a, {:href=>".new?t=FirstPage"},
		[:img, {:src=>'.theme/i/new.png', :alt=>'create'}]]],
	    "//div[@class='section']/p")

      # To confirm
      res = session("/test/.new?t=FirstPage")
      ok_title('New page')
      ok_in(['New page'], 'h1')
      ok_in(['Confirm'], 'h2')
      assert_attr({:action=>'.new', :method=>'POST'}, 'form')
      ok_xp([:input, {:value=>'FirstPage', :class=>'focus', :name=>'t'}],
	    '//input')
      ok_xp([:input, {:value=>'New page', :type=>'submit'}],
	    "//input[2]")

      # Create a new page.
      res = session("POST /test/.new?t=FirstPage")
      ok_in(['Edit new page'], "//div[@class='section']//a")
      ok_xp([:a, {:href=>'FirstPage.edit'}, 'Edit new page'],
	    "//div[@class='section']//a")

      # Check the new page
      ok_eq("* FirstPage\n", @site['FirstPage'].load)

      # Try to create with the same key.
      res = session("/test/.new?t=FirstPage")
      ok_in(['Already exists'], '//h2')
      ok_xp([:a, {:href=>'FirstPage.html'}, [:strong, 'FirstPage']],
	    "//div[@class='section']/a")

      # Try to create with the same key.
      res = session("POST /test/.new?t=FirstPage")
      ok_in(['Already exists'], '//h2')
      ok_xp([:a, {:href=>'FirstPage.html'}, [:strong, 'FirstPage']],
	    "//div[@class='section']/a")
    end

    def test_embeded_new_with_space
      t_add_user
      page = @site['FrontPage']
      page.store("[[First Page]]")
      ok_eq('FrontPage', page.get_title)

      # see a page
      res = session('/test/')
      ok_in(['First Page', [:a, {:href=>".new?t=First+Page"},
		[:img, {:src=>'.theme/i/new.png', :alt=>'create'}]]],
	    "//span[@class='new']")

      # Please input corresponding page key
      res = session("/test/.new?t=First+Page")
      ok_in(['New page'], 'h1')
      ok_in(['Confirm'], 'h2')
      assert_attr({:action=>'.new', :method=>'POST'}, 'form')
      ok_xp([:input, {:value=>'First Page',
		:class=>'focus', :name=>'t'}], '//input')
      ok_xp([:input, {:value=>'New page', :type=>'submit'}], "//input[2]")

      # POST
      res = session("POST /test/.new?t=First Page")
      ok_in(['New page'], 'h1')
      ok_in(['Edit new page'], "//div[@class='section']//a")
      ok_xp([:a, {:href=>'1.edit'}, 'Edit new page'],
	    "//div[@class='section']//a")

      # check the new page
      ok_eq("* First Page\n", @site['1'].load)
      page = @site.get_by_title('First Page')
      ok_eq('1', page.key)

      # check title
      page = @site['1']
      ok_eq('First Page', page.get_title)
      ok_eq('1', @site.get_by_title('First Page').key.to_s)
      ok_eq(false, @site.exist?('First Page'))
      ok_eq(true, @site.exist?('1'))

      # check the source page
      res = session('/test/')
      ok_in(['First Page'], "//div[@class='section']//a")
      ok_xp([:a, {:href=>'1.html'}, 'First Page'],
	    "//div[@class='section']//a")
      ok_eq("[[First Page]]", @site['FrontPage'].load)

      # Try to create with the same key.
      res = session("/test/.new?t=First+Page")
      ok_in(['Already exists'], '//h2')
      ok_xp([:a, {:href=>'1.html'}, [:strong, 'First Page']],
	    "//div[@class='section']/a")

      # Try to create with the same key.
      res = session("POST /test/.new?t=First+Page")
      ok_in(['Already exists'], '//h2')
      ok_xp([:a, {:href=>'1.html'}, [:strong, 'First Page']],
	    "//div[@class='section']/a")

      # Let's create a page again.  At the first, embed the title.
      page = @site['FrontPage']
      page.store("[[2nd Page]]")

      # See the page
      res = session('/test/')
      ok_in(['2nd Page', [:a, {:href=>".new?t=2nd+Page"},
		[:img, {:src=>'.theme/i/new.png', :alt=>'create'}]]],
	    "//div[@class='section']//span")

      # please input a corresponding page key
      res = session("/test/.new?t=2nd+Page")
      ok_xp([:input, {:value=>'2nd Page', :class=>'focus', :name=>'t'}],
	    '//input')

      # try again
      res = session("POST /test/.new?t=2nd+Page")
      ok_in(['Edit new page'], "//div[@class='section']//a")
      ok_xp([:a, {:href=>'2.edit'}, 'Edit new page'],
	    "//div[@class='section']//a")

      page = @site['2']
      ok_eq("* 2nd Page\n", page.load)

      # check the source page again
      res = session('/test/')
      ok_in(['2nd Page'], "//div[@class='section']//a")
      ok_xp([:a, {:href=>'2.html'}, '2nd Page'],
	    "//div[@class='section']//a")
      ok_eq("[[2nd Page]]", @site['FrontPage'].load)
    end

    def test_new_sjis
      t_add_user
      page = @site['FrontPage']
      page.store("[[ポス]]")

      # See FrontPage
      res = session('/test/')
      ok_title('FrontPage')
      ok_in([:span, {:class=>'new'}, "ポス",
	      [:a, {:href=>".new?t=%83%7C%83X"},
		[:img, {:src=>'.theme/i/new.png', :alt=>'create'}]]],
	    "//div[@class='section']/p")
    end

    def test_embeded_new_with_japanese_name
      t_add_user

      page = @site['FrontPage']
      page.store("[[最初のページ]]")
      ok_eq('FrontPage', page.get_title)

      # See a page
      res = session('/test/')
      ok_in(["最初のページ",
	      [:a, {:href=>".new?t=%8D%C5%8F%89%82%CC%83y%81%5B%83W"},
		[:img, {:src=>'.theme/i/new.png', :alt=>'create'}]]],
	    "//span[@class='new']")

      # Please input corresponding page key
      res = session("/test/.new?t=最初のページ")
      ok_in(['New page'], 'h1')
      ok_in(['Confirm'], 'h2')
      assert_attr({:action=>'.new', :method=>'POST'}, 'form')
      ok_xp([:input, {:value=>"最初のページ",
		:class=>'focus', :name=>'t'}], '//input')
      ok_xp([:input, {:value=>'New page', :type=>'submit'}],
	    "//input[2]")

      # POST
      res = session("POST /test/.new?t=最初のページ")
      ok_in(['New page'], 'h1')
      ok_in(['Edit new page'], "//div[@class='section']//a")
      ok_xp([:a, {:href=>'1.edit'}, 'Edit new page'],
	    "//div[@class='section']//a")

      # Check the new page.
      ok_eq("* 最初のページ\n", @site['1'].load)
      page = @site.get_by_title("最初のページ")
      ok_eq('1', page.key)

      # Check title.
      page = @site['1']
      ok_eq("最初のページ", page.get_title)
      ok_eq('1', @site.get_by_title("最初のページ").key.to_s)
      ok_eq(false, @site.exist?("最初のページ"))
      ok_eq(true, @site.exist?('1'))

      # Check the source page.
      res = session('/test/')
      ok_in(["最初のページ"], "//div[@class='section']//a")
      ok_xp([:a, {:href=>'1.html'}, "最初のページ"],
	    "//div[@class='section']//a")
      ok_eq("[[最初のページ]]", @site['FrontPage'].load)

      # Try to create with the same key.
      res = session("/test/.new?t=最初のページ")

      # Try to create with the same key.
      res = session("POST /test/.new?t=最初のページ")
      ok_in(['Already exists'], '//h2')

      # Let's create a page again.  At the first, embed the title.
      page = @site['FrontPage']
      page.store("[[二頁]]")

      # See the page
      res = session('/test/')
      ok_in(["二頁",
	      [:a, {:href=>".new?t=%93%F1%95%C5"},
		[:img, {:src=>'.theme/i/new.png', :alt=>'create'}]]],
	    "//div[@class='section']//span")

      # please input a corresponding page key
      res = session("/test/.new?t=二頁")
      ok_xp([:input, {:value=>"二頁", :class=>'focus', :name=>'t'}], '//input')

      # try again
      res = session("POST /test/.new?t=二頁")
      ok_in(['Edit new page'], "//div[@class='section']//a")
      ok_xp([:a, {:href=>'2.edit'}, 'Edit new page'],
	    "//div[@class='section']//a")

      page = @site['2']
      ok_eq("* 二頁\n", page.load)

      # check the source page again
      res = session('/test/')
      ok_in(["二頁"], "//div[@class='section']//a")
      ok_xp([:a, {:href=>'2.html'}, "二頁"],
	    "//div[@class='section']//a")
      ok_eq("[[二頁]]", @site['FrontPage'].load)
    end
  end
end
