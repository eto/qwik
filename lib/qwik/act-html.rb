# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    MAX_PAGE_SIZE = 100 * 1024

    def ext_html
      c_require_page_exist
      c_require_member if Action.private_page?(@req.base)

      page = @site[@req.base]
      if MAX_PAGE_SIZE < page.size
        return c_nerror(_('Page too big.')) {
          [:div,
           [:p, _('The page is too big to show.')],
           [:p, _('Max is 100K bytes. Please truncate it.')],
           [:p, [:a, {:href=>"#{@req.base}.edit"}, _('Edit')]]]
        }
      end

      if ! c_login?
	c_set_html

	if @config.test		# Only for test.
	  @res.body = view_page_cache_generate(@req.base)
	  return
	end

	pagename = @req.base
	dirpath = @site.cache_path
	file = Action.html_page_cache_path(dirpath, pagename)

	if view_page_cache_need_generate?(file)
	  view_page_cache_generate(pagename)
	end

	c_simple_send(file.to_s, 'text/html; charset=Shift_JIS')
	return
      end

      #c_make_log('view')	# do not check.
      #c_monitor('view')
      surface_view(@req.base)	# common-surface.rb

      users = @config[:wysiwyg_users]
      if users && users.split(/,\s/).include?(@req.user)
	head = @res.body.get_path('//head')
	head << [:meta, {'http-equiv'=>'Refresh',
	    :content=>"0; url=#{@req.base}.wysiwyg"}]
      end
    end

    def self.private_page?(pagename)
      return pagename[0] == ?_
    end

    def view_page_cache_need_generate?(file)
      return true if ! file.exist?
      return true if file.mtime < @site.last_page_time
      return true if @req.header['cache-control'] == ['no-cache']
      return false
    end

    # called from act-archive
    def view_page_cache_generate(pagename)
      w = surface_view_generate(pagename)
      str = w.format_xml	# format xml with "\n"
      dirpath = @site.cache_path
      Action.html_page_cache_store(dirpath, pagename, str)
      return w
    end

    def self.html_page_cache_store(dirpath, pagename, str)
      Action.html_page_cache_path(dirpath, pagename).write(str)	# Write to file.
    end

    def self.html_page_cache_path(dirpath, pagename)
      return (dirpath+"#{pagename}.html").cleanpath
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActHtml < Test::Unit::TestCase
    include TestSession

    def test_private_page?
      eq false, Qwik::Action.private_page?('t')
      eq true,  Qwik::Action.private_page?('_t')
    end

    def test_protect_underbar
      t_add_user

      page = @site.create '_t'
      page.store '*t'

      res = session '/test/_t.html'	# with login
      ok_title 't'

      res = session('/test/_t.html') {|req|
	req.cookies.clear
      }
      ok_title 'Login'
    end

    def test_ext_html
      t_add_user
      t_site_open

      page = @site['1']
      eq nil, page
      
      res = session '/test/1.html'
      eq 404, @res.status
      ok_title 'Page not found.'

      page = @site.create_new
      page.store 't'

      res = session '/test/1.html'
      ok_in ['t'], "//div[@class='section']/p"

      # test_cache
      res = session('/test/') {|req|
	req.cookies.clear
      }
      # You can see the page.
      ok_title 'FrontPage'
      # But you are not logged in.
      ok_in ['Login'], "//div[@class='adminmenu']//a"
      eq 'text/html; charset=Shift_JIS', @res.headers['Content-Type']

      t_without_testmode {
	res = session('/test/') {|req|		# Do it again
	  req.cookies.clear
	}
	assert_instance_of(File, res.body)	# The body is a cached content.
	str = res.body.read
	res.body.close		# Important.
	assert_match(/FrontPage/, str)
	eq 'text/html; charset=Shift_JIS', res.headers['Content-Type']
      }
    end

    def test_wysiwyg_users
      t_add_user
      t_site_open

      page = @site.create_new

      res = session '/test/1.html'
      ok_xp nil, '//meta'

      @config[:wysiwyg_users] = "a@e.com, #{DEFAULT_USER}, b@e.com"

      res = session('/test/1.html')
      ok_xp [:meta, {:content=>'0; url=1.wysiwyg', 'http-equiv'=>'Refresh'}],
	'//meta'
    end

    def test_guest_in_public_mode
      t_site_open

      page = @site.create_new

      res = session('/test/1.html') {|req| req.cookies.clear }
      ok_title '1'

      res = session('/test/1.html') {|req| req.cookies.clear }
      ok_title '1'

    end

    def test_big_page
      t_site_open

      page = @site.create_new
      page.store("a" * (100 * 1024 + 1))

      res = session('/test/1.html') {|req| req.cookies.clear }
      ok_title "Page too big."
    end

    def test_superpre_sharp_mark
      t_add_user
      page = @site.create_new
      page.store '{{{
#t
}}}'
      session '/test/1.html'
      ok_in ["#t\n"], "//div[@class='section']/pre"
    end
  end
end
