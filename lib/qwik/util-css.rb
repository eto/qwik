# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

class CSS
  INHIBIT_PATTERN = %w(
@i
\\
javascript
vbscript
cookie
eval
expression
behavior
behaviour
binding
include-source
)

  def self.valid?(str)
    INHIBIT_PATTERN.each {|c|
      return false if str.include?(c)
    }
    return true
  end
end

if $0 == __FILE__
  require 'test/unit'
  $test = true
end

if defined?($test) && $test
  class TestCSS < Test::Unit::TestCase
    def valid(s)
      assert_equal true, CSS.valid?(s)
    end

    def invalid(s)
      assert_equal false, CSS.valid?(s)
    end

    def test_all
      valid   'h2 { color: red }'
      invalid "@import"
      invalid "\\important"
      valid   ''
      valid   'text-align:center;'
      valid   'ok@style'
      valid   'ok.style'
      invalid '@i'
    end
  end
end
