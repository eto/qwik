#
# Copyright (C) 2002-2004 Satoru Takabayashi <satoru@namazu.org> 
# Copyright (C) 2003-2006 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

#class TooLongLine < StandardError; end
class TooLongLine < Exception; end	# FIXME: should be StandardError.

module SafeGetsModule
  def safe_gets (max_length = 1024)
    s = ''
    while ! self.eof?
      c = self.read(1)		# FIXME: This code may be slow.
      s << c

      if max_length < s.length
	raise TooLongLine
      end

      if c == "\n"
	return s
      end
    end

    res = if s.empty? then nil else s end
    return res
  end
end

class IO
  include SafeGetsModule
end

if $0 == __FILE__
  require 'test/unit'
  require 'stringio'
  $test = true
end

if defined?($test) && $test
  class StringIO
    include SafeGetsModule
  end

  class TestUtilSafe < Test::Unit::TestCase
    def test_safe_gets
      # under max
      line = 'a' * 1024
      assert_equal line, StringIO.new(line).gets
      assert_equal line, StringIO.new(line).safe_gets

      # over max
      line = 'a' * 1025
      assert_equal line, StringIO.new(line).gets
      assert_raise(TooLongLine) {
	assert_equal line, StringIO.new(line).safe_gets
      }
    end
  end
end
