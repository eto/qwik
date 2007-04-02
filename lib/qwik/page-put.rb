# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/util-string'

module Qwik
  class Page
    def put(v)
      return @db.put(@key, v)
    end
    alias store put

    def put_with_time(v, time)
      @db.put(@key, v, time)
    end

    def put_with_md5(v, md5)
      if md5 && self.get.md5hex != md5
	raise PageCollisionError
      end
      put(v)
    end

    def add(v)
      str = self.get
      addstr = ''

      # FIXME: Use normalize_eol?
      if ! (str.empty? || str[-1] == ?\n)
	addstr += "\n"
      end

      addstr += v

      if !(v.empty? || v[-1] == ?\n)
	addstr += "\n"
      end

      @db.add(@key, addstr)
    end

    def delete
      @db.delete(@key)
      # @pages.delete(@key)
    end

    def touch
      @db.touch(@key)
    end

  end
end

if $0 == __FILE__
  require 'qwik/farm'
  require 'qwik/server-memory'
  require 'qwik/test-module-session'
  $test = true
end

if defined?($test) && $test
  class TestPagePut < Test::Unit::TestCase
    include TestSession

    def test_all
      pages = @site.get_pages
      page = pages.create_new

      # test_put
      page.put('test1')
      page.store('test1')
      ok_eq('test1', page.get)

      # test_put_with_time
      page.put_with_time('test1', 0)
      ok_eq(0, page.mtime.to_i)

      # test_put_with_md5
      page.put('t1')
      assert_raises(Qwik::PageCollisionError) {
	page.put_with_md5('t1', 'somethingwrong')
      }
      md5 = page.get.md5hex
      page.put_with_md5('t2', md5)
      ok_eq('t2', page.get)

      # test_add
      page.add('t3')
      ok_eq("t2\nt3\n", page.get)

      # test_mtime_with_nonexistent_page
      assert_instance_of(Time, pages.last_page_time)

      page = pages['1']
      page.put('* a')
      assert_instance_of(Time, page.mtime)
      assert_instance_of(Time, pages.last_page_time)

      page.delete
      assert_instance_of(Time, page.mtime)
      assert_instance_of(Time, pages.last_page_time)
      ok_eq(0, page.mtime.to_i)
    end

    def test_add
      pages = @site.get_pages
      page = pages.create_new

      page.put('t1')
      page.add('t2')
      ok_eq("t1\nt2\n", page.get)

      page.put('')
      page.add('t2')
      ok_eq("t2\n", page.get)

      page.put('t1')
      page.add('')
      ok_eq("t1\n", page.get)

      page.delete
      page.add('')
      ok_eq('', page.get)
    end
  end
end
