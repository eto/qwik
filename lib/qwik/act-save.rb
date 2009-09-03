# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/act-password'
require 'qwik/wabisabi-diff'
require 'qwik/act-edit'
require 'qwik/act-monitor'
require 'qwik/act-event'
#require 'qwik/act-rrefs'

module Qwik
  class Action
    def ext_save(contents=nil, ext='html')
      c_require_login
      c_require_page_exist

      contents = @req.query['contents'] if contents.nil?
      return c_nerror('contents is nil.') if contents.nil?

      page = @site[@req.base]
      # Do not delete a page with password
      if contents.empty? && ! page.get_password
	@site.delete(@req.base)	# DELETE
	c_make_log('delete')	# DELETE
	c_monitor('delete')	# DELETE
#        clear_rrefs(@req.base)
        site_updated
	return save_page_deleted
      end

      newcontents = Page.embed_password(contents)	# embed the password
      if ! page.match_password?(newcontents)
	return save_password_does_not_match(contents)
      end
      contents = newcontents

      contents = contents.gsub(/\r/, '')
      md5hex = @req.query['md5hex']
      md5hex = nil if page.get_password
      begin
	page.put_with_md5(contents, md5hex)	# STORE
      rescue PageCollisionError	# failed to save?
	return save_conflict(contents)
      end

      c_make_log('save')	# STORE
      c_monitor('save')		# STORE
      c_event('save')		# STORE

      url = "#{@req.base}.#{ext}"

#      update_rrefs
      site_updated

      return save_page_is_saved(url)
    end

    def save_page_deleted
      url = 'FrontPage.html'
      c_notice(_('Page is deleted.'), url) {
	[[:h2, _('Page is deleted.')],
	  [:p, [:a, {:href=>url}, _('Go next')]]]
      }
    end

    def save_password_does_not_match(contents)
      message = [:div, {:class=>'day'},
	[:h2, _('Password does not match.')],
	[:div, {:class=>'section'},
	  [:p, [:tt, '{{password('], _('Password'), [:tt, ')}}']],
	  [:p, _('Please find a line like that above, then input password in parentheses.')]]]
      return generate_edit_page(contents, message)
    end

    def edit_conflict_message(url, editing_content)
      return [:div, {:class=>'day'},
	[:h2, _('Page edit conflict')],
	[:div, {:class=>'section'},
	  [:p, _('Please save the following content to your text editor.'),
	    [:a, {:href=>url}, _('Newest page')],
	    _(': see this page and re-edit again.')]],
	editing_content]
    end

    def save_conflict(contents)
      pagename = @req.base
      page = @site[pagename]
      differ = DiffGenerator.generate(contents, page.load)
      return save_edit_conflict(pagename, differ, contents)
    end

    def save_edit_conflict(pagename, differ, contents)
      url = pagename+'.html'
      editing_contents = [:div, {:class=>'differ'}, differ]
      message = edit_conflict_message(url, editing_contents)
      return generate_edit_page(contents, message)
    end

    def save_page_is_saved(url)
      return c_notice(_('Page is saved.'), url){
	[[:h2, _('Page is saved.')],
	  [:p, [:a, {:href=>url}, _('Go next')]]]
      }
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActSave < Test::Unit::TestCase
    include TestSession

    def test_save_basic
      t_add_user

      # Create a new page.
      res = session('POST /test/.new?t=TestPage')
      ok_xp([:a, {:href=>'TestPage.edit'}, 'Edit new page'],
	    '//div[@class="section"]/a')

      res = session('/test/TestPage.edit')
      ok_in(['Edit | TestPage'], 'title')
      ok_in(['* TestPage
'], 'textarea')

      # Try to save a nonexistent page.
      res = session('/test/NoSuchPage.save?contents=t')
      #ok_eq(404, @res.status)
      ok_in(['Page not found.'], 'h1')

      # Save to the page.
      res = session('/test/TestPage.save?contents=t')
      ok_in(['Page is saved.'], 'title')
      ok_in(['Page is saved.'], 'h1')
      ok_eq('t', @site['TestPage'].load)

      # Delete the page.
      res = session('/test/TestPage.save?contents=') # null content
      ok_in(['Page is deleted.'], 'title')

      # Try to delete the page again.
      res = session('/test/TestPage.save?contents=') # null content
      ok_in(['Page not found.'], 'title')
    end

    def test_save_again
      t_add_user

      page = @site.create_new
      page.store('* t')
      res = session('/test/1.edit') # See the edit page.
      ok_in(['Edit | t'], 'title')
      ok_in(['Edit', ' | ', [:a, {:href=>'1.html'}, 't']], 'h1')
      ok_in(['* t'], 'textarea')

      # Save to the page.
      res = session('/test/1.save?contents=* t%0A* h2 of 2%0Ah22body%0A')
      ok_in(['Page is saved.'], 'title')
      ok_in(['Page is saved.'], 'h1')

      # See the result.
      res = session('/test/1.html')
      ok_in(['t'], 'h1')
    end

    def test_save_new_delete
      t_add_user

      res = session('/test/')	# See the page.
      ok_in(['FrontPage'], 'title')

      # See the edit page.
      res = session('/test/FrontPage.edit')
      ok_in(['Edit | FrontPage'], 'title')
      assert_attr({:action=>'FrontPage.save', :method=>'POST'}, 'form')
      #ok_in(/^\* FrontPage/, '//textarea')
      ok_xp([:input, {:value=>'dae58ef7afd29544c7196b4cbde04902',
		:type=>'hidden',  :name=>'md5hex'}], '//input')
      e = @res.body.get_path('//input')
      md5hex = e[1][:value]
      ok_eq('dae58ef7afd29544c7196b4cbde04902', md5hex)
      ok_xp([:input, {:value=>'Save', :type=>'submit',
		:class=>'submit', :name=>'save'}],
	    '//input[2]')

      # Save to the page.
      res = session("/test/FrontPage.save?md5hex=#{md5hex}&save=Save&contents=* FrontPage%0A[[test]]%0A")
      ok_in(['Page is saved.'], 'title')
      ok_in(['Page is saved.'], 'h1')
      ok_xp([:a, {:href=>'FrontPage.html'}, 'Go next'], '//a')

      # See the result.  The page contains a link to the new page.
      res = session('/test/')
      ok_in(['test', [:a, {:href=>'.new?t=test'},
		[:img, {:src=>'.theme/i/new.png', :alt=>'create'}]]],
	    '//div[@class="section"]//span')
      ok_xp([:a, {:href=>'.new?t=test'},
	      [:img, {:src=>'.theme/i/new.png', :alt=>'create'}]],
	    '//div[@class="section"]//a')

      # Create a new page.
      res = session('POST /test/.new?t=test')
      ok_in(['New page'], 'title')
      ok_in(['New page'], 'h1')
      ok_xp([:a, {:href=>'test.edit'}, 'Edit new page'],
	    '//div[@class="section"]//a')
      ok_eq('* test
', @site['test'].load)

      # See the from page.
      res = session('/test/')
      ok_xp([:a, {:href=>'test.html'}, 'test'],
	    '//div[@class="section"]//a')

      # Try to see a nonexistent page.
      res = session('/test/nosuchpage.html')
      #ok_eq(404, @res.status)
      ok_in(['Page not found.'], 'title')
      ok_in(['Page not found.'], 'h1')

      # Try to edit a nonexistent page.
      res = session('/test/nosuchpage.edit')
      ok_in(['Page not found.'], 'title')

      # See the edit page.
      res = session('/test/test.edit')
      ok_in(['* test
'], 'textarea')
      ok_xp([:input, {:value=>'2f1580c9dc650a5d827ba7bf44be031b',
		:type=>'hidden', :name=>'md5hex'}], '//input')
      md5hex = '2f1580c9dc650a5d827ba7bf44be031b'

      # Selete the new page.
      res = session("/test/FrontPage.save?md5hex=#{md5hex}&save=Save&contents=")
      ok_in(['Page is deleted.'], 'title')
      ok_in(['Page is deleted.'], 'h1')
    end

    def test_conflict
      t_add_user

      page = @site.create_new
      page.store('t1')

      # See the page
      res = session('/test/1.html')
      ok_xp([:p, 't1'], '//div[@class="section"]/p')

      # See the edit page.
      res = session('/test/1.edit')
      ok_xp([:textarea, {:id=>'contents', :name=>'contents',
		:cols=>'70', :rows=>'20', :class=>'focus'}, 't1'],
	    '//textarea')
      ok_xp([:input, {:value=>'83f1535f99ab0bf4e9d02dfd85d3e3f7',
		:type=>'hidden', :name=>'md5hex'}], '//input')
      ok_xp([:input, {:value=>'Save', :type=>'submit',
		:class=>'submit', :name=>'save'}],
	    '//input[2]')

      # Save the page.
      res = session('/test/1.save?contents=t2&md5hex=83f1535f99ab0bf4e9d02dfd85d3e3f7')
      ok_in(['Page is saved.'], 'title')
      ok_eq('t2', page.load)

      # See the edit page again.
      res = session('/test/1.edit')
      ok_xp([:textarea, {:id=>'contents', :name=>'contents',
		:cols=>'70', :rows=>'20', :class=>'focus'}, 't2'],
	    '//textarea')
      ok_xp([:input, {:value=>'0f826a89cf68c399c5f4cf320c1a5842',
		:type=>'hidden', :name=>'md5hex'}], '//input')

      # When you are editing the page, another person edited the page.
      page.store('t3')

      # Try to save the page, but it failed.
      res = session('/test/1.save?contents=t4&md5hex=0f826a89cf68c399c5f4cf320c1a5842')
      ok_in(['Edit | 1'], 'title')
      ok_in(['Page edit conflict'], "//div[@class='message']/h2")
      ok_in(['Please save the following content to your text editor.',
	      [:a, {:href=>'1.html'}, 'Newest page'],
	      ': see this page and re-edit again.'],
	    "//div[@class='message']/p")
      ok_in([[:del, 't4'], [:br], [:ins, 't3'], [:br]],
	    "//div[@class='differ']")
      ok_eq('t3', page.load)
    end
  end
end
