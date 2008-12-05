# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/act-save'
require 'qwik/act-files'	# files_form

module Qwik
  class Action
    def ext_edit
      c_require_login
      c_require_page_exist
      generate_edit_page
    end

    def generate_edit_page(contents=nil, message=nil)
     #c_monitor('startedit')
      c_editor(@site, @req.base, contents, message)
    end

    # only for check design
    def act_test_editor
      w = c_page_res('TextFormatSimple')
      generate_editor_page('act_test_editor', 'h1', w, w, w)
    end

    def c_editor(site, pagename, contents=nil, message=[''])
      page = site[pagename]

      page_title = page.get_title

      title = _('Edit')+' | '+page_title

      h1 = [_('Edit'), ' | ', [:a, {:href=>page.url}, page_title]]

      str = contents
      str = page.load if contents.nil?

      md5hex = str.md5hex

      edit_form = editor_edit_form(pagename, str, md5hex)

      attach_form, attach_list = editor_attach_form(pagename)

      main = editor_main(edit_form, attach_form, attach_list, pagename)

      ar = []
      ar << editor_help_qwikweb
      ar << editor_help_edit
      ar << editor_page_functions(pagename)
      ar << editor_site_admin
      sidebar = editor_sidebar(*ar)

      generate_editor_page(title, h1, message, main, sidebar)
    end

    def editor_edit_form(pagename, str, md5hex)
      form = [:form, {:method=>'POST', :action=>"#{pagename}.save"},
	[:textarea, {:name=>'contents', :id=>'contents',
	    :cols=>'70', :rows=>'20', :class=>'focus'}, str],
	[:div, {:class=>'right'},
	  [:input, {:type=>'hidden', :name=>'md5hex', :value=>md5hex}],
	  [:input, {:class=>'submit', :type=>'submit',
	      :name=>'save', :value=>_('Save')}]]]
      return form
    end

    def editor_attach_form(pagename)
      form = files_form(pagename)
      list = files_list
      return form, list
    end

    def editor_main(edit_form, attach_form, attach_list, pagename)
      divs = [
	[:div, {:class=>'day edit'},
	  [:h2, _('Edit')],
	  [:div, {:class=>'section section_edit'}, edit_form]],
	[:div, {:class=>'day attach'},
	  [:h2, _('Attach Files')],
	  [:div, {:class=>'section section_attach'},
	    attach_form,
	    [:div, {:class=>'right attach_many'},
	      [:a, {:href=>"#{pagename}.files"}, _('Attach many files')]]]]
      ]

      if attach_list
	divs << [:div, {:class=>'day attach'},
	  [:h2, _('Files')],
	  [:div, {:class=>'section'},
	    [:ul, *attach_list]]]
      end

      return divs
    end

    def editor_help_qwikweb
      return [:div, {:class=>'section edithistory'},
	[:h2, _('Help')],
	[:ul,
	  [:li, [:a, {:href=>'.describe'}, _('How to qwikWeb')]]
	]]
    end

    def editor_help_edit
      return [:div, {:class=>'section edithelp'},
	[:h2, _('Text Format')],
	[:ul,
	  [:li, [:tt, '*'], ' ', _('Header')],
	  [:li, [:tt, '-'], ' ', _('List')],
	  [:li, [:tt, '+'], ' ', _('Ordered list')],
	  [:li, [:tt, '>'], ' ', _('Block quote')],
	  [:li, [:tt, ':'], ' ', _('Word'), ': ', _('Definition')],
	  [:li, [:tt, ','], ' ', _('Table')],
	  [:li, [:tt, "''"], _('Emphasis'), [:tt, "''"]],
	  [:li, [:tt, "'''"], _('Stronger'), [:tt, "'''"]],
	  [:li, [:tt, '[['], 'FrontPage', [:tt, ']]'], ' ', _('Link')]],
	[:p, [:a, {:href=>'TextFormat.describe'}, _('more help')]]]
    end

    def editor_page_functions(pagename)
      return [:div, {:class=>'section edithistory'},
	[:h2, _('Page functions')],
	[:ul,
	  [:li, [:a, {:href=>"#{pagename}.backup"},  _('Backup')]],
	  [:li, [:a, {:href=>"#{pagename}.history"}, _('Time machine')]],
	  [:li, [:a, {:href=>"#{pagename}.presen"},  _('Presentation mode')]],
	  [:li, [:a, {:href=>"#{pagename}.wysiwyg"}, _('Edit in this page')]],
	  [:li, [:a, {:href=>"PluginWema.describe"}, _('How to use post-its')]],
	]]
    end

    def editor_site_admin
      return [:div, {:class=>'section edithistory'},
	[:h2, _('Site administration')],
	[:ul,
	  [:li, [:a, {:href=>'SiteManagement.describe'}, _('Site Menu')]],
	  [:li, [:a, {:href=>'_SiteConfig.html'}, _('Site Configuration')]],
	  [:li, [:a, {:href=>'.plan'}, _('Create a new plan')]],
	  [:li, [:a, {:href=>'.chronology'}, _('Chronology')]],
	  [:li, [:a, {:href=>'_GroupMembers.html'}, _('Group members')]],
	  [:li, [:a, {:href=>"#{@site.sitename}.zip"}, _('Site Archive')]],
	  [:li, [:a, {:href=>"#{@site.sitename}.sitebackup"}, _('Site backup')]],
	  [:li, [:a, {:href=>"_GroupConfig.html"}, _('Mailing List Configuration')]],
	  [:li, [:a, {:href=>".sendpass"}, _('Send Password')]],
	]]
    end

    def editor_sidebar(*a)
      return a
    end

    def generate_editor_page(title, h1, message, main, sidebar)
      @res.status = 200
      template = @memory.template.get('editor')
      @res.body = Action.editor_generate(template, title, h1,
				       message, main, sidebar)
      c_set_html
      c_set_no_cache
      return nil
    end

    def self.editor_generate(template, title, h1, message, main, sidebar)
      w = template.get_tag('head')

      # insert title
      w.insert(1, [:title, title])

      # insert JavaScript
      js = generate_js
      w.insert(w.length, *js)

      # insert meta
      w << [:meta, {:name=>'ROBOTS', :content=>'NOINDEX,NOFOLLOW'}]

      # insert h1
      w = template.get_tag('h1')
      #w << title
      w << h1

      # insert message
      w = template.get_by_class('message')
      w << message

      # insert main
      w = template.get_by_class('main')
      w.insert(2, *main)

      # insert sidebar
      w = template.get_by_class('sidebar')
      w.insert(2, *sidebar)

      return template
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActEdit < Test::Unit::TestCase
    include TestSession

    def test_generator
      res = session

      template = @memory.template.get('editor')
      eq [:h1], template.get_tag('h1')
      eq [:div, {:class=>'main'}], template.get_by_class('main')

      res = Qwik::Action.editor_generate(template, 'title', 'h1',
					 'msg', ['m'], ['s'])

      eq [:title, 'title'], res.get_tag('title')
#     eq [:script, {:src=>'.theme/js/base.js',
#		:type=>'text/javascript'}, ''], res.get_tag('script')
      eq [:link, {:href=>'.theme/css/base.css', :rel=>'stylesheet',
	  :media=>'screen,tv', :type=>'text/css'}],
	res.get_tag('link')
      eq [:link, {:media=>'screen,tv', :type=>'text/css',
	  :href=>'.theme/qwikeditor/qwikeditor.css',
	  :rel=>'stylesheet'}],
	res.get_tag('link[2]')
      eq [:meta, {:content=>'NOINDEX,NOFOLLOW', :name=>'ROBOTS'}],
	res.get_tag('meta')
      eq [:h1, 'h1'], res.get_tag('h1')
      eq [:div, {:class=>'message'}, 'msg'],
	res.get_path("//div[@class='message']")
      eq [:div, {:class=>'main'}, 'm'],
	res.get_path("//div[@class='main']")
      eq [:div, {:class=>'sidebar'}, 's'],
	res.get_path("//div[@class='sidebar']")
    end

    def test_all
      res = session

      @action.generate_editor_page('title', 'h1', 'msg', ['ma'], ['si'])
      eq 200, res.status
      ok_title 'title'
      ok_xp [:div, {:class=>'message'}, 'msg'], "//div[@class='message']"
      ok_xp [:div, {:class=>'main'}, 'ma'], "//div[@class='main']"
      ok_xp [:div, {:class=>'sidebar'}, 'si'], "//div[@class='sidebar']"

      t_add_user

      res = session '/test/.test_editor'
      #ok_xp [:title, 'Edit | 1'], 'title', res
      #ok_xp [:title, 'act_test_editor'], 'title', res

      page = @site.create_new
      page.store 't'
      @action.c_editor(@site, '1')
      ok_title 'Edit | 1'
      ok_xp [:div, {:class=>'message'}, ['']],
	"//div[@class='message']"

      # edit form
      assert_rattr({:action=>'1.save', :method=>'POST'},
		   "//div[@class='day edit']/form")
      ok_xp [:textarea, {:id=>'contents', :name=>'contents',
		:cols=>'70', :rows=>'20', :class=>'focus'}, 't'],
	    "//div[@class='day edit']/form/textarea"
      ok_xp [:input, {:value=>'e358efa489f58062f10dd7316b65649e',
		:type=>'hidden', :name=>'md5hex'}],
	    "//div[@class='day edit']/form/input"
      ok_xp [:input, {:value=>'Save', :type=>'submit',
		:class=>'submit', :name=>'save'}],
	    "//div[@class='day edit']/form/input[2]"

      # attach form
      assert_rattr({:enctype=>'multipart/form-data',
		     :action=>'1.files', :method=>'POST'},
		   "//div[@class='day attach']/form")
      ok_xp [:input, {:type=>'file', :name=>'content'}],
	    "//div[@class='day attach']/form/input"
      ok_xp [:input, {:value=>'Attach', :type=>'submit', :class=>'submit'}],
	    "//div[@class='day attach']/form/input[2]"
      ok_in [:a, {:href=>'1.files'}, 'Attach many files'],
	    "//div[@class='day attach']//div[@class='right attach_many']"
#      ok_xp [:a, {:href=>'_SiteMenu.html'}, 'SiteMenu'],
#	    "//div[@class='sidebar']//a"
    end

    def test_editor
      res = session

      # test_edit_page_generator
      page = @site.create_new
      page.store "* test\ntestbody\n** h3\nh3body\n* h2\nh2body\n"
      side = @site['_SideMenu']
      side.store '* side\nsidebody [[1]]'

      res = session
      @action.c_editor(@site, '1', 'contents', 'msg')
      ok_title 'Edit | test'
      assert_text 'Edit | test', 'h1'
      ok_xp [:meta, {:content=>'NOINDEX,NOFOLLOW', :name=>'ROBOTS'}],
	    '//meta'
      ok_in ['msg'], "//div[@class='message']"
      assert_attr({:action=>'1.save', :method=>'POST'}, 'form')
      assert_text 'contents', 'textarea'
      ok_xp [:input, {:value=>'98bf7d8c15784f0a3d63204441e1e2aa',
		:type=>'hidden', :name=>'md5hex'}], '//input'
      ok_xp [:input, {:value=>'Save', :type=>'submit', :class=>'submit',
		:class=>'submit', :name=>'save'}], '//input[2]'
#      ok_xp [:a, {:href=>'_SiteMenu.html'}, 'SiteMenu'],
#	    '//div[@class='sidebar']//a'
#      ok_xp [:a, {:href=>'1.presen'}, 'Presentation mode'],
#	    "//div[@class='sidebar']//a"
   end
  end
end
