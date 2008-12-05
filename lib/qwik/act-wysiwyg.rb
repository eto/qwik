# -*- coding: shift_jis -*-
# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/act-edit'
require 'qwik/html-to-wabisabi'
require 'qwik/wabisabi-to-wiki'
require 'qwik/act-event'
require 'qwik/act-md5'

module Qwik
  class Action
    D_ExtWysiwyg = {
      :dt => 'WYSIWYG editing mode',
      :dd => 'You can edit a page in wysiwyg mode.',
      :dc => "* Example
You can access [[edit FrontPage|FrontPage.wysiwyg]] in wysiwyg mode.

You can show a link to wysiwyg mode by this plugin.
 {{wysiwyg}}
{{wysiwyg}}
"
    }

    D_ExtWysiwyg_ja = {
      :dt => '見たまま編集モード',
      :dd => 'ページを見たままの状態で編集できます。',
      :dc => "* 例
たとえば、[[FrontPageを見たまま編集|FrontPage.wysiwyg]]ページにいくと、
FrontPageを見たままの状態で編集する画面にとびます。

そのページから見たまま編集画面に飛ぶには、下記のプラグインを使います。
 {{wysiwyg}}
{{wysiwyg}}
"
    }

    def plg_wysiwyg
      return if @req.user.nil?
      return page_attribute('wysiwyg', _('Edit in this page'))
    end
    alias plg_edit_wysiwyg plg_wysiwyg

    def plg_watch(pagename=@req.base, ext=nil)
      ext ||= 'html'
      return if defined?(@watch_defined)
      @watch_defined = true

#//alert('hi');
      script = "
g_watcher_env.add('#{pagename}', '#{ext}');
g_watcher_env.start();
g_weditor.init('#{pagename}', '#{ext}');
g_weditor.check();
"
      md5 = @site[pagename].get.md5hex

      div = [:div, {:id=>'watch'}]

      if @config.debug || defined?($test) && $test
#	div << "watch(#{pagename})"
      end

      div << [:input, {:type=>'hidden', :name=>'watch_md5', :value=>md5}]
      div << [:script,
	{:type=>'text/javascript', :src=>'.theme/js/watch.js'}, '']
      div << [:script, {:type=>'text/javascript'}, script]
      return div
    end

    def ext_wysiwyg
      c_require_pagename
      c_require_page_exist
      c_require_member
      c_require_no_path_args
      c_require_no_ext_args

      if 0 < @req.query.length
	return wysiwyg_save
      end

      return wysiwyg_editor_page(@site, @req.base)
    end

    def wysiwyg_save
      wtext = @req.query['wtext']
      return c_nerror('null content') if wtext.nil? || wtext.empty?
      wtext = wtext.gsub(/\&nbsp\;/, '')	# delete_bogus

      wabisabi = HtmlToWabisabi.parse(wtext)
      wiki = WabisabiToWiki.translate(wabisabi)
      return ext_save(wiki, 'wysiwyg')		# in act-save.rb
    end

    def wysiwyg_editor_page(site, pagename)
      page = site[pagename]
      str = page.load
      w = c_parse(str)	# without resolve

     #w = c_tdiary_resolve(w)
      md5hex = str.md5hex
      ar = Action.wysiwyg_generate(pagename, w, md5hex, $test)

      title = "#{pagename} : "+_('Edit in this page')
      c_surface(title, false) { ar }

      wysiwyg_patch_sidemenu

      return nil
    end

    def wysiwyg_patch_sidemenu
      side = @res.body.get_path("//div[@class='sidebar']")
      side.insert(2, plg_watch(@req.base, @req.ext))
    end

    def self.wysiwyg_generate(pagename, w, md5hex, debug)
      s = [:div, {:class=>'section'}]
      s << [:style, "@import '.theme/css/wema.css';"]
      s << wysiwyg_toolbar(pagename)
      s << wysiwyg_editor(w)	# important
      s << wysiwyg_form(pagename, md5hex, debug)
      s << [:script, {:type=>'text/javascript', :src=>'.theme/js/wysiwyg.js'},
	'']
      div = [:div, {:class=>'wysiwyg'}, [:div, {:class=>'day'}, s]]
      return div
    end

    def self.wysiwyg_toolbar(pagename)
      div = [:div, {:class=>'toolbar'},
	[:a, {:href=>'javascript:wysiwyg_save()'},
	  [:img, {:alt=>'Save', :src=>'.theme/i/action_save.gif'}]],
	[:input, {:type=>'checkbox', :name=>'autosave',
	    :title=>'Auto-save'}],

	[:a, {:href=>"javascript:wysiwyg_command('bold')"},
	  [:img, {:alt=>'Bold', :src=>'.theme/i/text_bold.png'}]],
	[:a, {:href=>"javascript:wysiwyg_command('italic')"},
	  [:img, {:alt=>'Italic', :src=>'.theme/i/text_italic.png'}]],

	[:a, {:href=>"javascript:wysiwyg_command('InsertUnorderedList')"},
	  [:img, {:alt=>'UL', :src=>'.theme/i/text_list_bullets.png'}]],
	[:a, {:href=>"javascript:wysiwyg_command('InsertOrderedList')"},
	  [:img, {:alt=>'OL', :src=>'.theme/i/text_list_numbers.png'}]],

	[:a, {:href=>"javascript:wysiwyg_markup('h2')"},
	  [:img, {:alt=>'H2', :src=>'.theme/i/text_heading_2.png'}]],
	[:a, {:href=>"javascript:wysiwyg_markup('h3')"},
	  [:img, {:alt=>'H3', :src=>'.theme/i/text_heading_3.png'}]],
	[:a, {:href=>"javascript:wysiwyg_markup('h4')"},
	  [:img, {:alt=>'H4', :src=>'.theme/i/text_heading_4.png'}]],

	[:a, {:href=>"javascript:wysiwyg_command('CreateLink')"},
	  [:img, {:alt=>'Link', :src=>'.theme/i/icon_link.gif'}]],
	[:a, {:href=>'javascript:wysiwyg_image()'},
	  [:img, {:alt=>'Image', :src=>'.theme/i/image.gif'}]],

	[:a, {:href=>'javascript:wysiwyg_deleteTags()'},
	  [:img, {:alt=>'Normal', :src=>'.theme/i/text_align_justify.png'}]],

	[:span, {:class=>'wupdate_here'},
	  [:a, {:href=>"#{pagename}.wysiwyg"},
	    [:img,
	      {:alt=>'Update', :src=>'.theme/i/action_refresh_blue.gif'}]]],
	[:input, {:type=>'checkbox', :name=>'autoupdate',
	    :title=>'Auto update'}],
      ]
      return div
    end

    def self.wysiwyg_editor(w)
      # The attribute 'contenteditable' makes it editable.  Only works in IE.
      return [:div, {:id=>'weditor', :contenteditable=>'true'}, w]
    end

    def self.wysiwyg_form(pagename, md5hex, debug=false)
      #debug = true
      div = [:div]
      div << {:style=>'display:none;'} if ! debug
      div << [:form, {:action=>pagename+'.wysiwyg', :method=>'POST',
	  :name=>'wform', :id=>'wform'},
	[:input, {:type=>'submit', :value=>'Submit'}],
	[:input, {:type=>'text', :name=>'mode', :value=>'save'}],
	[:input, {:type=>'text', :name=>'md5hex', :value=>md5hex}],
	[:textarea, {:name=>'wtext', :id=>'wtext'}, '']]

      return div
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActWysiwyg < Test::Unit::TestCase
    include TestSession

    def test_plg_edit_wysiwyg
      ok_wi([:span, {:class=>'attribute'},
	      [:a, {:href=>'1.wysiwyg'}, 'Edit in this page']],
	    '{{edit_wysiwyg}}')
      ok_wi([:span, {:class=>'attribute'},
	      [:a, {:href=>'1.wysiwyg'}, 'Edit in this page']],
	    '{{wysiwyg}}')
    end

    def test_ext_wysiwyg
      t_add_user

      page = @site.create_new
      page.store('* t')

      res = session('/test/1.wysiwyg')
      ok_title('1 : Edit in this page')

      res = session('POST /test/1.wysiwyg?wtext=ttt')
      ok_eq('ttt', page.load)

      res = session('POST /test/1.wysiwyg?wtext=<p>t</p>')
      ok_eq("t\n", page.load)

      res = session('POST /test/1.wysiwyg?wtext=<h2>t</h2>')
      ok_eq("* t\n", page.load)

      res = session('POST /test/1.wysiwyg?wtext=<p>a %26nbsp%3b b</p>')
      ok_eq("a  b\n", page.load)

      # test_wysiwyg_bug
      res = session('/test/TextFormatSimple.wysiwyg')
      ok_title('TextFormatSimple : Edit in this page')
    end
  end
end
