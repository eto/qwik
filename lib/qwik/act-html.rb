$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    def ext_html
      #select_appropriate_lang_page

      c_require_page_exist
      c_require_member if Action.private_page?(@req.base)

      if ! c_login?
	#c_monitor('view')	# do not check.
	return view_page_cache_check
      end

      #c_make_log('view')	# do not check.
      #c_monitor('view')
      surface_view(@req.base)	# common-surface.rb
    end

    def nu_select_appropriate_lang_page
      @req.accept_language.each {|lang|
	pagename_with_lang = "#{@req.base}_#{lang}"
	if @site.exist?(pagename_with_lang)
	  @req.base = pagename_with_lang
	  return true
	end
      }
      return false
    end

    def self.private_page?(pagename)
      return pagename[0] == ?_
    end

    def view_page_cache_check
      c_set_html
      #c_set_no_cache	# You can cache the page.

      if @config.test	# Only for test.
	w = view_page_cache_generate(@req.base)
	@res.body = w
	return w
      end

      pagename = @req.base
      dirpath = @site.cache_path
      file = Action.html_page_cache_path(dirpath, pagename)

      if view_page_cache_need_generate?(file)
	view_page_cache_generate(pagename)
      end

      c_simple_send(file.to_s, "text/html; charset=Shift_JIS")
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
      # Write it to the file.
      Action.html_page_cache_path(dirpath, pagename).write(str)
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
      ok_eq false, Qwik::Action.private_page?('t')
      ok_eq true,  Qwik::Action.private_page?('_t')
    end

    def test_protect_underbar
      t_add_user

      page = @site.create('_t')
      page.store('*t')

      res = session('/test/_t.html') # with login
      ok_title('t')

      res = session('/test/_t.html') {|req|
	req.cookies.clear
      }
      ok_title('Login')
    end

    def test_ext_html
      t_add_user
      t_site_open

      page = @site['1']
      ok_eq(nil, page)
      
      res = session('/test/1.html')
      #ok_eq(404, @res.status)
      ok_title('Page not found.')

      page = @site.create_new
      page.store('t')

      res = session('/test/1.html')
      ok_in(['t'], "//div[@class='section']/p")

      # test_cache
      res = session('/test/') {|req|
	req.cookies.clear
      }
      # You can see the page.
      ok_title('FrontPage')
      # But you are not logged in.
      ok_in(['Login'], "//div[@class='adminmenu']//a")
      ok_eq("text/html; charset=Shift_JIS", @res.headers['Content-Type'])

      t_without_testmode {
	res = session('/test/') {|req|	# do it again
	  req.cookies.clear
	}
	assert_instance_of(File, res.body)	# The body is a cached content.
	str = res.body.read
	res.body.close		# Important.
	assert_match(/FrontPage/, str)
	ok_eq("text/html; charset=Shift_JIS",
	      res.headers['Content-Type'])
      }
    end

    def nu_test_pagename_with_lang
      t_add_user

      page = @site.create 't'
      res = session '/test/t.html'
      ok_title 't'

      page = @site.create 't_en'
      res = session '/test/t.html'
      ok_title 't_en'
    end
  end
end
