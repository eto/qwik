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
end
