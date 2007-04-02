# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH << 'compat' unless $LOAD_PATH.include? 'compat'
require 'htree'

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module HTree
  module Node
    def format_xml(i=-1)
      str = ''
      display_xml(str)
      str.gsub!(%r! xmlns=\"http://www.w3.org/1999/xhtml\"!, "")
      str.gsub!(%r! xmlns=\"\"!, "")
      if i < 0
	str.gsub!(/\n>/, ">")
	str.gsub!(/\n\/>/, "/>")
      end
      str
    end
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  $test = true
end

if defined?($test) && $test
  class TestHTree_format_xml < Test::Unit::TestCase
    def ok(e, s)
      ok_eq(e, s.format_xml)
    end

    def test_all
      # check_extract_text
      e = HTree::Elem.new('a', 't')
      ok("<a>t</a>", e)
      ok_eq('t', e.extract_text.to_s)

      e = HTree::Elem.new('b', 's', e, 'u')
      ok("<b>s<a>t</a>u</b>", e)
      ok_eq('stu', e.extract_text.to_s)

      # test_htree_format_xml
      e = HTree::Elem.new('a')
      ok_eq("<a/>", e.format_xml)
      ok_eq("<a\n/>", e.format_xml(0))

      e = HTree::Text.new('a')
      ok_eq('a', e.format_xml)
      ok_eq('a', e.format_xml(0))
    end
  end
end
