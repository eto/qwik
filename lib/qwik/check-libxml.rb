# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/test-common'

begin
  require 'xml/libxml'
  $have_libxml_so = true
rescue LoadError
  $have_libxml_so = false
end

if $0 == __FILE__
  $test = true
end

class TestLibXml < Test::Unit::TestCase
  def test_parser
    str = <<'EOT'
<html><head id='header'><title>FrontPage - example.com/test</title><link href="/.theme/qwikgreen/qwikgreen.css" rel='stylesheet' media="screen,tv,print" type="text/css"/><link href="/.theme/base.css" rel='stylesheet' media="screen,tv,print" type="text/css"/></head><body><div class='container'><div class='main'><div class='adminmenu' id='adminmenu'><p><span class='loginstatus'>user | <em>user@e.com</em> (<a href=".logout">.logout</a>)</span></p>
<ul><li><a href=".new">新規作成</a></li>
<li><a href="FrontPage.edit">編集</a></li>
</ul>
</div><h1 id="view_title">FrontPage</h1><div id='body'><div class='day'><h2>FrontPage</h2><div class='body'><div class='section'>
<p>これは新規qwikWebサイトの入口となるページです。</p>
<h3>使い方</h3>
<p>ページの上の方にある「編集」というリンクをたどると、このページの編集モードになります。</p>
<p>表示されたテキストの内容を変更し、「Save」ボタンをクリックすると、このページの内容が変更されます。</p>
<h3>記述方法</h3>
<p>ページの内容はテキストで書かれており、いくつかの記号によって見出しなどの指定をします。詳しい情報は、<a href="/test/TextFormat.html">TextFormat</a>をご覧下さい。</p>
<h3>qwikWeb</h3>
<p>詳しくは、<a href="http://example.com/" class='external'>qwikWeb</a>ホームページをご覧ください。</p>
<h3>QuickML</h3>
<p>メーリングリスト機能の使い方は、<a href="http://www.quickml.com/" class='external'>QuickML</a>ホームページをご覧ください。</p>
</div></div></div></div><div id="body_leave"><div class='day'><div class='comment'><div class='caption'><div class="page_attribute"><p><div class='qrcode'><a href="http://example.com/test/" class='external'><img src=".attach/qrcode-test.png" alt="http://example.com/test/"/><br/>http://example.com/test/</a></div><div>last modified: 2004-05-20</div></p>
</div></div></div><div class="body_leave"></div></div></div></div><div class='sidebar' id='sidemenu'><h2>menu</h2>
<ul><li><a href="/test/FrontPage.html">FrontPage</a></li>
<li><a href="/test/TitleList.html">TitleList</a></li>
<li><a href="/test/RecentList.html">RecentList</a></li>
<li><a href="/test/TextFormat.html">TextFormat</a></li>
<li><a href="/test/_SiteMenu.html">_SiteMenu</a></li>
</ul>
<h2>recent change</h2>
<p><h3>2004-09-09</h3>
<ul><li><a href="/test/_SiteMember.html">_SiteMember</a></li>
</ul>
</p>
</div><div class='footer' id='footer'><p>powered by <a href="http://example.com/" class='external'>qwikWeb</a></p>
</div></div></body></html>
EOT

    if $have_libxml_so
      ok_eq('2.6.11', XML::Parser::LIBXML_VERSION)
      ok_eq(28, XML::Parser::VERNUM)
      xp = XML::Parser.new
      xp.string = str.page_to_xml
      doc = xp.parse
      assert_instance_of(XML::Document, doc)
      e = nil
      doc.find('//a'){|ee|
	e = ee
      }
    end
  end

  def test_text
    if $have_libxml_so
      xp = XML::Parser.new
      xp.string = '<html><p><b>a</b></p></html>'
      doc = xp.parse
      assert_instance_of(XML::Document, doc)
      e = nil
      doc.find('//title'){|e|
	e = ee
      }
    end
  end
end

class TestAssertXPath < Test::Unit::TestCase
  include TestSession

  def test_ok_xp
    t_add_user
    session('/test/')
    ok_in(['FrontPage'], '//h1')
    ok_xp([:a, {:href=>'.logout'}, 'Logout'], '//a')
    ok_in(['Logout'], '//a')
  end
end

class CheckLibXml_OriginalTest < Test::Unit::TestCase
  def make_sample_xml
    str = "<nodes>\n"
    10000.times {|i|
      str << '<node sum="1" avg="'+i.to_s+'">Node sample text</node>'+"\n"
    }
    str << "</nodes>\n"
    str
  end

  def nutest_rexml #9.851 seconds.
    require 'rexml/document'
    xmlStr = make_sample_xml
    doc = REXML::Document.new xmlStr
    sum = avgSum = count = 0
    doc.elements.each('/nodes/node') { |e|
      count += 1
      sum += e.attributes['sum'].to_i
      avgSum += e.attributes['avg'].to_i
    }
    puts "count(node): #{count}, sum(sum): #{sum}, avg(avg): #{avgSum/count}"
  end

  def nutest_libxml #4.685 seconds
    require 'xml/libxml'
    xmlStr = make_sample_xml
    xp = XML::Parser.new
    xp.string = xmlStr
    doc = xp.parse
    sum = avgSum = count = 0
    doc.find('/nodes/node').each { |e|
      count += 1
      sum += e['sum'].to_i
      avgSum += e['avg'].to_i
    }
    puts "count(node): #{count}, sum(sum): #{sum}, avg(avg): #{avgSum/count}"
  end

  def test_dummy #0.117 seconds.
    xmlStr = make_sample_xml
  end
end
