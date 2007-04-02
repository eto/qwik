# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

# Under construction.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    # ==============================
    def notyet_plg_calendar
      return 'calendar'
    end

    # ==============================
    def notyet_plg_draw
      return [:div, 
	[:'v:line', {:from=>'0, 100', :to=>'200, 200'}, '']]
    end

    # ==============================
    def notyet_plg_extlink
      w = []
      w << [:script, {:type=>'text/javascript',
	  :src=>'.theme/ap/ArekorePopup.js'}, '']
      w << [:script, {:type=>'text/javascript'}, '
AP.launch;
']
      return []
    end

    # ==============================
    # 'Go Back to Work.' plugin
    # Inspired from http://www.marktaw.com/getbacktowork.htm
    def notyet_plg_go_back_to_work
      return [:strong, 'hello, world!']
    end

    def notyet_ext_go_back_to_work
      c_notice('hello, world!'){'hi, there.'}
    end

    # ==============================
    def notyet_ext_print
      ext_html	# call this first.
      return c_nerror('not yet')
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActTmp < Test::Unit::TestCase
    include TestSession

    def notyet_test_plg_calendar
    end

    def notyet_test_plg_draw
    end

    def notyet_test_extlink
      ok_wi([], '{{extlink}}')
    end

    def test_gbtw
      t_add_user

      res = session

      page = @site.create_new
      page.store('{{go_back_to_work}}')
      res = session('/test/1.html')
      #ok_xp({:action=>'1.go_back_to_work', :method=>'POST'}, 'div[@class='main']')

      res = session('POST /test/1.go_back_to_work?work=n&style=0')
      #assert_match(/ ''\[\[n\]\]'' : m\n\{\{hcomment\}\}/, page.load)
    end

    def test_ext_print
      t_add_user
      page = @site.create_new
      page.store('t')
      res = session('/test/1.html')
      ok_xp([:div, {:class=>'body'}, [:div, {:class=>'section'}, [[:p, 't']]]],
	    "//div[@class='body']")
    end
  end
end
