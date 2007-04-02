# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/bench-module-session'
require 'qwik/test-common'

class BenchEmode < Test::Unit::TestCase
  include TestSession

  def copy_all
    pages = []
    src  = @org_sites_dir.path+'eto.com'
    dest = @dir
    return nil unless src.exist?
    src.each_entry {|file|
      if /\A\d\d\d\d\.txt\z/ =~ file.to_s
	str = (src+file).read
	(dest+file).put(str)
	base = file.to_s.sub('.txt', '')
	pages << base
      end
    }
    pages
  end

  def nutest_0008
    copy_all
    t_add_user
    session('/test/0008.html')
    body = @res.body.format_xml
  end

  def test_bench000
    repeat = 10
    pages = copy_all
    return if pages.nil?
    t_add_user
    repeat.times {
      pages.each {|base|
	session("/test/#{base}.html")
	body = @res.body.format_xml
      }
    }
  end
end
