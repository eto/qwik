# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/common-notice'

module Qwik
  class Action
    def c_nerror(title=_('Error'), url=nil, status=500, &b)
     #status = 200 if @config.test
      msg = title
      msg = yield if block_given?
      generate_notice_page(status, title, url, msg)
    end

    def c_notfound(title=_('Not found.'), &b)
      return c_nerror(title, nil, 404, &b)
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestCommonError < Test::Unit::TestCase
    include TestSession

    def test_all
      res = session

      @action.c_nerror('c_notice_error title') { 'msg' }
      ok_eq(500, res.status)
      ok_title('c_notice_error title')

      @action.c_nerror
      ok_eq(500, res.status)
      ok_title('Error')

      @action.c_notfound('Not found') { 'msg' }
      ok_eq(404, res.status)
      ok_title('Not found')
    end
  end
end
