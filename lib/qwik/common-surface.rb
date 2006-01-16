#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '../../lib' unless $LOAD_PATH.include?('../../lib')
require 'qwik/act-adminmenu'
require 'qwik/wabisabi-index'

module Qwik
  class Action
    # ==================== c_surface
    # http://co/qwik/.test_surface
    # Only for page design check.
    def act_test_surface
      w = c_page_res('TextFormat')
      c_surface('act_test_surface') { w }
    end

    def c_surface(title, patch=true, &b)
      msg = yield
      c_set_status
      c_set_contenttype
      c_set_no_cache
      body = surface_generate(title, msg, patch)
      c_set_body(body)
    end

    def surface_generate(title, msg, patch=true)
      template = @memory.template.get('surface')
      data = {}
      data['title'] = title
      data['theme_path'] = @site.theme_path
      data['adminmenu'] = c_page_res('_AdminMenu')
      if patch
	li = data['adminmenu'].get_path('//ul/li[2]')
	li.clear if li
      end
      data['toc'] = nil		# Do not use toc.
      data['h1'] = title	# same as title.
      data['body'] = msg
      data['sidemenu'] = surface_get_sidemenu
      data['pageattribute'] = c_page_res('_PageAttribute')
      surface_template(template, data)
      return template
    end

    # ==================== view page
    # Called from act-html.rb:28, 57
    def surface_view(pagename)
      c_set_status
      c_set_contenttype
      c_set_no_cache
      body = surface_view_generate(pagename)
      c_set_body(body)
    end

    def surface_view_generate(pagename)
      page = @site[pagename]
      template = @memory.template.get('surface')
      data = {}
      data['title'] = @site.get_page_title(pagename)
      data['theme_path'] = @site.theme_path
      data['adminmenu'] = c_page_res('_AdminMenu')
      data['toc'] = toc_inside
      data['h1'] = page.get_title
      data['body'] = surface_get_body(page)
      data['sidemenu'] = surface_get_sidemenu
      data['pageattribute'] = c_page_res('_PageAttribute')
      surface_template(template, data)
      return template
    end

    # act-include:22, act-tag:49
    def surface_get_body(page)
      tree = page.get_body_tree
      w = Resolver.resolve(@site, self, tree)
      w = TDiaryResolver.resolve(@config, @site, self, w)
      return w
    end

    private

    def surface_get_sidemenu
      page = @site.get_superpage('SideMenu')
      tree = page.get_tree
      w = Resolver.resolve(@site, self, tree)
      return w
    end

    # ==================== build using template
    # Destructive for template.
    def old_surface_template(template, data)
      w = template.get_tag('head')	# TAKETIME: Here!
      w.insert(1, [:title, data['title']])
      media = 'screen,tv,print'
      w.insert(w.length, [:link, {:href=>'.theme/css/base.css', :media=>media,
		   :rel=>'stylesheet', :type=>'text/css'}])
      w.insert(w.length, [:link, {:href=>data['theme_path'], :media=>media,
		   :rel=>'stylesheet', :type=>'text/css'}])
      js = Action.generate_js
      w.insert(w.length, *js)

      w = template.get_by_class('adminmenu')	# TAKETIME: Here!
      w << data['adminmenu']

      w = template.get_by_class('toc')	# TAKETIME: Here!
      if data['toc'].nil?
	w.clear
      else
	w << data['toc']
      end

      w = template.get_tag('h1')	# TAKETIME: Here!
      w << data['h1']

      w = template.get_by_class('body_enter')	# TAKETIME: Here!
      w.clear

      w = template.get_by_class('body_main')	# TAKETIME: Here!
      w << data['body']

      w = template.get_by_class('sidebar')	# TAKETIME: Here!
      w << data['sidemenu']

      w = template.get_by_class('body_leave')	# TAKETIME: Here!
      w << [:div, {:class=>'day'},
	[:div, {:class=>'comment'},
	  [:div, {:class=>'caption'},
	    [:div, {:class=>'page_attribute'},
	      data['pageattribute']]]]]

      nil	# This method just destruct the template.
    end

    def new_surface_template(template, data)
      template.make_index

      w = template.index_tag(:head)
      w.insert(1, [:title, data['title']])
      media = 'screen,tv,print'
      w.insert(w.length, [:link, {:href=>'.theme/css/base.css', :media=>media,
		   :rel=>'stylesheet', :type=>'text/css'}])
      w.insert(w.length, [:link, {:href=>data['theme_path'], :media=>media,
		   :rel=>'stylesheet', :type=>'text/css'}])
      js = Action.generate_js
      w.insert(w.length, *js)

      w = template.index_class('adminmenu')
      w << data['adminmenu']

      w = template.index_class('toc')
      if data['toc'].nil?
	w.clear
      else
	w << data['toc']
      end

      w = template.index_tag(:h1)
      w << data['h1']

      w = template.index_class('body_enter')
      w.clear

      w = template.index_class('body_main')
      w << data['body']

      w = template.index_class('sidebar')
      w << data['sidemenu']

      w = template.index_class('body_leave')
      w << [:div, {:class=>'day'},
	[:div, {:class=>'comment'},
	  [:div, {:class=>'caption'},
	    [:div, {:class=>'page_attribute'},
	      data['pageattribute']]]]]

      return nil	# Just destruct the template.
    end

   #alias surface_template old_surface_template
    alias surface_template new_surface_template

  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  require 'qwik/test-module-public'

  class TestActSurface < Test::Unit::TestCase
    include TestSession
    include TestModulePublic

    def test_test_surface
      t_add_user
      res = session('/test/.test_surface')
      ok_xp([:title, 'act_test_surface'], 'title', res)
    end

    def test_all
      res = session

#      @action.generate_surface_page('title', 'msg')
#      ok_xp([:title, 'title'], 'title', res)

      @action.c_surface('c_surface title') { 'msg' }
      ok_xp([:title, 'c_surface title'], 'title', res)
    end

    def test_surface_generate
      res = session

      # test_original_template
      template = @memory.template.get('surface')
      ok_eq([:h1], template.get_tag('h1'))
      ok_eq([:div, {:class=>'body_main'}],
	    template.get_by_class('body_main'))

      # test_surface_generate
      res = @action.surface_generate('title', 'msg')
      ok_eq([:title, 'title'], res.get_tag('title'))
#      ok_eq([:script, {:src=>'.theme/js/base.js',
#		:type=>'text/javascript'}, ''], res.get_tag('script'))
      ok_eq([:h1, 'title'], res.get_tag('h1'))
      ok_eq([:div, {:class=>'body_main'}, 'msg'],
	    res.get_path("//div[@class='body_main']"))
    end

    def test_surface_build_template
      res = session
      t_make_public(Qwik::Action, :surface_template)
      template = @memory.template.get('surface')
      data = {}
      data['title'] = 'title'
      data['theme_path'] = 'theme_path'
      data['adminmenu'] = 'adminmenu'
      data['toc'] = 'toc'
      data['h1'] = 'h1'
      data['body'] = 'body'
      data['sidemenu'] = 'sidemenu'
      data['pageattribute'] = 'pageattribute'
      @action.surface_template(template, data)
      res.body = template
      ok_xp([:title, 'title'], 'title', res)
      ok_xp([:div, {:class=>'sidebar'}, 'sidemenu'],
	    "//div[@class='sidebar']")
    end
  end
end
