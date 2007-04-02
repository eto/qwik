# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH << 'compat' unless $LOAD_PATH.include? 'compat'
begin
  require 'diff'
rescue LoadError
  require 'algorithm/diff'
end

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/util-string'
require 'qwik/htree-generator'

module Qwik
  class HTreeDiffHtmlGenerator
    def initialize(s1, s2)
      @s1 = s1.gsub(/\r/, "")
      @s2 = s2.gsub(/\r/, "")
    end

    def to_txt
      a1 = @s1.split("\n").collect! {|s| "#{s}\n"}
      a2 = @s2.split("\n").collect! {|s| "#{s}\n"}
      Diff.diff(a1, a2) 
    end

    def to_xml
      g = HTree::Generator.new
      src = @s1.split("\n").collect {|s| "#{s.escapeHTML}" }
      si = 0
      di = 0
      e = []
      to_txt.each {|action, position, elements|
        case action
        when :-
          while si < position
	    e << HTree::Text.new(src[si])
	    e << g.br
            si += 1
            di += 1
          end
          si += elements.length
          elements.each {|l|
            e << g.del{l.chomp}
	    e << g.br
	  }
        when :+
          while di < position
	    e << HTree::Text.new(src[si])
	    e << g.br
            si += 1
            di += 1
          end
          di += elements.length
          elements.each {|l|
            e << g.ins{l.chomp}
	    e << g.br
	  }
        end
      }
      while si < src.length
	e << HTree::Text.new(src[si])
	e << g.br
        si += 1
      end
      e
    end
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  require 'qwik/htree-format-xml'
  $test = true
end

if defined?($test) && $test
  class TestHTreeDiffHtmlGenerator < Test::Unit::TestCase
    def test_all
      dhg = Qwik::HTreeDiffHtmlGenerator.new('a', 'b')
      ok_eq([[:-, 0, ["a\n"]], [:+, 0, ["b\n"]]], dhg.to_txt)
      ok_eq("[{elem <del> {text a}}, {emptyelem <br>}, {elem <ins> {text b}}, {emptyelem <br>}]", dhg.to_xml.inspect)
    end
  end
end
