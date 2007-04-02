# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/act-text'

module Qwik
  class Action
    def plg_mail(from = '', time = nil)
      h2 = [:h2]
      h2 << plg_date(time) if time
      h2 << ' From: '+MailAddress.obfuscate(from)

      content = yield
      content = MailAddress.obfuscate_str(content)
      content = c_pre_text { content }

      ar = []
      ar << h2
      ar += content
      return ar
    end

    def plg_date(time_str = nil)
      return unless time_str.is_a?(String)

      if /\A\d+\z/ =~ time_str	# Only number.
	time = Time.at(time_str.to_i)
	date = time.strftime("%b #{time.day}, %Y")
	return [:span, {:class=>'date'}, date]
      elsif /\A\d\d\d\d\-\d\d\-\d\d\z/ =~ time_str	# 2005-04-19
	return [:span, {:class=>'date'}, time_str]
      end
      return
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActMail < Test::Unit::TestCase
    include TestSession

    def ok(e, w, user=DEFAULT_USER)	# assert_body_main
      assert_path(e, w, user, "//div[@class='body_main']")
    end

    def nu_test_mail_old
      ok([:div, {:class=>'day'}, [:h2, {:id=>'From'}, 'From:'],
	   [:div, {:class=>'body'},
	     [:div, {:class=>'section'}, [[:p, 'a']]]]],
	 "{{mail\na\n}}")
      ok([:div,
	   {:class=>'day'},
	   [:h2, {:id=>'From'}, 'From:'],
	   [:div,
	     {:class=>'body'},
	     [:div, {:class=>'section'}, [[:p, 'テストです。'], ["\n"]]]]],
	 "* テスト\n{{mail\nテストです。\n\n}}")
      ok([:div,
	   {:class=>'day'},
	   [:h2, {:id=>'979dff15c789fca0315256fc8af6fa64'}, 'From: t@e...'],
	   [:div, {:class=>'body'}, [:div, {:class=>'section'},
	       [[:p, 'ス'], ["\n"]]]]],
	 "* テ\n{{mail(t@e.com)\nス\n\n}}")
      ok([:div,
	   {:class=>'day'},
	   [:h2,
	     {:id=>'979dff15c789fca0315256fc8af6fa64'},
	     [:span, {:class=>'date'}, 'Jan 1, 1970'],
	     ' From: t@e...'],
	   [:div, {:class=>'body'}, [:div, {:class=>'section'},
	       [[:p, 'ス'], ["\n"]]]]],
	 "* テ\n{{mail(t@e.com,0)\nス\n\n}}")
      ok([:div,
	   {:class=>'day'},
	   [:h2, {:id=>'979dff15c789fca0315256fc8af6fa64'}, 'From: t@e...'],
	   [:div,
	     {:class=>'body'},
	     [:div, {:class=>'section'}, [[:p, 't@e...'], ["\n"]]]]],
	 "* テ\n{{mail(t@e.com)\nt@e.com\n\n}}")
    end

    def test_mail_new
      ok([:div, {:class=>'day'},
	   [:h2, {:id=>'From'}, ' From: '],
	   [:div, {:class=>'body'},
	     [:div, {:class=>'section'},
	       [[:p, 'a']]]]],
	 "{{mail\na\n}}")
      ok([:div, {:class=>'day'},
	   [:h2, {:id=>'From'}, ' From: '],
	   [:div, {:class=>'body'},
	     [:div, {:class=>'section'}, [[:p, 'テストです。'], ["\n"]]]]],
	 "* テスト\n{{mail\nテストです。\n\n}}")
      ok([:div, {:class=>'day'},
	   [:h2, {:id=>'979dff15c789fca0315256fc8af6fa64'}, ' From: t@e...'],
	   [:div, {:class=>'body'},
	     [:div, {:class=>'section'}, [[:p, 'ス'], ["\n"]]]]],
	 "* テ\n{{mail(t@e.com)\nス\n\n}}")
      ok([:div, {:class=>'day'},
	   [:h2, {:id=>'979dff15c789fca0315256fc8af6fa64'},
	     [:span, {:class=>'date'}, 'Jan 1, 1970'],
	     ' From: t@e...'],
	   [:div, {:class=>'body'},
	     [:div, {:class=>'section'}, [[:p, 'ス'], ["\n"]]]]],
	 "* テ\n{{mail(t@e.com,0)\nス\n\n}}")
      ok([:div, {:class=>'day'},
	   [:h2, {:id=>'979dff15c789fca0315256fc8af6fa64'}, ' From: t@e...'],
	   [:div, {:class=>'body'},
	     [:div, {:class=>'section'}, [[:p, 't@e...'], ["\n"]]]]],
	 "* テ\n{{mail(t@e.com)\nt@e.com\n\n}}")
      ok([:div, {:class=>'day'},
	   [:h2, {:id=>'979dff15c789fca0315256fc8af6fa64'},
	     [:span, {:class=>'date'}, 'Jan 1, 1970'], ' From: t@e...'],
	   [:div, {:class=>'body'},
	     [:div, {:class=>'section'}, [[:p, 'a', [:br], 'b']]]]],
	 "* Test\n{{mail(t@e.com,0)\na\nb\n}}")
    end

    def test_date
      ok_wi([:span, {:class=>'date'}, '2001-01-01'], '{{date(2001-01-01)}}')
      ok_wi([:span, {:class=>'date'}, 'Jan 1, 1970'], '{{date(0)}}')
      ok_wi([:span, {:class=>'date'}, 'Sep 9, 2001'], '{{date(1000000000)}}')
      ok_wi([], '{{date(a)}}')
    end

    def nu_test_all_old
      res = session
      ok_wi([:p, 'a ',
	      [:h2, 'From: a'], ' b'],
	    'a {{mail(a)}} b')
      ok_wi([:p, 'a ', [:span, {:class=>'date'}, 'Jan 1, 1970'], ' b'],
	    'a {{date(0)}} b')
      ok_wi([:p, 'a ',
	      [:h2, [:span, {:class=>'date'}, 'Jan 1, 1970'], ' From: a'],
	      ' b'],
	    'a {{mail(a,0)}} b')
    end

    def test_all_new
      res = session
      ok_wi([:p, 'a ',
	      [:h2, ' From: a'], ' b'],
	    'a {{mail(a)}} b')
      ok_wi([:p, 'a ', [:span, {:class=>'date'}, 'Jan 1, 1970'], ' b'],
	    'a {{date(0)}} b')
      ok_wi([:p, 'a ',
		[:h2, [:span, {:class=>'date'}, 'Jan 1, 1970'], ' From: a'],
	      ' b'],
	    'a {{mail(a,0)}} b')
    end
  end
end
