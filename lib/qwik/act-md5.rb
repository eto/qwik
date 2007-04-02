# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    def ext_md5
      c_require_page_exist
      c_set_status
      c_set_no_cache
      c_set_contenttype('text/plain')
      c_set_body(@site[@req.base].get.md5hex)
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActMD5 < Test::Unit::TestCase
    include TestSession

    def test_all
      t_add_user

      page = @site.create_new

      page.store ''
      res = session '/test/1.md5'
      eq 'd41d8cd98f00b204e9800998ecf8427e', res.body

      page.store '*t'
      res = session '/test/1.md5'
      eq '713c3323a56a1024e3638a96c031cf91', res.body
    end
  end
end
