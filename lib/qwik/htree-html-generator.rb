# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH << 'compat' unless $LOAD_PATH.include? 'compat'
require 'htree'
$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/html-generator'
require 'qwik/htree-generator'

module HTree
  module HtmlGeneratorModule
    include GeneratorModule
    include HtmlGeneratorUnit
  end

  class HtmlGenerator
    include HtmlGeneratorModule
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  require 'qwik/htree-format-xml'
  $test = true
end

if defined?($test) && $test
  class TestHTreeHtmlGeneratorModule < Test::Unit::TestCase
    include HTree::HtmlGeneratorModule

    def test_html_generator_module
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
      ok_eq("<html><head><meta content=\"text/html; charset=SHIFT_JIS\" http-equiv=\"Content-Type\"/><title>タイトル</title><link href=\"style.css\" rel=\"stylesheet\" type=\"text/css\"/></head><body><pre><b>world</b>hello</pre><pre>This is <b>bold</b> text.</pre><pre>This is <i>italic</i> text.</pre><p>This is <a href=\"hoge\">anchor</a> text.</p><p>This is <a href=\"hoge\">anchor</a> text.</p><img src=\"new.gif\" alt=\"new\"/></body></html>", html.format_xml)
    end
  end

  class TestHTreeXmlGeneratorModule < Test::Unit::TestCase
    include HTree::GeneratorModule

    def ok(e, s)
      ok_eq(e, s.format_xml)
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

  class TestHTreeHtmlGenerator < Test::Unit::TestCase
    def ok(e, s)
      ok_eq(e, s.format_xml)
    end

    def test_htree_html_generator
      g = HTree::HtmlGenerator.new

      ok("<p/>", g.p)
      doc = HTree::Doc.new(g.p)
      ok("<p/>", doc)
      str = ''
      doc.display_xml(str)
      #ok_eq("<p xmlns=\"http://www.w3.org/1999/xhtml\"\n/>", str)

      ok("<meta content=\"text/html\" http-equiv=\"Content-Type\"/>",
	 g.contenttype('text/html'))
      ok("<meta content=\"0; url=t\" http-equiv=\"Refresh\"/>",
	 g.refresh(0, 't'))
      ok("<link href=\"style1.css\" rel=\"stylesheet\" type=\"text/css\"/>",
	 g.stylesheet('style1.css'))

      ok("<a href=\"t\">s</a>", g.a('t'){'s'}) # test_link
      ok("<a href=\"t?a\">s</a>", g.a("t?a"){'s'})
      ok("<a href=\"t?a&amp;b\">s</a>", g.a("t?a&b"){'s'})
      ok("<a href=\"t\">&lt;</a>", g.a('t'){"<"})

      ok("<input name=\"n\" type=\"submit\" value=\"t\"/>",
	 g.submit('t', 'n')) # test_form
      ok("<textarea name=\"\">t</textarea>", g.textarea{'t'})
      ok("<select name=\"n\"><option name=\"t1\">t1</option><option name=\"t2\">t2</option></select>", g.select('n', 't1', 't2'))

      ok("<input type=\"hidden\" name=\"n\"/>", g.hidden('n'))
      ok("<input type=\"hidden\" name=\"n\" value=\"v\"/>",
	 g.hidden('n', 'v'))
      ok("<input name=\"n\" id=\"i\" value=\"v\"/>",
	 g.hidden({:name=>'n', :value=>'v', :id=>'i'}))
      ok("<input name=\"n\" id=\"i\" value=\"v\"/>",
	 g.hidden(:name=>'n', :value=>'v', :id=>'i'))

      ok("<form>t</form>", g.form{'t'})
      ok("<form method=\"POST\">t</form>", g.form('POST'){'t'})
      ok("<form method=\"POST\" action=\"u\">t</form>",
	 g.form('POST', 'u'){'t'})
      ok("<form enctype=\"multipart/form-data\" method=\"POST\">t</form>",
	 g.form(:method=>'POST', :enctype=>'multipart/form-data'){'t'})

      # test_apos
      ok("&lt;&amp;", HTree::Text.new("<&"))
      ok("'", HTree::Text.new("'"))
      xml = g.p(:title => "What's New"){'t'}
      ok("<p title=\"What's New\">t</p>", xml)
      xml = g.p{"What's New"}
      ok("<p>What's New</p>", xml)

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
      ok("<html><head><meta content=\"text/html; charset=SHIFT_JIS\" http-equiv=\"Content-Type\"/><title>タイトル</title><link href=\"style.css\" rel=\"stylesheet\" type=\"text/css\"/></head><body><pre><b>world</b>hello</pre><pre>This is <b>bold</b> text.</pre><pre>This is <i>italic</i> text.</pre><p>This is <a href=\"hoge\">anchor</a> text.</p><p>This is <a href=\"hoge\">anchor</a> text.</p><img src=\"new.gif\" alt=\"new\"/></body></html>", html)

      ok_eq(<<'EOT'.chomp, html.format_xml(0))
<html
><head
><meta content="text/html; charset=SHIFT_JIS" http-equiv="Content-Type"
/><title
>タイトル</title
><link href="style.css" rel='stylesheet' type="text/css"
/></head
><body
><pre
><b
>world</b
>hello</pre
><pre
>This is <b
>bold</b
> text.</pre
><pre
>This is <i
>italic</i
> text.</pre
><p
>This is <a href='hoge'
>anchor</a
> text.</p
><p
>This is <a href='hoge'
>anchor</a
> text.</p
><img src="new.gif" alt='new'
/></body
></html
>
EOT
    end
  end
end
