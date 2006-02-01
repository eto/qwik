#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'

module Qwik
  class CSS
    INHIBIT_PATTERN = %w(@i \\ javascript vbscript cookie eval expression behavior behaviour binding include-source)

    def self.valid?(str)
      INHIBIT_PATTERN.each {|c|
	return false if str.include?(c)
      }
      return true
    end
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  $test = true
end

if defined?($test) && $test
  class TestCSS < Test::Unit::TestCase
    def ok(e, s)
      ok_eq(e, Qwik::CSS.valid?(s))
    end

    def test_all
      ok(true,  'h2 { color: red }')
      ok(false, "@import\n}}")
      ok(false, "\\important")
      ok(true,  '')
      ok(true,  'text-align:center;')
      ok(true,  'ok@style')
      ok(true,  'ok.style')
      ok(false, '@i')
    end
  end
end
