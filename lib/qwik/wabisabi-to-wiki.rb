# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/util-string'

module Qwik
  class WabisabiToWiki
    def self.translate(wabisabi)
      str = parse(wabisabi)
      str.gsub!(/\n\n\z/, "\n")
      return str
    end

    private

    def self.parse(wabisabi)
      if wabisabi.is_a?(Array)
	first = wabisabi[0]

	if first.nil?
	  return ''
	end

	if first.is_a?(String)
	  if first == "\n"
	    str = ''
	  else
	    str = first
	  end
	  str += parse(wabisabi[1..-1])
	  return str
	end

	if first.is_a?(Array)
	  return wabisabi.map {|a|
	    parse(a)
	  }.join
	end

	if first.is_a?(Symbol)
	  # FIXME: Should take care for inline level element.
	  return parse_block(wabisabi)
	end

	p 'What? ', wabisabi; raise
      end

      if wabisabi.is_a?(String)
	if wabisabi == "\n"
	  return ''
	else
	  return wabisabi
	end
      end

      p 'What? ', wabisabi; raise
    end

    SIMPLE_BLOCK = {
      :h2 => ['* ', "\n"],
      :h3 => ['** ', "\n"],
      :h4 => ['*** ', "\n"],
      :h5 => ['**** ', "\n"],
      :h6 => ['***** ', "\n"],
      :p  => ['', "\n\n"],
    }

    # ==================== block level
    def self.parse_block(e)
      if SIMPLE_BLOCK[e[0]]
	head, tail = SIMPLE_BLOCK[e[0]]
	str = head + parse_span(e.inside) + tail
	return str
      end

      case e[0]

      when :dl
	return parse_dl(e)

      when :ul
	return parse_ul(e)

      when :ol
	return parse_ol(e)

      when :blockquote
	return parse_blockquote(e)

      when :pre
	return parse_pre(e)

      when :table
	return parse_table(e)

      when :plugin
	return parse_plugin(e)

      when :html, :div
	return parse(e.inside)

      when :hr
	return "====\n"

      end

      # maybe, inline element.
      return parse_span(e)
      #p 'What? ', e; raise
    end

    def self.parse_dl(elem)
      str = ''
      in_dt = false
      elem.each_child {|e|
	next if e == "\n"
	if e[0] == :dt
	  span = parse_span(e.inside)
	  span.sub!(/\n+\z/, '')
	  str << ':'+span
	  in_dt = true
	elsif e[0] == :dd
	  str << ':' if ! in_dt
	  span = parse_span(e.inside)
	  span.sub!(/\n+\z/, '')
	  str << ':'+span+"\n"
	  in_dt = false
	else
	  p 'What? ', e; raise
	end
      }
      return str
    end

    def self.parse_ul(elem)
      return parse_list('-', :ul, elem)
    end

    def self.parse_ol(elem)
      return parse_list('+', :ol, elem)
    end

    def self.parse_list(prefix, elementname, elem)
      str = ''
      elem.each_child {|e|
	next if e == "\n"

	if e[0] == :li
	  inside = e.inside
	  instr = parse(inside)
	  nstr = ''
	  instr.each_line {|line|
	    next if line == "\n"
	    line = line.normalize_eol
	    str << prefix + line
	  }

	elsif e[0] == elementname
	  nstr = parse_ul(e)
	  nstr.each_line {|line|
	    next if line == "\n"
	    line = line.normalize_eol
	    str << prefix + line
	  }
	else
	  p 'What? ', e
	end
      }
      return str
    end

    def self.parse_blockquote(elem)
      str = parse(elem.inside)
      nstr = ''
      str.each {|line|
	next if line == "\n"
	nstr << "> #{line}"
      }
      return nstr
    end

    def self.parse_pre(elem)
      str = ''
      elem.inside.each {|e|
	if e.is_a?(String)
	  str << e
	else
	  p 'What? ', e; raise
	end
      }

      nstr = ''
      str.each {|line|
	next if line == "\n"
	line = line.normalize_eol
	nstr << " #{line}"
      }
      return nstr
    end

    def self.parse_table(elem)
      str = ''
      elem.each_child {|e|
	next if e == "\n"
	if e[0] == :tr
	  str << "#{parse_tr(e)}\n"
	elsif e[0] == :tbody
	  str << parse_table(e.inside)
	else
	  p 'What? ', e; raise
	end
      }
      return str
    end

    def self.parse_tr(elem)
      str = ''
      elem.each_child {|e|
	next if e == "\n"
	if e[0] == :td
	  str << "|#{parse_span(e.inside)}"
	else
	  p 'What? ', e; raise
	end
      }
      return str
    end

    def self.parse_plugin(e)
      param = e.attr[:param]
      method = e.attr[:method]
      data = e.text
      str = ''
      str << "{{#{method}"
      str << "(#{param})" if param && ! param.empty?
      if data && ! data.empty?
	str << "\n"
	data = data.normalize_eol
	str << data
      end
      str << "}}\n"
      return str
    end

    # ==================== inline level
    def self.parse_span(elem)
      str = ''

      if elem.is_a?(Array) && elem[0].is_a?(Symbol)
	return parse_span_elem(elem)
      end

      elem.each_child {|e|
	if e.is_a?(String)
	  str << e
	elsif e.is_a?(Array)
	  str << parse_span_elem(e)
	else
	  p 'What? ', e
	end
      }
      str
    end

    def self.parse_span_elem(e)
      n = e[0]

      case n

      when :a
	return parse_a(e)

      when :img
	attr = e.attr
	return '' if attr.nil?
	src = attr[:src]
	return '' if src.nil?
	return "[[#{src}]]"

      when :em
	return "''#{parse_span(e.inside)}''"

      when :strong
	return "'''#{parse_span(e.inside)}'''"

      when :del
	return "==#{parse_span(e.inside)}=="

      when :br
	return "{{br}}\n"

      else
	return ''
	#p 'What? ', e; raise
      end
    end

    def self.parse_a(e)
      href = e.attr[:href]

      if /\A(.+)\.html\z/ =~ href
	href = $1
      end

      text = e.text
      str = ''
      str << "[[#{text}"
      if href != text
	str << "|#{href}"
      end
      str << ']]'
      return str
    end
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  require 'qwik/html-to-wabisabi'
  $test = true
end

if defined?($test) && $test
  class TestWabisabiToWiki < Test::Unit::TestCase
    # In this situation, I use reverse order argument for covinience.
    def ok(w, e)
      ok_eq(e, Qwik::WabisabiToWiki.translate(w))
    end

    def test_from_parser
      # test none
      ok([], '')
      #ok([["\n"]], "#t")

      # test p
      ok([[:p, 't']], "t\n")
      ok([[:p, 's', "\n", 't']], "s\nt\n")
      ok([[:p, 's'], ["\n"], [:p, 't']], "s\n\nt\n")
      ok([[:p, 's', [:br], 't']], "s{{br}}\nt\n")

      ok([[:dl, [:dt, 'dt1'], [:dd, 'dd1']], [:p, 'p1'],
	   [:dl, [:dd, 'dd2']]], ":dt1:dd1\np1\n\n::dd2\n")

      # test header
      ok([[:h2, 't']], "* t\n")
      ok([[:h2, 't'], [:p, 't']], "* t\nt\n")
      ok([[:h3, 't']], "** t\n")
      ok([[:h4, 't']], "*** t\n")
      ok([[:h5, 't']], "**** t\n")
      ok([[:h6, 't']], "***** t\n")
      ok([[:h6, '*t']], "***** *t\n")
      ok([[:h6, '**t']], "***** **t\n")

      # test_ignore_space
      ok([[:h2, 't']], "* t\n")
      ok([[:h2, 't']], "* t\n")
      ok([[:h2, 't']], "* t\n")
      ok([[:h3, 't']], "** t\n")
      ok([[:h3, 't']], "** t\n")
      ok([[:h3, 't']], "** t\n")

      # test listing
      ok([[:ul, [:li, 't']]], "-t\n")
      ok([[:ul, [:ul, [:li, 't']]]], "--t\n")
      ok([[:ul, [:ul, [:ul, [:li, 't']]]]], "---t\n")
      ok([[:ul, [:li, 't']], [:p, 't']], "-t\nt\n")
      ok([[:ul, [:li, 't'], [:li, 't']]], "-t\n-t\n")
      ok([[:ul, [:li, 't'], [:ul, [:li, 't']]]], "-t\n--t\n")
      ok([[:ul, [:ul, [:li, 't']], [:li, 't']]], "--t\n-t\n")
      ok([[:ul, [:ul, [:li, 't']], [:li, 't'], [:ul, [:li, 't']]]],
	     "--t\n-t\n--t\n")
      ok([[:ol, [:li, 't']]], "+t\n")
      ok([[:ul, [:li, 't']], [:ol, [:li, 't']]], "-t\n+t\n")
      ok([[:ul, [:li, 't1']], ["\n"], [:ul, [:li, 't2']]], "-t1\n-t2\n")
      ok([["\n"], [:ul, [:li, 't1'], [:li, 't2']]], "-t1\n-t2\n")

      # test blockquote
      ok([[:blockquote, [:p, 't']]], "> t\n")
      ok([[:blockquote, [:p, 's', "\n", 't']]], "> s\n> t\n")
      ok([[:blockquote, [:ul, [:li, 's'], [:li, 't']]]], "> -s\n> -t\n")

      # test dl
      ok([[:dl, [:dt, 'dt'],[:dd, 'dd']]], ":dt:dd\n")
      ok([[:dl, [:dt, 'dt']]], ':dt')
      ok([[:dl]], '')
      ok([[:dl]], '')
      ok([[:dl, [:dd, 'dd']]], "::dd\n")
      ok([[:dl, [:dt, 'dt'], [:dd, 'dd'], [:dt, 'dt2'], [:dd, 'dd2']]],
	     ":dt:dd\n:dt2:dd2\n")
      ok([[:dl, [:dt, 'dt'], [:dd, 'dd'], [:dd, 'dd2']]], ":dt:dd\n::dd2\n")

      # test pre
      ok([[:pre, 't']], " t\n")
      ok([[:pre, "s\nt"]], " s\n t\n")
      ok([[:pre, "s\n"]], " s\n")
      ok([[:pre, "s\nt\n"]], " s\n t\n")
      ok([[:pre, 't1'], ["\n"], [:pre, 't2']], " t1\n t2\n")

      # test_table
      ok([[:table, [:tr, [:td, 't']]]], "|t\n")
      ok([[:table, [:tr, [:td, 't1'], [:td, 't2']]]], "|t1|t2\n")
      ok([[:table, [:tr, [:td, ''], [:td, 't2']]]], "||t2\n")
      ok([[:table, [:tr, [:td, 's']], [:tr, [:td, 't']]]], "|s\n|t\n")
      ok([[:table, [:tr, [:td, 's1'], [:td, 's2']],
		 [:tr, [:td, 't1'], [:td, 't2']]]], "|s1|s2\n|t1|t2\n")

      # test plugin
      ok([[:plugin, {:method=>'t', :param=>''}]], "{{t}}\n")
      ok([[:plugin, {:method=>'t', :param=>'a'}]], "{{t(a)}}\n")
      ok([[:plugin, {:method=>'t', :param=>''}, "s\n"]], "{{t\ns\n}}\n")
      ok([[:plugin, {:method=>'t', :param=>''}, "s1\ns2\n"]],
	     "{{t\ns1\ns2\n}}\n")

      # test_multiline
      ok([[:p, 's', "\n", 't']], "s\nt\n")
      ok([[:p, 's', [:br], 't']], "s{{br}}\nt\n")
      ok([[:p, 's'], ["\n"], [:p, 't']], "s\n\nt\n")
      ok([[:p, 's', [:br], [:br], 't']], "s{{br}}\n{{br}}\nt\n")

      str0 = "
p1~
~
> b1~
> b2~
> ~
> > bb1~
> > bb2~
> ~
> b3~
> b4~
~
p2~
"

      str = "p1

> b1{{br}}
> b2
> > bb1{{br}}
> > bb2
> b3{{br}}
> b4
p2
"
      ok([[:p, 'p1'],
	       [:blockquote,  [:p, 'b1', [:br], 'b2'],
		 [:blockquote, [:p, 'bb1', [:br], 'bb2']],
		 [:p, 'b3', [:br], 'b4']],
	       [:p, 'p2']],
	 str)

      # test_html
      ok([[:html, "t\n"]], "t\n")
      ok([[:div, {:class=>'error'}, 'can not use [script]']],
	     'can not use [script]')

      # test_ref
      ok([[:ul, [:li, [:a, {:href=>'http://e.com/'}, 't']]]],
	     "-[[t|http://e.com/]]\n")

      # test_hr
      ok([[:hr]], "====\n")

      # test_bug
      ok_eq("\226]", '望')
      ok([[:p, [:a, {:href=>"\226].html"}, "\226]"]]], '[[望]]'+"\n")
    end
  end

  class TestWabisabiToWiki_wiki < Test::Unit::TestCase
    def ok(e, html)
      # $KCODE = 's'
      w = Qwik::HtmlToWabisabi.parse(html)
      wiki = Qwik::WabisabiToWiki.translate(w)
      ok_eq(e, wiki)
    end

    def test_dl
      s = '<DL>
<DT>Wiki
<DD>書き込み可能なWebページ
<DT>QuickML
<DD>簡単に作れるメーリングリストシステム</DD></DL>
'
      e = ':Wiki:書き込み可能なWebページ
:QuickML:簡単に作れるメーリングリストシステム
'
      ok(e, s)
    end

    def test_ul
      s = '<UL>
<LI>箇条書レベル1
<UL>
<LI>箇条書レベル2
<UL>
<LI>箇条書レベル3</LI></UL></LI></UL></LI></UL>
'
      e = '-箇条書レベル1
--箇条書レベル2
---箇条書レベル3
'
      ok(e, s)
    end

    def test_blockquote
      s = '<BLOCKQUOTE>
<P>引用。</P></BLOCKQUOTE>
'
      e = "> 引用。\n"
      ok(e, s)
    end

    def test_basic
      # test div
      ok("* h\n", '<H2>h</H2>')
      ok("** h\n", '<H3>h</H3>')
      ok("p\n", '<P>p</P>')
      ok("p\n\np2\n", '<P>p</P><P>p2</P>')
      #ok('', '<UL><LI>li</LI></UL>')
      #ok('', '<UL><LI>li1</LI><UL><LI>li2</LI></UL></UL>')
      #ok('', '<DL><DT>dt<DD>dd</DD></DL>')
      #ok('', '<DL><DT>dt1<DD>dd1><DT>dt2<DD>dd2</DD></DL>')
      ok("> 引用。\n", '<BLOCKQUOTE><P>引用。</P></BLOCKQUOTE>')
      ok("> * h\n", '<BLOCKQUOTE><H2>h</H2></BLOCKQUOTE>')
      ok("> x\n> y\n", '<BLOCKQUOTE><P>x</P><P>y</P></BLOCKQUOTE>')

      # test span
      ok("Go [[FrontPage]].\n",
	 '<P>Go <A href="FrontPage.html">FrontPage</A>.</P>')
      ok("Go [[qwikWeb|http://example.com/]].\n",
	 '<P>Go <A href="http://example.com/">qwikWeb</A>.</P>')
      ok("''強調''、'''さらに強調'''、==取り消し線==\n",
	 '<P><EM>強調</EM>、<STRONG>さらに強調</STRONG>、<DEL>取り消し線</DEL></P>')
      ok("[[http://example.com/.theme/new.png]]\n",
	 '<P><IMG alt=new src="http://example.com/.theme/new.png"></P>')
      ok("\n", '<P><IMG></P>')
      ok("[[FrontPage]] [[Yahoo!|http://www.yahoo.co.jp/]]\n\n{{recent(1)}}\n", '<P><A href="FrontPage.html">FrontPage</A> <A href="http://www.yahoo.co.jp/">Yahoo!</A></P><PLUGIN param="1" method="recent"></PLUGIN>')
    end

    def test_frontpage
      s = '<H2>FrontPage</H2>
<P>これは新規qwikWebサイトの入口となるページです。</P>
<H3>使い方</H3>
<P>ページの上の方にある「編集」というリンクをたどると、このページの編集モードになります。</P>
<P>表示されたテキストの内容を変更し、「Save」ボタンをクリックすると、このページの内容が変更されます。</P>
<H3>記述方法</H3>
<P>ページの内容はテキストで書かれており、いくつかの記号によって見出しなどの指定をします。詳しい情報は、<A href="TextFormat.html">TextFormat</A>をご覧下さい。</P>
<H3>qwikWeb</H3>
<P>詳しくは、<A href="http://example.com/">qwikWeb</A>ホームページをご覧ください。</P>
'
      org = '* FrontPage
これは新規qwikWebサイトの入口となるページです。

** 使い方
ページの上の方にある「編集」というリンクをたどると、
このページの編集モードになります。

表示されたテキストの内容を変更し、「Save」ボタンをクリックすると、
このページの内容が変更されます。

** 記述方法
ページの内容はテキストで書かれており、
いくつかの記号によって見出しなどの指定をします。
詳しい情報は、[[TextFormat]]をご覧下さい。

** qwikWeb
詳しくは、[[qwikWeb|http://example.com/]]ホームページをご覧ください。
'
      e = '* FrontPage
これは新規qwikWebサイトの入口となるページです。

** 使い方
ページの上の方にある「編集」というリンクをたどると、このページの編集モードになります。

表示されたテキストの内容を変更し、「Save」ボタンをクリックすると、このページの内容が変更されます。

** 記述方法
ページの内容はテキストで書かれており、いくつかの記号によって見出しなどの指定をします。詳しい情報は、[[TextFormat]]をご覧下さい。

** qwikWeb
詳しくは、[[qwikWeb|http://example.com/]]ホームページをご覧ください。
'
      ok(e, s)
    end

    def test_textformat
      s = '<H2>書式一覧簡易版</H2>
<P>詳細な説明は<A href="TextFormat.html">TextFormat</A>をごらんください。</P>
<H3>見出し2</H3>
<H4>見出し3</H4>
<H5>見出し4</H5>
<H6>見出し5</H6>
<UL>
<LI>箇条書レベル1
<UL>
<LI>箇条書レベル2
<UL>
<LI>箇条書レベル3</LI></UL></LI></UL></LI></UL>
<OL>
<LI>順序リスト1
<OL>
<LI>順序リスト2
<OL>
<LI>順序リスト3</LI></OL></LI></OL></LI></OL><PRE>整形済みテキスト。</PRE>
<BLOCKQUOTE>
<P>引用。</P></BLOCKQUOTE>
<DL>
<DT>Wiki
<DD>書き込みできるWebページ
<DT>QuickML
<DD>簡単に作れるメーリングリストシステム</DD></DL>
<TABLE>
<TBODY>
<TR>
<TD>項目1-1</TD>
<TD>項目1-2</TD>
<TD>項目1-3</TD></TR>
<TR>
<TD>項目2-1</TD>
<TD>項目2-2</TD>
<TD>項目2-3</TD></TR></TBODY></TABLE>
<P><EM>強調</EM>、<STRONG>さらに強調</STRONG>、<DEL>取り消し線</DEL> <IMG alt=new src="http://example.com/.theme/new.png"> <A href="FrontPage.html">FrontPage</A> <A href="http://www.yahoo.co.jp/">Yahoo!</A></P><PLUGIN param="1" method="recent"></PLUGIN>
'
      org = "* 書式一覧簡易版
詳細な説明は[[TextFormat]]をごらんください。
** 見出し2
*** 見出し3
**** 見出し4
***** 見出し5
- 箇条書レベル1
-- 箇条書レベル2
--- 箇条書レベル3
+ 順序リスト1
++ 順序リスト2
+++ 順序リスト3
 整形済みテキスト。
> 引用。
:Wiki:書き込みできるWebページ
:QuickML:簡単に作れるメーリングリストシステム
,項目1-1,項目1-2,項目1-3
,項目2-1,項目2-2,項目2-3
''強調''、'''さらに強調'''、==取り消し線==
[[new|http://example.com/.theme/new.png]]
[[FrontPage]]
[[Yahoo!|http://www.yahoo.co.jp/]]
{{recent(1)}}
"
      e = "* 書式一覧簡易版
詳細な説明は[[TextFormat]]をごらんください。

** 見出し2
*** 見出し3
**** 見出し4
***** 見出し5
-箇条書レベル1
--箇条書レベル2
---箇条書レベル3
+順序リスト1
++順序リスト2
+++順序リスト3
 整形済みテキスト。
> 引用。
:Wiki:書き込みできるWebページ
:QuickML:簡単に作れるメーリングリストシステム
|項目1-1|項目1-2|項目1-3
|項目2-1|項目2-2|項目2-3
''強調''、'''さらに強調'''、==取り消し線== [[http://example.com/.theme/new.png]] [[FrontPage]] [[Yahoo!|http://www.yahoo.co.jp/]]

{{recent(1)}}
"
      ok(e, s)
    end

    def test_bug
      s = '<DL>
<DT>Wiki
<DD>書き込みできる<STRONG>Web</STRONG>ページ
<DT>QuickML
<DD><EM>簡単</EM>に作れるメーリングリストシステム</DD></DL>
'
      e = ":Wiki:書き込みできる'''Web'''ページ
:QuickML:''簡単''に作れるメーリングリストシステム
"
      ok(e, s)
    end
  end
end
