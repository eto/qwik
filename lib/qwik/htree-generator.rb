# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH << 'compat' unless $LOAD_PATH.include? 'compat'
require 'htree'

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module HTree
  module GeneratorModule
    def method_missing(symbol, *args, &block)
      make(symbol, *args, &block)
    end

    def p(*args, &block)
      make(:p, *args, &block)
    end

    def make(symbol, *args, &block)
      ar = make_ar(symbol, *args, &block)
      Elem.new(*ar)
    end

    def make_ar(symbol, *args, &block)
      ar = []

      ar << symbol.to_s.gsub(/_/, '-') # tag name

      if 0 < args.length
	a = add_args(args)
	ar += a
      end

      if block
	y = block.call
	ar += add_elems(y)
      end

      ar
    end

    def add_args(args)
      args.flatten.map {|arg|
	symbol_to_hash(arg)
      }
    end

    def add_elems(args)
      return [] if args.nil?
      return [args] unless args.kind_of? Array
      ar = []
      args.each {|a|
	next if a.nil?
	ar << a
      }
      ar = [''] if ar.empty?
      ar
    end

    def symbol_to_hash(s)
      h = {}
      s.each {|k, v|
	next if v.nil?
	h[k.to_s] = v.to_s
      }
      h
    end
  end

  class Generator; include GeneratorModule; end
end

if $0 == __FILE__
  require 'qwik/testunit'
  require 'qwik/htree-format-xml'
  $test = true
end

if defined?($test) && $test
  class TestHTreeGenerator < Test::Unit::TestCase
    def ok(e, s)
      ok_eq(e, s.format_xml)
    end

    def test_all
      g = HTree::Generator.new

      # test_htree_generator
      ok("<p/>", g.p)
      doc = HTree::Doc.new(g.p)
      ok("<p/>", doc)
      str = ''
      doc.display_xml(str)
      ok_eq("<p\n/>", str)

      ok("<a/>", g.a)
      ok("<b/>", g.b{})
      ok("<b></b>", g.b{''})
      ok('<img src='u'/>', g.img(:src=>'u'))
      ok("<b>t</b>", g.b{'t'})
      ok("<p><b>b</b></p>", g.p{g.b{'b'}})
      ok("<p>t<p>b</p>t</p>", g.p{['t', g.p{'b'}, 't']})
      ok('<a href='u'>t</a>', g.a(:href=>'u'){'t'})
      ok('<font size='7'>t</font>', g.font(:size => 7){'t'})

      # test_namespace
      ok("<b>t</b>", g.make('b'){'t'})
      ok("<n:b>t</n:b>", g.make("n:b"){'t'})
      ok('<a href='u'>t</a>', g.make('a', :href=>'u'){'t'})

      html = g.html {[
	  g.head {[
	      g.title {"タイトル"},
	    ]},
	  g.body {[
	      g.pre {[g.b {'world'},  'hello']},
	      g.pre {['This is ', g.b{'bold'}, ' text.']},
	      g.pre {['This is ', g.i{'italic'}, ' text.']},
	      g.p {['This is ', g.a(:href=>'hoge'){'anchor'}, ' text.']},
	    ]}
	]}
      ok("<html><head><title>タイトル</title></head><body><pre><b>world</b>hello</pre><pre>This is <b>bold</b> text.</pre><pre>This is <i>italic</i> text.</pre><p>This is <a href=\"hoge\">anchor</a> text.</p></body></html>", html)

      # test_with_underbar
      ok("<ab/>", g.ab)
      ok("<a-b/>", g.a_b)
      ok("<a-b/>", g.make("a_b"))
      ok("<a-b/>", g.make("a-b"))

      # test_ordered_hash
      ok("<a b=\"c\"/>", g.a({'b'=>'c'}))
      ok("<a b=\"c\"/>", g.a([{'b'=>'c'}]))
      ok("<a b=\"c\" d=\"e\"/>", g.a([{'b'=>'c'}, {'d'=>'e'}]))
      ok("<a b=\"c\" d=\"e\"/>", g.a({'b'=>'c'}, {'d'=>'e'}))

      # test_multi_attr
      ok("<a href=\"h\" class=\"c\"/>",
	 g.make('a', {:href=>'h'}, {:class=>'c'}))
      ok("<a class=\"c\" href=\"h\"/>",
	 g.make('a', {:class=>'c'}, {:href=>'h'}))
    end
  end
end
