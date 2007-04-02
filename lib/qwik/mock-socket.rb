# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/util-safe'

module QuickML
  class MockSocket
    include SafeGetsModule

    def initialize(str = '')
      require 'stringio'
      @inputs = StringIO.new(str)
      @buffer = []
    end
    attr_reader :buffer

    def result
      ar = []
      @buffer.each {|res|
	ar << res.sub(/\r\n\z/, "")
      }
      return ar
    end

    def hostname
      return 'localhost'
    end

    def address
      return '127.0.0.1'
    end

    def eof?
      return @inputs.eof?
    end

    def closed?
      return @inputs.eof?
    end

    def close
      # Do nothing.
    end

    def print(*args)
      str = args.join
      @buffer << str
    end

    def read(len)
      @inputs.read(len)
    end

    alias org_safe_gets safe_gets
    def safe_gets
      line = org_safe_gets
      return nil if line.nil?
      line = line.xchomp+"\r\n"
      return line
    end
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  $test = true
end

if defined?($test) && $test
  class TestMockSocket < Test::Unit::TestCase
    def test_all
      # test_initialize
      s = QuickML::MockSocket.new('')

      # test_print
      s.print('t')
      is ['t'], s.buffer
    end
  end
end
