#
# Copyright (C) 2003-2006 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

# modified from hiki/command.rb

$LOAD_PATH << 'compat' unless $LOAD_PATH.include? 'compat'
require 'diff'
$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'
require 'qwik/util-string'

module Qwik
  class DiffGenerator
    def self.generate_array(s1, s2)
      s1 = s1.gsub(/\r/, "")
      s2 = s2.gsub(/\r/, "")
      a1 = s1.split("\n").collect! {|s| "#{s}\n"}
      a2 = s2.split("\n").collect! {|s| "#{s}\n"}
      Diff.diff(a1, a2) 
    end

    def self.generate(s1, s2)
      s1 = s1.gsub(/\r/, "")
      s2 = s2.gsub(/\r/, "")

      # why?
      #src = s1.split("\n").collect {|s| "#{s.escapeHTML}" }
      #src = s1
      src = s1.split("\n").collect {|s| s }

      si = 0
      di = 0
      e = []
      self.generate_array(s1, s2).each {|action, position, elements|
        case action
        when :-
          while si < position
	    e << src[si]
	    e << [:br]
            si += 1
            di += 1
          end
          si += elements.length
          elements.each {|l|
            e << [:del, l.chomp]
	    e << [:br]
	  }
        when :+
          while di < position
	    e << src[si]
	    e << [:br]
            si += 1
            di += 1
          end
          di += elements.length
          elements.each {|l|
            e << [:ins, l.chomp]
	    e << [:br]
	  }
        end
      }
      while si < src.length
	e << src[si]
	e << [:br]
        si += 1
      end
      e
    end
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  $test = true
end

if defined?($test) && $test
  class TestDiffGenerator < Test::Unit::TestCase
    def test_all
      # check_diff
      ok_eq("[[:+, 1, \"t\"]]", Diff.diff('t', 'tt').inspect)
      ok_eq("[[:-, 1, \"t\"]]", Diff.diff('tt', 't').inspect)

      newstr = "a\nz\nc\n"
      curstr = "a\nb\nc\n"

      # test_generate_array
      a = Qwik::DiffGenerator.generate_array('t', 'tt')
      ok_eq([[:-, 0, ["t\n"]], [:+, 0, ["tt\n"]]], a)

      a = Qwik::DiffGenerator.generate_array(newstr, curstr)
      ok_eq([[:-, 1, ["z\n"]], [:+, 1, ["b\n"]]], a)

      # test_generate
      r = Qwik::DiffGenerator.generate('t', 'tt')
      ok_eq([[:del, 't'], [:br], [:ins, 'tt'], [:br]], r)

      r = Qwik::DiffGenerator.generate(newstr, curstr)
      ok_eq(['a', [:br], [:del, 'z'], [:br],
	      [:ins, 'b'], [:br], 'c', [:br]],
	    r)
    end
  end
end
