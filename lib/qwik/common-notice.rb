# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/common-error'

module Qwik
  class Action
    # Method for testing page design.
    def act_test_notice
      w = login_show_login_page('http://example.com/HelloQwik/')
      c_notice('act_test_notice') { w }
    end

    def c_notice(title, url=nil, status=200, sec=0, &b)
      msg = yield
      generate_notice_page(status, title, url, msg, sec)
    end

    def c_nredirect(title, url, &b)
      msg = ''
      msg = yield if block_given?
      c_set_location(c_relative_to_absolute(url))
      generate_notice_page(302, title, url, msg)
    end

    def generate_notice_page(status, title, url=nil, msg='', sec=0)
      #url = nil	# for debug
      @res.status = status
      template = @memory.template.get('notice')
      @res.body = Action.notice_generate(template, title, msg, url, false, sec)
      c_set_html
      c_set_no_cache
      return nil
    end

    def self.notice_generate(template, title, msg, url=nil,
			     redirectflag=false, sec=0)
      w = template.get_tag('head')

      # insert title
      w.insert(1, [:title, title])

      # insert JavaScript
      js = generate_js
      w.insert(w.length, *js)

      # insert meta
      w << [:meta, {:name=>'ROBOTS', :content=>'NOINDEX,NOFOLLOW'}]
      if url && ! redirectflag		# redirect
	w << [:meta, {'http-equiv'=>'Refresh',
	    :content=>"#{sec}; url=#{url}"}]
      end

      # insert h1
      w = template.get_tag('h1')
      w << title

      # insert section
      w = template.get_by_class('section')
      w << msg

      template
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestCommonNotice < Test::Unit::TestCase
    include TestSession

    def test_all
      res = session

      @action.generate_notice_page(200, 'title') { 'msg' }
      eq 200, res.status
      ok_title 'title'

      @action.generate_notice_page(200, 'title', 'u') { 'msg' }
      eq 200, res.status
      ok_title 'title'
      ok_xp([:meta, {:content=>'0; url=u', 'http-equiv'=>'Refresh'}],
	    'meta[2]', res)

      @action.c_notice('c_notice title') { 'msg' }
      eq 200, res.status
      ok_title 'c_notice title'

      t_add_user

      res = session('/test/.test_notice')
      ok_title 'act_test_notice'
    end

    def test_c_nredirect
      res = session
      @action.c_nredirect('t', 't.html')
      eq 'http://example.com/test/t.html', res['Location']
      @action.c_nredirect('t', 'http://e.com/')
      eq 'http://e.com/', res['Location']
    end

    def test_notice_generate
      template = @memory.template.get('notice')
      eq [:h1], template.get_tag('h1')
      eq [:div, {:class=>'section'}],
	template.get_by_class('section')

      res = Qwik::Action.notice_generate(template, 'title', 'msg')
      eq [:title, 'title'], res.get_tag('title')
      #      eq [:script, {:src=>'.theme/js/base.js',
      #		:type=>'text/javascript'}, ''], res.get_tag('script')
      eq [:meta, {:content=>'NOINDEX,NOFOLLOW', :name=>'ROBOTS'}],
	res.get_tag('meta')
      eq [:h1, 'title'], res.get_tag('h1')
      eq [:div, {:class=>'section'}, 'msg'],
	res.get_path('//div[@class="section"]')
      eq nil, res.get_tag('meta[2]')	# not redirected

      template = @memory.template.get('notice')
      res = Qwik::Action.notice_generate(template, 'title', 'msg', 'url')
      eq [:meta, {:content=>'0; url=url', 'http-equiv'=>'Refresh'}],
	res.get_tag('meta[2]')	# redirected
    end
  end
end
