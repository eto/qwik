# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

# modified from hiki/command.rb

require 'timeout'

$LOAD_PATH << 'compat' unless $LOAD_PATH.include? 'compat'
require 'diff'

$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'
require 'qwik/util-string'

class DiffGenerator
  def self.gen_ary(s1, s2)
    s1 = s1.gsub(/\r/, '')
    s2 = s2.gsub(/\r/, '')
    a1 = s1.split("\n").collect! {|s| "#{s}\n"}
    a2 = s2.split("\n").collect! {|s| "#{s}\n"}
    Diff.diff(a1, a2) 
  end

  MAX_TIME = 60		# 1 minute

  def self.generate(s1, s2)
    result = nil
    begin
      Timeout.timeout(MAX_TIME) {
	result = generate_internal(s1, s2)
      }
    rescue Timeout::Error
      return []
    end
    result
  end

  def self.generate_internal(s1, s2)
    s1 = s1.gsub(/\r/, '')
    s2 = s2.gsub(/\r/, '')

    # why?
    #src = s1.split("\n").collect {|s| "#{s.escapeHTML}" }
    #src = s1
    src = s1.split("\n").collect {|s| s }

    si = 0
    di = 0
    e = []
    self.gen_ary(s1, s2).each {|action, position, elements|
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

if $0 == __FILE__
  require 'qwik/testunit'
  $test = true
end

if defined?($test) && $test
  class TestDiffGenerator < Test::Unit::TestCase
    def test_all
      # check_diff
      is "[[:+, 1, \"t\"]]", Diff.diff('t', 'tt').inspect
      is "[[:-, 1, \"t\"]]", Diff.diff('tt', 't').inspect

      curstr = "a
b
c
"
      newstr = "a
z
c
"

      # test_gen_ary
      is [[:-, 0, ["t\n"]], [:+, 0, ["tt\n"]]],
	DiffGenerator.gen_ary('t', 'tt')
      is [[:-, 1, ["z\n"]], [:+, 1, ["b\n"]]],
	DiffGenerator.gen_ary(newstr, curstr)

      # test_generate
      is [[:del, 't'], [:br], [:ins, 'tt'], [:br]],
	DiffGenerator.generate('t', 'tt')
      is ['a', [:br], [:del, 'z'], [:br],
	[:ins, 'b'], [:br], 'c', [:br]],
	DiffGenerator.generate(newstr, curstr)
    end
  end
end
