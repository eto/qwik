#
# Copyright (C) 2002-2004 Satoru Takabayashi <satoru@namazu.org> 
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'

class TooLongLine < Exception; end

module SafeGetsModule
  def safe_gets (max_length = 1024)
    s = ''
    while ! self.eof?
      c = self.read(1)
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
  require 'qwik/testunit'
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
      ok_eq(line, StringIO.new(line).gets)
      ok_eq(line, StringIO.new(line).safe_gets)

      # over max
      line = 'a' * 1025
      ok_eq(line, StringIO.new(line).gets)
      assert_raise(TooLongLine) {
	ok_eq(line, StringIO.new(line).safe_gets)
      }
    end
  end
end
