# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/html-generator'

module Qwik
  module WabisabiGeneratorModule
    def method_missing(symbol, *args, &block)
      make(symbol, *args, &block)
    end

    def p(*args, &block)
      make(:p, *args, &block)
    end

    def make(symbol, *args, &block)
      symbol = symbol.intern if symbol.is_a?(String)
      ar = make_ar(symbol, *args, &block)
      ar
    end

    def make_ar(symbol, *args, &block)
      ar = []

      ar << symbol

      if 0 < args.length
	ar += args.flatten
      end

      if block
	y = block.call
	es = add_elems(y)
	if 0 < es.length
	  if es[0].is_a? Symbol
	    ar << es
	  else
	    ar += es
	  end
	end
      end

      ar
    end

    def add_elems(args)
      return [] if args.nil?
      return [args] unless args.kind_of? Array
      ar = []
      args.each {|a|
	a = '' if a.nil?
	ar << a
      }
      ar
    end
  end

  module WabisabiHtmlGeneratorModule
    include WabisabiGeneratorModule
    include HtmlGeneratorUnit
  end

  class WabisabiGenerator; include WabisabiGeneratorModule; end
  class WabisabiHtmlGenerator; include WabisabiHtmlGeneratorModule; end

  class Generator < WabisabiGenerator; end
  class HtmlGenerator < WabisabiHtmlGenerator; end
end

if $0 == __FILE__
  require 'qwik/testunit'
  require 'qwik/wabisabi-format-xml'
  # $KCODE = 's'
  $test = true
end

if defined?($test) && $test
  class TestWabisabiGenerator < Test::Unit::TestCase
    def ok(e, s)
      assert_equal e, s
    end

    def test_all
      g = Qwik::WabisabiGenerator.new

      # test_htree_generator
      ok([:p], g.p)
      ok([:a], g.a)
      ok([:b], g.b{})
      ok([:b, ''], g.b{''})
      ok([:img, {:src=>'u'}], g.img(:src=>'u'))
      ok([:b, 't'], g.b{'t'})
      ok([:p, [:b, 'b']], g.p{g.b{'b'}})
      ok([:p, 't', [:p, 'b'], 't'], g.p{['t', g.p{'b'}, 't']})
      ok([:a, {:href=>'u'}, 't'], g.a(:href=>'u'){'t'})
      ok([:font, {:size=>'7'}, 't'], g.font(:size=>'7'){'t'})

      # test_namespace
      ok([:b, 't'], g.make('b'){'t'}) 
      ok([:'n:b', 't'], g.make('n:b'){'t'})
      ok([:a, {:href=>'u'}, 't'], g.make('a', :href=>'u'){'t'})
      html = g.html {[
	  g.head {[
	      g.title {"タイトル"},
	    ]},
	  g.body {[
	      g.pre {[g.b {'world'},  'hello']},
	      g.pre {['this is ', g.b{'bold'}, ' text.']},
	      g.pre {['this is ', g.i{'italic'}, ' text.']},
	      g.p {['this is ', g.a(:href=>'hoge'){'anchor'}, ' text.']},
	    ]}
	]}
      ok([:html,
	   [:head, [:title, "タイトル"]],
	   [:body,
	     [:pre, [:b, 'world'], 'hello'],
	     [:pre, 'this is ', [:b, 'bold'], ' text.'],
	     [:pre, 'this is ', [:i, 'italic'], ' text.'],
	     [:p, 'this is ', [:a, {:href=>'hoge'}, 'anchor'], ' text.']]],
	 html)

      # test_with_underbar
      ok([:ab], g.ab)
      ok([:'a-b'], g.make('a-b'))

      # test_ordered_hash
      ok([:a, {'b'=>'c'}], g.a({'b'=>'c'}))
      ok([:a, {'b'=>'c'}], g.a([{'b'=>'c'}]))
      ok([:a, {'b'=>'c'}, {'d'=>'e'}], g.a([{'b'=>'c'}, {'d'=>'e'}]))
      ok([:a, {'b'=>'c'}, {'d'=>'e'}], g.a({'b'=>'c'}, {'d'=>'e'}))
    end
  end

  class TestWabisabiHtmlGenerator < Test::Unit::TestCase
    def ok(e, s)
      assert_equal e, s
    end

    def test_htree_html_generator
      g = Qwik::WabisabiHtmlGenerator.new
      ok([:p], g.p)

      ok([:meta, {:content=>'text/html', 'http-equiv'=>'Content-Type'}],
	 g.contenttype('text/html'))
      ok([:meta, {:content=>"0; url=t", 'http-equiv'=>'Refresh'}],
	 g.refresh(0, 't'))
      ok([:link, {:href=>'style1.css',
	     :type=>'text/css', :rel=>'stylesheet'}],
	 g.stylesheet('style1.css'))

      # test_link
      ok([:a, {:href=>'t'}, 's'], g.a('t'){'s'})
      ok([:a, {:href=>"t?a"}, 's'], g.a("t?a"){'s'})
      ok([:a, {:href=>"t?a&b"}, 's'], g.a("t?a&b"){'s'})
      ok([:a, {:href=>'t'}, "<"], g.a('t'){"<"})

      # test_form
      ok([:input, {:name=>'n'}], g.text('n'))
      ok([:input, {:value=>'t', :type=>'submit', :name=>'n'}],
	 g.submit('t', 'n'))
      ok([:textarea, {:name=>''}, 't'],
	 g.textarea{'t'})
      ok([:select,
	   {:name=>'n'},
	   [:option, {:name=>'t1'}, 't1'],
	   [:option, {:name=>'t2'}, 't2']], g.select('n', 't1', 't2'))

      ok([:input, {:type=>'hidden'}, {:name=>'n'}], g.hidden('n'))
      ok([:input, {:type=>'hidden'}, {:name=>'n'}, {:value=>'v'}],
	 g.hidden('n', 'v'))
      ok([:input, {:id=>'i', :value=>'v', :name=>'n'}],
	 g.hidden({:name=>'n', :value=>'v', :id=>'i'}))
      ok([:input, {:id=>'i', :value=>'v', :name=>'n'}],
	 g.hidden(:name=>'n', :value=>'v', :id=>'i'))

      ok([:form, 't'], g.form{'t'})
      ok([:form, {:method=>'POST'}, 't'], g.form('POST'){'t'})
      ok([:form, {:method=>'POST'}, {:action=>'u'}, 't'],
	 g.form('POST', 'u'){'t'})
      ok([:form, {:enctype=>'multipart/form-data', :method=>'POST'}, 't'],
	 g.form(:method=>'POST', :enctype=>'multipart/form-data'){'t'})

      # test_html
      html = g.html {[
	  g.head {[
	      g.contenttype("text/html; charset=SHIFT_JIS"),
	      g.title {"タイトル"},
	      g.stylesheet('style.css')
	    ]},
	  g.body {[
	      g.pre {[g.b {'world'},  'hello']},
	      g.pre {['This is ', g.b{'bold'}, ' text.']},
	      g.pre {['This is ', g.i{'italic'}, ' text.']},
	      g.p {['This is ', g.a('hoge'){'anchor'}, ' text.']},
	      g.p {['This is ', g.a(:href=>'hoge'){'anchor'}, ' text.']},
	      g.img('new.gif', 'new')
	    ]}
	]}
      ok([:html,
	   [:head,
	     [:meta,
	       {:content=>"text/html; charset=SHIFT_JIS", 'http-equiv'=>'Content-Type'}],
	     [:title, "タイトル"],
	     [:link,
	       {:href=>'style.css', :rel=>'stylesheet', :type=>'text/css'}]],
	   [:body,
	     [:pre, [:b, 'world'], 'hello'],
	     [:pre, 'This is ', [:b, 'bold'], ' text.'],
	     [:pre, 'This is ', [:i, 'italic'], ' text.'],
	     [:p, 'This is ', [:a, {:href=>'hoge'}, 'anchor'], ' text.'],
	     [:p, 'This is ', [:a, {:href=>'hoge'}, 'anchor'], ' text.'],
	     [:img, {:alt=>'new', :src=>'new.gif'}]]], html)
    end
  end

  class TestWabisabiXmlGeneratorModule < Test::Unit::TestCase
    include Qwik::WabisabiGeneratorModule

    def ok(e, s)
      assert_equal e, s.rb_format_xml(-1, -1)
    end

    def test_generator_module
      ok("<b/>", b)
      ok("<b/>", b{})
      ok("<b>t</b>", b{'t'})
      ok("<div><b>t</b></div>", div{b{'t'}})
      ok("<p><b>b</b></p>", p{b{'b'}})
      ok("<p>t<p>b</p>t</p>", p{['t', p{'b'}, 't']})
      ok("<a href=\"u\">t</a>", a(:href=>'u'){'t'})
    end
  end

  class TestWabisabiHtmlGeneratorModule < Test::Unit::TestCase
    include Qwik::WabisabiHtmlGeneratorModule

    def ok(e, s)
      assert_equal e, s.rb_format_xml(-1, -1)
    end

    def test_all
      html = html {[
	  head {[
	      contenttype("text/html; charset=SHIFT_JIS"),
	      title {"タイトル"},
	      stylesheet('style.css')
	    ]},
	  body {[
	      pre {[b {'world'},  'hello']},
	      pre {['This is ', b{'bold'}, ' text.']},
	      pre {['This is ', i{'italic'}, ' text.']},
	      p {['This is ', a('hoge'){'anchor'}, ' text.']},
	      p {['This is ', a(:href=>'hoge'){'anchor'}, ' text.']},
	      img('new.gif', 'new')
	    ]}
	]}
      ok("<html><head><meta content=\"text/html; charset=SHIFT_JIS\" http-equiv=\"Content-Type\"/><title>タイトル</title><link href=\"style.css\" rel=\"stylesheet\" type=\"text/css\"/></head><body><pre><b>world</b>hello</pre><pre>This is <b>bold</b> text.</pre><pre>This is <i>italic</i> text.</pre><p>This is <a href=\"hoge\">anchor</a> text.</p><p>This is <a href=\"hoge\">anchor</a> text.</p><img alt=\"new\" src=\"new.gif\"/></body></html>", html)
    end
  end
end
