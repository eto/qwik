# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH << 'compat' unless $LOAD_PATH.include? 'compat'
require 'htree'

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/htree-to-wabisabi'
require 'qwik/wabisabi-template'
require 'qwik/util-string'

module Qwik
  class HtmlToWabisabi
    def self.parse(str)
      html = "<html>"+str+"</html>"
      html = html.normalize_newline

      htree = HTree(html)
      first_child = htree.children[0]
      wabisabi = first_child.to_wabisabi
      wabisabi = wabisabi.inside
      return wabisabi
    end
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  $test = true
end

if defined?($test) && $test
  class TestHtmlToWabisabi < Test::Unit::TestCase
    def ok(e, s)
      ok_eq(e, Qwik::HtmlToWabisabi.parse(s))
    end

    def test_ref
      #ok(["\240"], "&nbsp;")
      #ok(["?"], "&nbsp;")
      ok(["<"], "&lt;")
      ok([">"], "&gt;")
    end

    def test_html_parser
      ok([], '')
      ok(['a'], 'a')

      # Div element can contain another div element.
      ok([[:div, 't1', [:div, 't2']]], "<div>t1<div>t2")

      # Span element can not contain div element.
      ok([[:span, 't1'], [:div, 't2']], "<span>t1<div>t2")

      # Fix the order.
      ok([[:b, [:i, 't']]], "<b><i>t</i></b>")

      # You can use incomplete html also.
      ok([[:ul, [:li, 't1'], [:li, 't2']]], "<ul><li>t1<li>t2")

      # test_long_html
      html = <<'EOT'
<H2>書式一覧簡易版</H2>
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
<DD>書き込み可能なWebページ
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
<P><EM>強調</EM>、<STRONG>さらに強調</STRONG>、<DEL>取り消し線</DEL> <IMG alt=new src="http://example.com/.theme/new.png"> <A href="FrontPage.html">FrontPage</A> <A href="http://www.yahoo.co.jp/">Yahoo!</A></P><PLUGIN param='1' method='recent'></PLUGIN>
EOT

      result = [[:h2, "書式一覧簡易版"], "\n",
	[:p, "詳細な説明は",
	  [:a, {:href=>'TextFormat.html'}, 'TextFormat'],
	  "をごらんください。"], "\n",
	[:h3, "見出し2"], "\n",
	[:h4, "見出し3"], "\n",
	[:h5, "見出し4"], "\n",
	[:h6, "見出し5"], "\n",
	[:ul,  "\n",
	  [:li,   "箇条書レベル1\n",
	    [:ul,    "\n",
	      [:li, "箇条書レベル2\n",
		[:ul, "\n", [:li, "箇条書レベル3"]]]]]], "\n",
	[:ol,  "\n",
	  [:li,   "順序リスト1\n",
	    [:ol, "\n", [:li, "順序リスト2\n",
		[:ol, "\n", [:li, "順序リスト3"]]]]]],
	[:pre, "整形済みテキスト。"], "\n",
	[:blockquote, "\n", [:p, "引用。"]], "\n",
	[:dl, "\n",
	  [:dt, "Wiki\n"],
	  [:dd, '書き込み可能なWebページ'+"\n"],
	  [:dt, "QuickML\n"],
	  [:dd, "簡単に作れるメーリングリストシステム"]], "\n",
	[:table, "\n",
	  [:tbody, "\n",
	    [:tr, "\n",
	      [:td, "項目1-1"], "\n",
	      [:td, "項目1-2"], "\n",
	      [:td, "項目1-3"]], "\n",
	    [:tr, "\n",
	      [:td, "項目2-1"], "\n",
	      [:td, "項目2-2"], "\n",
	      [:td, "項目2-3"]]]], "\n",
	[:p,
	  [:em, "強調"],  "、",
	  [:strong, "さらに強調"],  "、",
	  [:del, "取り消し線"],  ' ',
	  [:img, {:alt=>'new', :src=>'http://example.com/.theme/new.png'}],  ' ',
	  [:a, {:href=>'FrontPage.html'}, 'FrontPage'],  ' ',
	  [:a, {:href=>'http://www.yahoo.co.jp/'}, "Yahoo!"]],
	[:plugin, {:method=>'recent', :param=>'1'}], "\n"]

      ok(result, html)
    end
  end
end
