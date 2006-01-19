#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '..' unless $LOAD_PATH.include?('..')

module Qwik
  class Action
    # Method for testing page design.
    def act_test_notice
      w = login_show_login_page('http://example.com/HelloQwik/')
      c_notice('act_test_notice'){w}
    end

    def c_notice(title, url=nil, status=200, sec=0, &b)
      msg = yield
      generate_notice_page(status, title, url, msg, sec)
    end

    def c_nerror(title, url=nil, status=500, &b)
      status = 200 if @config.test
      msg = title
      msg = yield if block_given?
      generate_notice_page(status, title, url, msg)
    end

    def c_notfound(title, &b)
      return c_nerror(title, nil, 404, &b)
    end

    def c_nredirect(title, url, &b)
      msg = ''
      msg = yield if block_given?
      @res['Location'] =  c_relative_to_full(url)
    # @res['Location'] =  c_relative_to_absolute(url)
      generate_notice_page(302, title, url, msg)
    end

    def generate_notice_page(status, title, url=nil, msg='', sec=0)
      #url = nil # for debug
      @res.status = status
      template = @memory.template.get('notice')
      @res.body = Action.notice_generate(template, title, msg, url, false, sec)
      c_set_html
      c_set_no_cache
      nil
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
      if url && !redirectflag # redirect
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
  class TestActNotice < Test::Unit::TestCase
    include TestSession

    def test_all
      res = session

      @action.generate_notice_page(200, 'title'){'msg'}
      ok_eq(200, res.status)
      ok_xp([:title, 'title'], 'title', res)

      @action.generate_notice_page(200, 'title', 'u'){'msg'}
      ok_eq(200, res.status)
      ok_xp([:title, 'title'], 'title', res)
      ok_xp([:meta, {:content=>'0; url=u', 'http-equiv'=>'Refresh'}],
	    'meta[2]', res)

      @action.c_notice('c_notice title'){'msg'}
      ok_eq(200, res.status)
      ok_xp([:title, 'c_notice title'], 'title', res)
      @action.c_nerror('c_notice_error title'){'msg'}
      #ok_eq(500, res.status)
      ok_xp([:title, 'c_notice_error title'], 'title', res)

      t_add_user

      res = session('/test/.test_notice')
      ok_xp([:title, 'act_test_notice'], 'title', res)
    end

    def test_c_nredirect
      res = session
      @action.c_nredirect('t', 't.html')
     #ok_eq('http://127.0.0.1:9190/t.html', res['Location'])
      #qp res['Location']
      #assert_match(/\Ahttp:/, res['Location'])
      @action.c_nredirect('t', 'http://e.com/')
      #ok_eq('http://e.com/', res['Location'])
    end

    def test_notice_generate
      template = @memory.template.get('notice')
      ok_eq([:h1], template.get_tag('h1'))
      ok_eq([:div, {:class=>'section'}],
	    template.get_by_class('section'))

      res = Qwik::Action.notice_generate(template, 'title', 'msg')
      ok_eq([:title, 'title'], res.get_tag('title'))
#      ok_eq([:script, {:src=>'.theme/js/base.js',
#		:type=>'text/javascript'}, ''], res.get_tag('script'))
      ok_eq([:meta, {:content=>'NOINDEX,NOFOLLOW', :name=>'ROBOTS'}],
	    res.get_tag('meta'))
      ok_eq([:h1, 'title'], res.get_tag('h1'))
      ok_eq([:div, {:class=>'section'}, 'msg'],
	    res.get_path('//div[@class="section"]'))
      ok_eq(nil, res.get_tag('meta[2]')) # not redirected

      template = @memory.template.get('notice')
      res = Qwik::Action.notice_generate(template, 'title', 'msg', 'url')
      ok_eq([:meta, {:content=>'0; url=url', 'http-equiv'=>'Refresh'}],
	    res.get_tag('meta[2]')) # redirected
    end
  end
end
