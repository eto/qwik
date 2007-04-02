# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/util-string'

$LOAD_PATH << '../../ext' unless $LOAD_PATH.include?('../../ext')
begin
  require 'xmlformatter.so'
  $have_xmlformatter_so = true
rescue LoadError
  #p "No extention.  Use Ruby version."
  $have_xmlformatter_so = false
end

module Qwik
  class RB_XMLFormatter
    # copied from gonzui-0.1
    # Extend some functions by Kouichirou Eto

    # To eliminate costs for object creation, the following
    # strings are defined as constants. It makes format_xml
    # 1.2 times faster.
    SP = ' '
    QT = '"'
    EQ = '='
    LT = '<'
    GT = '>'
    LF = "\n"
    SL = '/'
    NL = '' # null

    # Meta element
    XMLDECL = '?xml'
    DOCTYPE = '!DOCTYPE'
    COMMENT = '!--'
    CDATA = '![CDATA['

    def format(ar, indent=0, sindent=0)
      n = (0 <= indent) ? LF : NL
      sn = (0 <= sindent) ? LF : NL

      if !ar[0].is_a?(Symbol)
	out = ''
	ar.each {|x|
	  if x.is_a?(Array)
	    out << format(x, indent, sindent) # recursive
	  elsif x.is_a?(String)
	    out << x.escapeHTML
	  elsif x.is_a?(NilClass)
	    # do nothing
	  else
	    p "what?", x
	    out << x.to_s.escapeHTML
	  end
	}
	return out
      end

      element = ar[0].to_s.escapeHTML

      if element == XMLDECL # XML Declaration
	attributes = ''
	attributes += " version=\""+ar[1]+"\"" if ar[1]
	attributes += " encoding=\""+ar[2]+"\"" if ar[2]
	attributes += " standalone=\""+ar[3]+"\"" if ar[3]
	return "<?xml"+attributes+"?>"

      elsif element == DOCTYPE # doctype
	return "<!DOCTYPE "+ar[1]+' '+ar[2]+
	  " \""+ar[3]+"\" \""+ar[4]+"\">"

      elsif element == COMMENT # comment
	return "<!--"+ar[1]+"-->"

      elsif element == CDATA # CDATA
	return "<![CDATA["+ar[1]+"]]>"

      end

      offset = 1
      attributes = ''
      while ar[offset].is_a?(Hash)
	attr = ar[offset]
	offset += 1
	attr.keys.sort{|a, b| a.to_s <=> b.to_s }.each {|k|
	  v = attr[k]
	  attributes << SP << k.to_s.escapeHTML << EQ << QT << v.to_s.escapeHTML << QT
	}
      end

      if ar[offset].nil? && ar.length == offset
	o = ''
	o << LT << element << attributes << n << SL << GT
	return o
      end

      out = ''
      out << LT << element << attributes << sn << GT
      (offset...ar.length).each {|i|
	x = ar[i]
	if x.is_a?(Array)
	  out << format(x, indent, sindent) # recursive
	elsif x.is_a?(String)
	  out << x.escapeHTML
	else
	  out << x.to_s.escapeHTML
	end
      }
      out << LT << SL << element << n << GT
      out
    end
  end
end

class Array
  def rb_format_xml(indent=0, sindent=0)
    formatter = Qwik::RB_XMLFormatter.new
    result = formatter.format(self, indent, sindent)
    result
  end

  # You can not specify indent in c_formt_xml.
  def c_format_xml
    formatter = Gonzui::XMLFormatter.new
    result = formatter.format(self)
    result
  end

  def format_xml
    return self.c_format_xml if $have_xmlformatter_so
    return self.rb_format_xml
  end
end

if $0 == __FILE__
  if ARGV[0] == '-c'
    $check = true
  else
    require 'qwik/testunit'
    require 'pp'
    $test = true
  end
end

if defined?($test) && $test
  class TestXMLFormatter < Test::Unit::TestCase
    def ok(e, w)
      ok_eq(e, w.rb_format_xml)
      ok_eq(e, w.format_xml)	# assert twice
    end

    def ok_rb(e, w)
      ok_eq(e, w.rb_format_xml)
    end

    def test_rb_format_xml
      ok_eq("<a\n/>", [:a].rb_format_xml(0))
      ok_eq("<a></a\n>", [:a, ""].rb_format_xml(0, -1))
      ok_eq("<a\n></a\n>", [:a, ""].rb_format_xml)
      ok_eq("<a><b></b></a>", [:a, [:b, '']].rb_format_xml(-1, -1))
      ok_eq("<a><b></b\n></a\n>", [:a, [:b, ""]].rb_format_xml(0, -1))
      ok_eq("<a\n><b\n></b\n></a\n>", [:a, [:b, ""]].rb_format_xml)
    end

    def test_all
      # test_basic
      ok("<a\n/>", [:a])
      ok("<a\n>t</a\n>", [:a, 't'])
      ok("<a\n><b\n></b\n></a\n>", [:a, [:b, '']])
      ok("<a href=\"t\"\n>s</a\n>", [:a, {:href=>'t'}, 's'])

      # test_escape
      ok("<a\n>&lt;</a\n>", [:a, '<'])
      ok("<a href=\"&lt;\"\n/>", [:a, {:href=>'<'}])
      ok("<a &gt;=\"&lt;\"\n/>", [:a, {'>'=>'<'}])
      ok("<a &lt;=\"&lt;\"\n/>", [:a, {'<'=>'<'}])
      ok("<&lt;\n/>", [:'<'])
      ok("<&lt; &amp;=\"&lt;\"\n/>", [:'<', {'&'=>'<'}])

      # test_doctype
      ok("<!DOCTYPE html PUBLIC \"-//W3C//DTD html 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">",
	 [:"!DOCTYPE", 'html', 'PUBLIC',
	   '-//W3C//DTD html 4.01 Transitional//EN',
	   'http://www.w3.org/TR/html4/loose.dtd'])
      ok("<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">",
	 [:"!DOCTYPE", 'html', 'PUBLIC',
	   '-//W3C//DTD XHTML 1.0 Transitional//EN',
	   'http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd'])

      # test_comment
      ok('<!--comment-->', [:'!--', 'comment'])
      ok("<!--<-->", [:"!--", "<"])

      # test_text
      ok('', [])
      ok('', [''])
      ok('a', ['a'])
      ok('ab', ['a', 'b'])
      ok('abc', ['a', ['b'], 'c'])

      # test_null
      ok("<a\n></a\n>", [:a, ''])
      ok("<a\n></a\n>", [:a, nil])
      ok("<a\n></a\n>", [:a, []])
      ok("<a\n>nil</a\n>", [:a, :nil])
      ok("<p id=\"\"\n/>", [:p, {:id=>''}])
      ok("<p id=\"\"\n/>", [:p, {:id=>nil}])
      ok("<p id=\"\"\n/>", [:p, {:id=>[]}])
      ok("<p\n>b</p\n>", [:p, [['b']]])
      ok("<p\n>bc</p\n>", [:p, ['b'], 'c'])
      ok("<p id=\"\"\n></p\n>", [:p, {:id=>''}, ''])

      # test_non_destructive
      w = [:a]
      ok("<a\n/>", w)
      ok("<a\n/>", w)

      # test_bug
      ok("<a\n/><b\n/>", [[:a], [:b]])

      # test_format_xml # copied from gonzui-0.3
      html = [:html]
      head = [:head, [:title, 'foo']]
      body = [:body, [:h1, [:a, {:href => 'foo<&">.html'}, 'foo<&">']]]
      body.push([:p, 'hello'])
      html.push(head)
      html.push(body)
      ok("<html\n><head\n><title\n>foo</title\n></head\n><body\n><h1\n><a href=\"foo&lt;&amp;&quot;&gt;.html\"\n>foo&lt;&amp;&quot;&gt;</a\n></h1\n><p\n>hello</p\n></body\n></html\n>", html)

      # test_general
      ok(
"<html
><head
><title
>hello</title
></head
><body
><h1
>hello, world!</h1
><p
>This is <a href=\"hello.html\"
>hello, world</a
>example.</p
></body
></html
>",
	 [:html,
	   [:head,
	     [:title, 'hello']],
	   [:body,
	     [:h1, 'hello, world!'],
	     [:p, 'This is ',
	       [:a, {:href=>'hello.html'}, 'hello, world'],
	       'example.']]]
	 )

      # test_etc
      ok_rb("<html lang=\"ja\" xml:lang=\"ja\" xmlns=\"http://www.w3.org/1999/xhtml\"\n></html\n>",
	 [:html, {:xmlns=>'http://www.w3.org/1999/xhtml',
	     :'xml:lang'=>'ja', :lang=>'ja'}, ''])
      ok_rb("<meta content=\"text/html; charset=shift_jis\" http-equiv=\"Content-Type\"\n/>",
	 [:meta, {:'http-equiv'=>'Content-Type',
	     :content=>'text/html; charset=shift_jis'}])

      # test_cdata
      ok("<![CDATA[cdata]]>", [:'![CDATA[', 'cdata'])
      ok("<![CDATA[<]]>", [:'![CDATA[', "<"])

      # test_xmldecl
      ok("<?xml?>", [:'?xml'])
      ok("<?xml version=\"1.0\"?>", [:'?xml', '1.0'])
      ok("<?xml version=\"1.0\" encoding=\"utf-8\"?>",
	 [:'?xml', '1.0', 'utf-8'])
      ok("<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\"?>",
	 [:'?xml', '1.0', 'utf-8', 'yes'])
      ok("<?xml version=\"1.0\" encoding=\"utf-8\"?><a\n/>",
	 [[:'?xml', '1.0', 'utf-8'], [:a]])

      # check_wabisabi_output
      html = [:html,
	[:head,
	  [:title, 'hello']],
	[:body,
	  [:h1, 'hello, world!'],
	  [:p, 'This is a ',
	    [:a, {:href=>'hello.html'}, 'hello, world'],
	    ' example.']]]
      #puts html.format_xml
      ok("<html
><head
><title
>hello</title
></head
><body
><h1
>hello, world!</h1
><p
>This is a <a href=\"hello.html\"
>hello, world</a
> example.</p
></body
></html
>",
	 html)
    end
  end
end

