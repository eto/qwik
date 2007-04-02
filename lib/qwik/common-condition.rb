# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    # ========== error check
    def c_login?
      return @req.user
    end

    def c_require_login # You must logged in.
      raise RequireLogin unless c_login?
    end

    def c_member?
      c_login? && @site.member.exist?(@req.user)
    end

    def c_require_member # You must be a member of this group.
      raise RequireMember unless c_member?
    end

    def c_require_post
      raise RequirePost unless @req.is_post?
    end

    def c_require_page_exist
      raise PageNotFound if @site[@req.base].nil?
    end

    def c_require_no_path_args
      raise RequireNoPathArgs if 0 < @req.path_args.length
    end

    def c_require_no_ext_args
      raise 'no ext args' if 0 < @req.ext_args.length
    end

    def c_require_pagename
      raise 'pagename is nil' if @req.base.nil?
      # FIXME: But, pagename is always not nil for now.
    end

    def c_require_base_is_sitename
      raise BaseIsNotSitename if @req.base != @req.sitename
    end

    def c_require_lib(lib)
      begin
	require lib
      rescue
	raise "there is no #{lib} library"
      end
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActCondition < Test::Unit::TestCase
    include TestSession

    def test_condition
      res = session

      # test_c_login
      ok_eq(true, !!@action.c_login?)

      # test_c_require_login
      @action.c_require_login # ok, nothing happen.

      # test_c_member
      ok_eq(false, @action.c_member?)

      # test_c_require_member
      assert_raise(Qwik::RequireMember) {
	@action.c_require_member
      }

      t_add_user

      # test_c_member, again
      ok_eq(true, @action.c_member?)

      # test_c_require_member, again
      @action.c_require_member # nothing happen

      # test_c_require_post
      res = session {|req|
	ok_eq(false, req.is_post?)
      }
      assert_raise(Qwik::RequirePost) {
	@action.c_require_post
      }
      res = session('POST /test/1.html')
      @action.c_require_post # nothing happen

      # test_c_require_page_exist
      res = session('/test/1.html') {|req|
	ok_eq(nil, @site[req.base])
      }
      assert_raise(Qwik::PageNotFound) {
	@action.c_require_page_exist
      }

      # test_c_require_no_path_args
      res = session('/test/1.html/1') {|req|
	ok_eq(['1'], req.path_args)
      }
      assert_raise(Qwik::RequireNoPathArgs) {
	@action.c_require_no_path_args
      }

      # test_c_require_no_ext_args
      res = session('/test/1.t.html') {|req|
	ok_eq(['t'], req.ext_args)
      }
      assert_raise(RuntimeError) {
	@action.c_require_no_ext_args
      }

      # test_c_require_pagename
      # FIXME: Pagename is always not nil for now.

      # test_c_require_base_is_sitename
      res = session('/test/1.t.html') {|req|
	ok_eq(['t'], req.ext_args)
      }
      assert_raise(RuntimeError) {
	@action.c_require_no_ext_args
      }

    end
  end
end
