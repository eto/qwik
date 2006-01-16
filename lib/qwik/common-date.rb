#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '../../lib' unless $LOAD_PATH.include?('../../lib')
require 'qwik/util-time'

module Qwik
  class Action
    def self.date_parse(tag)
      if /\A(\d\d\d\d)-(\d\d)-(\d\d)\z/ =~ tag
	return Time.local($1.to_i, $2.to_i, $3.to_i)
      end
      return nil
    end

    def self.date_abbr(now, date)
      year  = date.year
      month = date.month
      mday  = date.mday
      return date.ymd if now.year != date.year
      return date.md
    end

    def self.date_emphasis(now, date, title)
      diff = date - now
      day = 60*60*24
      if diff < -day	# past
	return [:span, {:class=>'past'}, title]
      elsif diff < day*7	# This week.
	return [:strong, title]
      elsif diff < day*30	# This month.
	return [:em, title]
      else
	return [:span, {:class=>'future'}, title]
      end
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActDate < Test::Unit::TestCase
    include TestSession

    def test_all
      # test_date_parse
      time = Qwik::Action.date_parse('1970-01-01')
      ok_eq(-32400, time.to_i)

      # test_date_abbr
      now = Time.local(1970, 1, 1)
      t2 = Time.local(1970, 1, 2)
      abbr = Qwik::Action.date_abbr(now, t2)
      ok_eq('01-02', abbr)

      t2 = Time.local(1971, 1, 1)
      abbr = Qwik::Action.date_abbr(now, t2)
      ok_eq('1971-01-01', abbr)

      # test_date_emphasis
      now = Time.local(1970, 2, 1)
      past = Time.local(1970, 1, 30)
      span = Qwik::Action.date_emphasis(now, past, 't')
      ok_eq([:span, {:class=>'past'}, 't'], span)

      tomorrow = Time.local(1970, 2, 2)
      span = Qwik::Action.date_emphasis(now, tomorrow, 't')
      ok_eq([:strong, 't'], span)

      nextweek = Time.local(1970, 2, 9)
      span = Qwik::Action.date_emphasis(now, nextweek, 't')
      ok_eq([:em, 't'], span)

      nextmonth = Time.local(1970, 3, 3)
      span = Qwik::Action.date_emphasis(now, nextmonth, 't')
      ok_eq([:span, {:class=>'future'}, 't'], span)
    end
  end
end
