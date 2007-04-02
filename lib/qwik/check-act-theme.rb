# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/test-common'
require 'qwik/act-theme'

class CheckExternalCss < Test::Unit::TestCase
  include TestSession

  def test_all
    return if $0 != __FILE__		# Only for separated test.

    # test_extcss_nosuch
    res = session '/.css/http://nosuchhostname/q.css'
    ok_title 'Access Failed'

    # test_extcss_hatena
    res = session '/.css/http://d.hatena.ne.jp/theme/clover/clover.css'
    if @res.body.is_a?(Array)
      ok_title 'Access Failed'
    else
      #eq true, 1000 < @res.body.length
    end
  end
end
