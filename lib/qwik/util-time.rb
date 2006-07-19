# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

require 'parsedate'

class Time
  def md
    return strftime('%m-%d')	# 01-01
  end

  def ymd_s
    return strftime('%Y%m%d')	# 20000101
  end

  def ymd
    return strftime('%Y-%m-%d')	# 2000-01-01
  end

  def ymdx
    return strftime('%Y-%m-%d %X')	# 2000-01-01 12:34:56
  end

  def ymdax
    return strftime("%Y-%m-%d(%a) %X")	# 2000-01-01(Sat) 12:34:56
  end

  def format_date
    day = %w(“ú Œ ‰Î … –Ø ‹à “y)	# 2000-01-01 (“y) 12:34:56
    return strftime("%Y-%m-%d #DAY# %H:%M:%S").sub(/#DAY#/, "(#{day[wday]})")
  end

  def rfc1123_date
    return strftime('%a, %d %b %Y %H:%M:%S GMT') # Sat, 01 Jan 2000 12:34:56 GMT
  end

  def rfc_date
    return strftime('%Y-%m-%dT%H:%M:%S')	# 2000-01-01T12:34:56
  end

  # ============================== date
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

if $0 == __FILE__
  require 'test/unit'
  $test = true 
end

if defined?($test) && $test
  class TestUtilTime < Test::Unit::TestCase
    def test_time
      t = Time.gm(2000, 1, 1, 12, 34, 56)
      assert_equal '01-01', t.md
      assert_equal '20000101', t.ymd_s
      assert_equal '2000-01-01', t.ymd
      assert_equal '2000-01-01 12:34:56', t.ymdx
      assert_equal "2000-01-01(Sat) 12:34:56", t.ymdax
      assert_equal "2000-01-01 (“y) 12:34:56", t.format_date
      assert_equal 'Sat, 01 Jan 2000 12:34:56 GMT', t.rfc1123_date
      assert_equal '2000-01-01T12:34:56', t.rfc_date
    end
  end

  def test_date
    # test_date_parse
    time = Time.date_parse('1970-01-01')
    assert_equal(-32400, time.to_i)

    # test_date_abbr
    now = Time.local(1970, 1, 1)
    t2 = Time.local(1970, 1, 2)
    abbr = Time.date_abbr(now, t2)
    assert_equal '01-02', abbr

    t2 = Time.local(1971, 1, 1)
    abbr = Time.date_abbr(now, t2)
    assert_equal '1971-01-01', abbr

    # test_date_emphasis
    now = Time.local(1970, 2, 1)
    past = Time.local(1970, 1, 30)
    span = Time.date_emphasis(now, past, 't')
    assert_equal [:span, {:class=>'past'}, 't'], span

    tomorrow = Time.local(1970, 2, 2)
    span = Time.date_emphasis(now, tomorrow, 't')
    assert_equal [:strong, 't'], span

    nextweek = Time.local(1970, 2, 9)
    span = Time.date_emphasis(now, nextweek, 't')
    assert_equal [:em, 't'], span

    nextmonth = Time.local(1970, 3, 3)
    span = Time.date_emphasis(now, nextmonth, 't')
    assert_equal [:span, {:class=>'future'}, 't'], span
  end
end
