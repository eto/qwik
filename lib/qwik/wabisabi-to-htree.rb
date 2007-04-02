# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH << 'compat' unless $LOAD_PATH.include? 'compat'
require 'htree'
$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/htree-generator'

module HTree
  module WabisabiModule
    include GeneratorModule

    def generate(xml)
      return xml if xml.is_a?(String)
      return xml if xml.is_a?(Hash)
      return xml if xml.is_a?(Elem)
      if xml.is_a?(Array) && xml.length == 1 && xml[0].is_a?(Elem)
	return xml[0]
      end

      offset  = 1
      element = xml.shift.to_s

      attributes_ar = []
      while xml.first.is_a?(Hash)
	attr = xml.shift
	attributes_ar << attr
      end

      if xml.empty?
	return make(element, *attributes_ar)
      end

      ar = xml.map {|i|
	generate(i) # recursive
      }
      return make(element, *attributes_ar){ar}
    end
  end

  # make a htree from a wabisabi
  class WabisabiGenerator
    include WabisabiModule

    def to_htree(sar)
      if sar.first.is_a?(Symbol)
	generate(sar)
      else
	sar = sar.map {|a| generate(a) }
	sar
      end
    end
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  require 'qwik/htree-format-xml'
  $test = true
end

if defined?($test) && $test
  class TestHTreeWabisabi < Test::Unit::TestCase
    include HTree::WabisabiModule

    def ok(e, xml)
      ok_eq(e, generate(xml).format_xml(0))
    end

    def ok_in(e, s)
      ok_eq(e, s.format_xml)
    end

    def test_all
      ok("<a\n/>", [:a])
      ok("<a href=\"foo.html\"\n/>", [:a, {:href=>"foo.html"}])
      ok("<a\n><b\n/></a\n>", [:a, [:b]])
      ok("<html\n><body\n><p\n><a href=\"foo.html\"\n>foo</a\n></p\n></body\n></html\n>", [:html, [:body, [:p, [:a, {:href => "foo.html"}, 'foo']]]])
      @g = HTree::Generator.new
      ok("<a\n><b\n/></a\n>", [:a, @g.b])

      # test_multi_attr
      ok("<a href=\"foo.html\"\n/>", [:a, {:href=>"foo.html"}])
      ok("<a href=\"foo.html\" class=\"bar\"\n/>",
	 [:a, {:href=>'foo.html', :class=>'bar'}])
      ok("<a href=\"foo.html\" class=\"bar\"\n/>",
	 [:a, {:href=>'foo.html'}, {:class=>'bar'}])

      # test_to_htree
      g = HTree::WabisabiGenerator.new
      ok_in("<a/>", g.to_htree([:a]))
      ok_in("<a/>", HTree::WabisabiGenerator.new.to_htree([:a]))
    end
  end

  class TestHTreeWabisabiObject < Test::Unit::TestCase
    include HTree::WabisabiModule

    def ok(e, xml)
      ok_eq(e, generate(xml).inspect)
    end

    def test_all
      ok("{emptyelem <a>}", [:a])
      ok("{emptyelem <a href=\"foo.html\">}", [:a, {:href=>"foo.html"}])
      ok("{elem <a> {emptyelem <b>}}", [:a, [:b]])
      ok("{elem <html> {elem <body> {elem <p> {elem <a href=\"foo.html\"> {text foo}}}}}", [:html, [:body, [:p, [:a, {:href => "foo.html"}, 'foo']]]])
    end
  end
end
