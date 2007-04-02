# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    def plg_text
      str = yield
      return c_res(str)
    end

    def plg_pre_text
      str = yield
      return c_pre_text { str }
    end

    def c_pre_text
      str = yield
      tokens = TextTokenizer.tokenize(str, true)
      tree = TextParser.make_tree(tokens)
      w = Resolver.resolve(@site, self, tree)
      return w
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActText < Test::Unit::TestCase
    include TestSession

    def ok_day(e, w, user=DEFAULT_USER)
      assert_path(e, w, user, "//div[@class='day']")
    end

    def test_plg_text
      ok_day([[:h2, {:id=>'8f03c3a6dbec1d0f1a5af60947b7b052'}, '‚ '],
	       [:div, {:class=>'body'}, [:div, {:class=>'section'}, []]]],
	     "{{text\n* ‚ \n}}")
      ok_day([[:h2, {:id=>'7657b04993b557a2ee9b36bf280a3ec4'}, '‚¢'],
	       [:div, {:class=>'body'}, [:div, {:class=>'section'}, []]]],
	     "{{text\n* ‚¢\n}}")
      ok_wi([:p, '<'], "{{text\n<\n}}")
      @site['1'].delete
      @site.erase_all
      ok_wi([[:dl, [:dt, 'dt1'], [:dd, 'dd1']],
	      [:p, 'p1'], [:dl, [:dd, 'dd2']]],
	    "{{text\n:dt1:dd1\np1\n::dd2\n}}")
    end

    def test_c_pre_text
      res = session
      ok_eq([[:p, 'a']], @action.c_pre_text { 'a' })
      ok_eq([[:br]], @action.c_pre_text { '{{br}}' })
      ok_eq([[:div, {:class=>'ref'},
		[:a, {:href=>'FrontPage.files/a.jpg'},
		  [:img, {:src=>'.theme/i/broken.gif',
		      :class=>'icon', :alt=>'a.jpg'}],
		  [:br],
		  'a.jpg']]],
	    @action.c_pre_text { '{{file(a.jpg)}}' })
    end
  end
end
