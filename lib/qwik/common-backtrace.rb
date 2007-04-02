# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    # Only for demonstration for the PrettyBacktrace function.
    def plg__qwik_test_for_raise_exception
      no_such_local_variable
    end
  end

  class PrettyBacktrace
    MARGIN = 10
    POS_NUM = 3
    MIN_MARGIN = -1

    def self.to_html(e)
      margin = MARGIN
      trs = e.backtrace.map {|str|
	sf, sl, method = str.split(':', 3)
	margin -= 1
	[[:tr,
	    [:td, {:class=>'file'}, get_pos(sf, sl)+':', [:strong, sl]],
	    [:td, {:class=>'method'}, method.to_s]],
	  [:tr,
	    [:td, {:class=>'excerpt', :colspan=>'3'},
	      get_excerpt(sf, sl.to_i, margin)]]]
      }
      return [[:h3, e.to_s], [:table, {:class=>'exception'}, trs]]
    end

    def self.get_pos(sourcefile, sourceline)
      ar = sourcefile.split('/')
      ar = ar[-POS_NUM, POS_NUM] if POS_NUM < ar.length
      return ar.join('/')
    end

    def self.get_excerpt(file, linenum, margin)
      margin = MIN_MARGIN if margin < MIN_MARGIN
      return '' if margin < 0
      f = file.path
      return '' unless f.exist?
      str = f.read
      b = linenum - margin - 1		# beginning
      ar = str.to_a[b, margin*2+1]

      table = []
      ar.each_with_index {|line, num|
	line = " \n" if line == "\n"	# only for visual effect
	n = b + num + 1
	attr = {:class=>'even'}
	attr = {:class=>'odd'} if n % 2 == 1
	attr = {:class=>'target'} if n == linenum
	table << [:tr, attr, [:th, n.to_s], [:td, [:pre, line]]]
      }
      return [:table, table]
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActException < Test::Unit::TestCase
    include TestSession

    def test_all
      t_add_user

      # test_backtrace
      page = @site.create_new
      page.store('{{nosuch}}')
      res = session('/test/1.html')
      ok_in [:span, {:class=>"plg_error"}, "nosuch plugin | ",
	[:strong, "nosuch"]], '//div[@class="section"]'
      eq [:div, {:class=>"section"},
	[[:span, {:class=>"plg_error"}, "nosuch plugin | ",
	    [:strong, "nosuch"]]]],
	@res.body.get_path('//div[@class="section"]')

      t_without_testmode {
	page.store '{{_qwik_test_for_raise_exception}}'
	res = session '/test/1.html'
	assert_text(/\Aundefined local variable or method `no_such_local_variable' for #<Qwik::Action:/, 'h3')
      }
    end
  end
end
