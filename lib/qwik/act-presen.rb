# -*- coding: shift_jis -*-
# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    D_ExtPresen = {
      :dt => 'Presentaion mode',
      :dd => 'You can show the page in presentation mode.',
      :dc => "* How to
 [[FrontPage.presen]]
[[FrontPage.presen]]
Follow this link and you'll see the presen mode of the FrontPage.
 {{presen}}
You can show a link to presentation mode.
** Specify Presentation theme
 {{presen_theme(qwikblack)}}
You can specify the presentation theme by this plugin.
{{presen_theme_list}}
You can choose from this list.
* Thanks
I use
[[S5: A Simple Standards-Based Slide Show System|http://www.meyerweb.com/eric/tools/s5/]]
by Mr. Eric Meyer for this presentation mode.  Thank you very much.
"
    }

    D_ExtPresen_ja = {
      :dt => 'プレゼン・モード',
      :dd => 'プレゼン・モードで表示します。',
      :dc => '* 使い方
 [[FrontPage.presen]]
[[FrontPage.presen]]
このリンクをたどると、FrontPageをプレゼン・モードで表示します。
 {{presen}}
あるページをプレゼン・モードにするリンクを表示したい場合は、
このプラグインをご利用下さい。
** プレゼンテーマ指定
 {{presen_theme(qwikblack)}}
このようにして、プレゼンテーマを指定できます。
{{presen_theme_list}}
この一覧の中から選べます。
* 感謝
プレゼン・モードには、Eric Meyer氏による
[[S5: A Simple Standards-Based Slide Show System|http://www.meyerweb.com/eric/tools/s5/]]
を使わせていただいております。どうもありがとうございます。
'
    }

    def plg_presen_switch
      return nil if ! defined?(@req.base) || @req.base.nil?
      return plg_ext('presen', _('Present')) if /^Presen/ =~ @req.base
      return nil
    end

    def plg_presen
      return nil if ! defined?(@req.base) || @req.base.nil?
      return page_attribute('presen', _('Presentation mode'))
    end
    alias plg_show_presen plg_presen	# FIXME: Make this obsolete.

    def plg_presen_theme(theme)
      return	# Do nothing.
    end

    def plg_presen_theme_list
      return [:ul, *presen_theme_list.map {|t| [:li, t] }]
    end

    PRESEN_THEME_IGNORE_DIR = %(default)

    def presen_theme_list
      themes = []
      theme_path = @config.theme_dir.path+'s5'
      theme_path.each_entry {|d|
	s = d.to_s
	next if /\A\./ =~ s
	next if PRESEN_THEME_IGNORE_DIR.include?(s)
	dir = theme_path+d
	next unless dir.directory?
	themes << d.to_s
      }
      return themes.sort
    end

    # ============================== ext_presen
    PRESEN_DEFAULT_THEME = 'qwikworld'

    def ext_presen
      c_require_pagename
      c_require_page_exist
      c_require_no_path_args
      c_require_no_ext_args

      # Get theme.
      page = @site[@req.base]
      content = page.load

      w = c_parse(content)
      theme = presen_get_theme(w)
      theme ||= PRESEN_DEFAULT_THEME

      w = c_res(content)

      w = presen_patch(w)

      c_set_html
      c_set_no_cache
      @res.body = PresenGenerator.generate(@site, @req.base, w, theme)
    end

    def presen_patch(wabisabi)
      if wabisabi.is_a?(String)		# for test
	wabisabi = c_parse(wabisabi)
      end

      nw = []
      wabisabi.each {|ele|
	if ele.is_a?(Array) && ele[0] == :plugin &&
	    ele.attr[:method] == 'com'
	  # do nothing
	else
	  nw << ele
	end
      }
      return nw
    end

    def presen_get_theme(wabisabi)
      if wabisabi.is_a?(String)		# for test
	wabisabi = c_parse(wabisabi)
      end

      theme = nil
      wabisabi.each {|ele|
	if ele.is_a?(Array) && ele[0] == :plugin &&
	    ele.attr[:method] == 'presen_theme'
	  theme = ele.attr[:param]
	end
      }
      return theme
    end

    def nu_presen_get_theme(content)
      theme = 'i18n'
      wabisabi = c_res(content)
      wabisabi.each {|ele|
	if ele.is_a?(Array) && ele[0] == :plugin &&
	    ele.attr[:method] == 'presen_theme'
	  theme = ele.attr[:param]
	end
      }
      theme
    end
  end

  class PresenGenerator
    def self.generate(site, pagename, wabisabi, theme=nil)
      page = site[pagename]
      title = page.get_title

      wabisabi = resolve_h(wabisabi)
      wabisabi = resolve_slide(wabisabi)

      #theme ||= 'i18n'
      theme ||= 'qwikworld'
      #theme = 'qwikblack'
      #theme = 'qwikborder'

      return html_page(title, theme, wabisabi, pagename)
    end

    REPLACE_H = {:h2=>:h1, :h3=>:h2, :h4=>:h3, :h5=>:h4, :h6=>:h5}
    def self.resolve_h(wabisabi)
      wabisabi.each_tag(:h2, :h3, :h4, :h5, :h6){|w|
	w[0] = REPLACE_H[w[0]]
	w
      }
    end

    def self.resolve_slide(wabisabi)
      presentation = []
      slide = []
      presentation << slide
      wabisabi.each {|e|
	if e.is_a?(Array) && e[0] == :h1 && 0 < slide.size
	  slide = []
	  presentation << slide
	end
	slide << e
      }

      return presentation.map {|slide|
	[:div, {:class=>'slide'}, slide]
      }
    end

    private

    def self.html_page(title, theme, wabisabi, pagename)
      theme_href = ".theme/s5/#{theme}/slides.css"
      html = [[:"!DOCTYPE", 'html', 'PUBLIC',
	  '-//W3C//DTD HTML 4.01 Transitional//EN',
	  'http://www.w3.org/TR/html4/loose.dtd'],
	[:html,
	  {:'xmlns'=>'http://www.w3.org/1999/xhtml',
	    :'xmlns:v'=>'urn:schemas-microsoft-com:vml'},
	  [:head,
	    [:title, title],
	    [:meta, {:name=>'defaultView', :content=>'slideshow'}],
	    [:meta, {:name=>'controlVis', :content=>'hidden'}],
	    [:link, {:rel=>'stylesheet', :href=>theme_href,
		:type=>'text/css', :media=>'projection', :id=>'slideProj'}],
	    [:link, {:rel=>'stylesheet', :href=>'.theme/s5/default/outline.css',
		:type=>'text/css', :media=>'screen', :id=>'outlineStyle'}],
	    [:link, {:rel=>'stylesheet', :href=>'.theme/s5/default/print.css',
		:type=>'text/css', :media=>'print', :id=>'slidePrint'}],
	    [:link, {:rel=>'stylesheet', :href=>'.theme/s5/default/opera.css',
		:type=>'text/css', :media=>'projection', :id=>'operaFix'}],
	    [:style, {:type=>'text/css', :media=>'all'}, ''],
	    [:script, {:src=>'.theme/s5/default/slides.js',
		:type=>'text/javascript'}, '']],
	  [:body,
	    [:div, {:class=>'layout'},
	      [:div, {:id=>'controls'}, ''],
	      [:div, {:id=>'currentSlide'}, ''],
	      [:div, {:id=>'header'}, ''],
	      [:div, {:id=>'footer'},
		[:h1, [:a, {:href=>"#{pagename}.html"}, title]]]],
	    [:div, {:class=>'presentation'}, wabisabi]]]]
      return html
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActPresen < Test::Unit::TestCase
    include TestSession

    def test_plg_presen
      ok_wi [:span, {:class=>'attribute'}, [:a, {:href=>'1.presen'},
		'Presentation mode']], '{{presen}}'

      # test_plg_presen_switch
      ok_wi [], '{{presen_switch}}'

      page = @site.create("PresenTest")
      page.store('{{presen_switch}}')
      res = session('/test/PresenTest.html')
      ok_in([:a, {:href=>"PresenTest.presen"}, "Present"],
	    "//div[@class='section']")
    end

    def test_plg_presen_theme
      ok_wi [], '{{presen_theme(q)}}'
    end

    def test_act_presen
      t_add_user

      page = @site.create_new
      page.store('* あ')
      res = session('/test/1.presen')
      assert_text('あ', 'title')
    end

    def test_get_theme
      res = session
      ok_eq(nil, @action.presen_get_theme('a'))
      ok_eq('q', @action.presen_get_theme('{{presen_theme(q)}}'))
      ok_eq('q', @action.presen_get_theme('a
{{presen_theme(q)}}
b
'))
    end
  end

  class TestPresenGenerator < Test::Unit::TestCase
    include TestSession

    def ok_re(e, w)
      ok_eq(e, Qwik::PresenGenerator.resolve_h(w))
    end

    def ok_slide(e, w)
      ok_eq(e, Qwik::PresenGenerator.resolve_slide(w))
    end

    def test_resolve_h
      res = session
      ok_re([[:h1, 'h']], [[:h2, 'h']])
      ok_re([[:h1, 'h', 'h2']], [[:h2, 'h', 'h2']])
      ok_re([[:h1, 'h', [:b, 'b'], 'c']], [[:h2, 'h', [:b, 'b'], 'c']])
      ok_re([[:h2, 'h']], [[:h3, 'h']])
    end

    def test_resolve_slide
      c = Qwik::PresenGenerator

      # test_resolve_slide
      ok_slide([[:div, {:class=>'slide'}, [[:h1, 'h']]]],
	       [[:h1, 'h']])
      ok_slide([[:div, {:class=>'slide'}, [[:h1, 'h'], [:p, 'p']]]],
	       [[:h1, 'h'], [:p, 'p']])
      ok_slide([[:div, {:class=>'slide'}, [[:h1, 'h'], [:p, 'p']]],
		 [:div, {:class=>'slide'}, [[:h1, 'h'], [:p, 'p']]]],
	       [[:h1, 'h'], [:p, 'p'], [:h1, 'h'], [:p, 'p']])
    end

    def test_get_html
      res = session

      c = Qwik::PresenGenerator
      page = @site.create_new
      page.store("* h\np\n* h2\np2\n")
      wabisabi = @action.c_page_res(page.key)
      w = c.generate(@site, page.key, wabisabi)

      wpage = [[:'!DOCTYPE',
	  'html',
	  'PUBLIC',
	  '-//W3C//DTD HTML 4.01 Transitional//EN',
	  'http://www.w3.org/TR/html4/loose.dtd'],
	[:html,
	  {:'xmlns:v'=>'urn:schemas-microsoft-com:vml',
	    :xmlns=>'http://www.w3.org/1999/xhtml'},
	  [:head,
	    [:title, 'h'],
	    [:meta, {:content=>'slideshow', :name=>'defaultView'}],
	    [:meta, {:content=>'hidden', :name=>'controlVis'}],
	    [:link,
	      {:id=>'slideProj',
		:rel=>'stylesheet',
		:type=>'text/css',
		:href=>'.theme/s5/qwikworld/slides.css',
		:media=>'projection'}],
	    [:link,
	      {:id=>'outlineStyle',
		:rel=>'stylesheet',
		:type=>'text/css',
		:href=>'.theme/s5/default/outline.css',
		:media=>'screen'}],
	    [:link,
	      {:id=>'slidePrint',
		:rel=>'stylesheet',
		:type=>'text/css',
		:href=>'.theme/s5/default/print.css',
		:media=>'print'}],
	    [:link,
	      {:id=>'operaFix',
		:rel=>'stylesheet',
		:type=>'text/css',
		:href=>'.theme/s5/default/opera.css',
		:media=>'projection'}],
	    [:style, {:type=>'text/css', :media=>'all'}, ''],
	    [:script, {:type=>'text/javascript',
		:src=>'.theme/s5/default/slides.js'}, '']],
	  [:body,
	    [:div,
	      {:class=>'layout'},
	      [:div, {:id=>'controls'}, ''],
	      [:div, {:id=>'currentSlide'}, ''],
	      [:div, {:id=>'header'}, ''],
              [:div, {:id=>"footer"}, [:h1, [:a, {:href=>"1.html"}, "h"]]]],
	    [:div,
	      {:class=>'presentation'},
	      [[:div, {:class=>'slide'}, [[:h1, 'h'], [:p, 'p']]],
		[:div, {:class=>'slide'}, [[:h1, 'h2'], [:p, 'p2']]]]]]]]
      ok_eq(wpage, w)
    end
  end
end
