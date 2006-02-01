#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    def c_set_status(status=200)
      @res.status = status
    end

    def c_set_contenttype(contenttype="text/html; charset=Shift_JIS")
      @res['Content-Type'] = contenttype
    end
    alias c_set_html c_set_contenttype

    def c_set_no_cache(pragma='no-cache', control='no-cache')
      @res['Pragma'] = pragma
      @res['Cache-Control'] = control
    end

    def c_set_body(body)
      @res.body = body
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActResponse < Test::Unit::TestCase
    include TestSession

    def test_all
      res = session

      # test_c_set_status
      @action.c_set_status(7743)
      ok_eq(7743, res.status)

      # test_c_set_contenttype
      @action.c_set_contenttype
      ok_eq("text/html; charset=Shift_JIS", res['Content-Type'])

      # test_c_set_no_cache
      @action.c_set_no_cache
      ok_eq('no-cache', res['Pragma'])
      ok_eq('no-cache', res['Cache-Control'])

      # test_c_set_body
      @action.c_set_body('body')
      ok_eq('body', res.body)
    end
  end
end
