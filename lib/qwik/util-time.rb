#
# Copyright (C) 2003-2006 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

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
    return strftime("%Y-%m-%d #DAY# %H:%M:%S").sub(/#DAY#/, "("+day[wday]+")")
  end

  def rfc1123_date
    return strftime('%a, %d %b %Y %H:%M:%S GMT') # Sat, 01 Jan 2000 12:34:56 GMT
  end

  def rfc_date
    return strftime('%Y-%m-%dT%H:%M:%S')	# 2000-01-01T12:34:56
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  $test = true 
end

if defined?($test) && $test
  class TestUtilTime < Test::Unit::TestCase
    def test_time
      t = Time.gm(2000, 1, 1, 12, 34, 56)
      ok_eq('01-01', t.md)
      ok_eq('20000101', t.ymd_s)
      ok_eq('2000-01-01', t.ymd)
      ok_eq('2000-01-01 12:34:56', t.ymdx)
      ok_eq("2000-01-01(Sat) 12:34:56", t.ymdax)
      ok_eq("2000-01-01 (“y) 12:34:56", t.format_date)
      ok_eq('Sat, 01 Jan 2000 12:34:56 GMT', t.rfc1123_date)
      ok_eq('2000-01-01T12:34:56', t.rfc_date)
    end
  end
end
