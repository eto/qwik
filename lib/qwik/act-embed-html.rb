# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/html-to-wabisabi'

module Qwik
  class Action
    D_PluginEmbedHtml = {
      :dt => 'Embed HTML plugin',
      :dd => 'You can embed bare HTML in the page.',
      :dc => "* Example
 {{html
 This is <font color='red'>red</font>.
 }}
{{html
This is <font color='red'>red</font>.
}}
* Allowed elements
You can input allowed elements only.
** valid tags
#{WabisabiValidator::VALID_TAGS.join(' ')}
** valid attributes
#{WabisabiValidator::VALID_ATTR.join(' ')}

* HTMLの中へのプラグインの埋め込み
You can also embed plugins like this.
 {{html
 <plugin param=\"1\" method=\"recent\"></plugin>
 }}
{{html
<plugin param=\"1\" method=\"recent\"></plugin>
}}

* Example
<html>
<H3>Header 2</H3>
<H4>Header 3</H4>
<H5>Header 4</H5>
<H6>Header 5</H6>
<UL>
<LI>List 1
<UL>
<LI>List 2
<UL>
<LI>List 3</LI></UL></LI></UL></LI></UL>
<OL>
<LI>Ordered List 1
<OL>
<LI>Ordered List 2
<OL>
<LI>Ordered List 3</LI></OL></LI></OL></LI></OL>
<PRE>Pre-formatted text.</PRE>
<BLOCKQUOTE>
<P>This is a quoted text.</P>
</BLOCKQUOTE>
<DL>
<DT>Wiki
<DD>A writable Web system.
<DT>QuickML
<DD>An easy-to-use mailing list management system.</DD></DL>
<TABLE>
<TBODY>
<TR>
<TD>Table 1-1</TD>
<TD>Table 1-2</TD>
<TD>Table 1-3</TD></TR>
<TR>
<TD>Table 2-1</TD>
<TD>Table 2-2</TD>
<TD>Table 2-3</TD></TR></TBODY></TABLE>
<P><EM>Emphasis</EM>、
<STRONG>Strong</STRONG>、
<DEL>Delete</DEL>
<A href=\"http://qwik.jp/.theme/new.png\">new</A>
<A href=\"FrontPage.html\">FrontPage</A>
<A href=\"http://www.yahoo.co.jp/\">Yahoo!</A>
</P>

<PLUGIN param=\"1\" method=\"recent\"></PLUGIN>
</html>
"
    }

    D_PluginEmbedHtml_ja = {
      :dt => 'HTML埋め込み機能 ',
      :dd => 'HTMLをそのまま埋込むことができます。',
      :dc => "* 例
 {{html
 This is <font color='red'>red</font>.
 }}
{{html
This is <font color='red'>red</font>.
}}
* 使える要素
任意のタグが使えるわけではなく，使える要素は限られています．
** 使えるタグ
#{WabisabiValidator::VALID_TAGS.join(' ')}
** 使えるアトリビュート
#{WabisabiValidator::VALID_ATTR.join(' ')}

* HTMLの中へのプラグインの埋め込み
HTML記述の中にqwikWebのプラグインを埋込むこともできます。
 {{html
 <plugin param=\"1\" method=\"recent\"></plugin>
 }}
{{html
<plugin param=\"1\" method=\"recent\"></plugin>
}}

* 例
<html>
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
<P><EM>強調</EM>、<STRONG>さらに強調</STRONG>、<DEL>取り消し線</DEL> <A href=\"http://qwik.jp/.theme/new.png\">new</A> <A href=\"FrontPage.html\">FrontPage</A> <A href=\"http://www.yahoo.co.jp/\">Yahoo!</A></P>

<PLUGIN param=\"1\" method=\"recent\"></PLUGIN>
</html>
"
    }

    def plg_html
      return unless block_given?
      str = yield

      wabisabi = HtmlToWabisabi.parse(str)

      v = WabisabiValidator.valid?(wabisabi)
      if v == true
	return wabisabi
      else
	return "can not use [#{v}]"
      end
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActEmbedHtml < Test::Unit::TestCase
    include TestSession

    def test_all
      ok_wi(['a
'], '{{html
a
}}')

      # div can contain another div
      ok_wi([:div, 't1', [:div, 't2
']],
	    '{{html
<div>t1<div>t2
}}')

      # span can not contain div
      ok_wi([[:span, 't1'], [:div, 't2
']],
	    '{{html
<span>t1<div>t2
}}')

      # fix the order
      ok_wi([[:b, [:i, 't']], '
'],
	    '{{html
<b><i>t</i></b>
}}')

      # incomplete html maybe ok.
      ok_wi([:ul, [:li, 't1'], [:li, 't2
']],
	    '{{html
<ul><li>t1<li>t2
}}')

      # test_longer_html
      html = <<"EOT"
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
<P><EM>強調</EM>、<STRONG>さらに強調</STRONG>、<DEL>取り消し線</DEL> <IMG alt=new src="http://example.com/.theme/new.png"> <A href="FrontPage.html">FrontPage</A> <A href="http://www.yahoo.co.jp/">Yahoo!</A></P><PLUGIN param="1" method="recent"></PLUGIN>
EOT

      result = <<"EOT"

<p>詳細な説明は<a href="TextFormat.html">TextFormat</a>をごらんください。</p>
<h3>見出し2</h3>
<h4>見出し3</h4>
<h5>見出し4</h5>
<h6>見出し5</h6>
<ul>
<li>箇条書レベル1
<ul>
<li>箇条書レベル2
<ul>
<li>箇条書レベル3</li></ul></li></ul></li></ul>
<ol>
<li>順序リスト1
<ol>
<li>順序リスト2
<ol>
<li>順序リスト3</li></ol></li></ol></li></ol><pre>整形済みテキスト。</pre>
<blockquote>
<p>引用。</p></blockquote>
<dl>
<dt>Wiki
</dt><dd>書き込み可能なWebページ
</dd><dt>QuickML
</dt><dd>簡単に作れるメーリングリストシステム</dd></dl>
<table>
<tbody>
<tr>
<td>項目1-1</td>
<td>項目1-2</td>
<td>項目1-3</td></tr>
<tr>
<td>項目2-1</td>
<td>項目2-2</td>
<td>項目2-3</td></tr></tbody></table>
<p><em>強調</em>、<strong>さらに強調</strong>、<del>取り消し線</del> <img alt="new" src="http://example.com/.theme/new.png"/> <a href="FrontPage.html">FrontPage</a> <a href="http://www.yahoo.co.jp/">Yahoo!</a></p><plugin method="recent" param="1"/>
EOT
      ok_wi(result, '{{html
'+html+'
}}')
    end
  end
end
