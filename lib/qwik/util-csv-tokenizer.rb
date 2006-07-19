# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

class CSVTokenizer
  def self.csv_split(source)
    status = :IN_FIELD
    csv = []
    last = ''
    csv << last

    while !source.empty?
      case status

      when :IN_FIELD
	case source
	when /\A'/
	  source = $'
	  last << "'"
	  status = :IN_QFIELD
	when /\A,/
	  source = $'
	  last = ''
	  csv << last
	when /\A(\\)/
	  source = $'
	when /\A([^,'\\]*)/ # anything else
	  source = $'
	  last << $1
	end

      when :IN_QFIELD
	case source
	when /\A'/
	  source = $'
	  last << "'"
	  status = :IN_FIELD
	when /\A(\\)/
	  source = $'
	  last << $1
	  status = :IN_ESCAPE
	when /\A([^'\\]*)/ # anything else
	  source = $'
	  last << $1
	end

      when :IN_ESCAPE
	if /\A(.)/ =~ source
	  source = $'
	  last << $1
	end
	status = :IN_QFIELD

      end
    end

    csv = csv.map {|a|
      a.strip
    }

    csv
  end
end

if $0 == __FILE__
  require 'test/unit'
  $test = true
end

if defined?($test) && $test
  class TestCSVTokenizer < Test::Unit::TestCase
    def ok(e, s)
      assert_equal e, CSVTokenizer.csv_split(s)
    end

    def test_csv
      # test basic
      ok(['1'], '1')
      ok(['1', ''], '1,')
      ok(['1', '2'], '1,2')
      ok(['1', '', '3'], '1,,3')

      # test from plugin
      ok(['a', 'b'], 'a,b')
      ok(["'a'", 'b'], "'a',b")
      ok(['a', 'b'], 'a, b')
      ok(['a', '', 'b'], 'a,,b')

      # test space
      ok(['1'], ' 1')
      ok(['1'], '1 ')
      ok(['1', '2'], '1, 2')
      ok(['1', '2'], "1,\n2")
      ok(['1', '2'], "1,\t2")
      ok(['1', '2'], "1,\\2")

      # test escape
      ok(["\"1\"\""], '"1""')

      # test IN_QFIELD
      ok(["'1'"], "'1'")
      ok(["'1 '"], "'1 '")
      ok(["'1,2'"], "'1,2'")
      ok(["\"1\""], "\"1\"")
      ok(["\"1\"", "\"2\""], "\"1\",\"2\"")
      ok(["\"1", "2\""], '"1,2"')

      # test with space
      ok(["'a b'"], "'a b'")
      ok(['a b'], 'a b')
    end
  end
end
