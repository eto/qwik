# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/util-string'
require 'qwik/tokenizer'
require 'qwik/parser-inline'
require 'qwik/tokenizer-inline'
require 'qwik/html-to-wabisabi'
require 'qwik/wabisabi-validator'

module Qwik
  class TextParser
    # Make a tree from tokens.
    def self.make_tree(tokens)
      ar = []

      tokens.each {|token|
	tag = token.first
	case tag

	when :h2, :h3, :h4, :h5, :h6
	  ar << [tag, *inline(token[1])]

	when :ul, :ol
	  lu = ar
	  token[1].times {
	    if lu.last && lu.last.is_a?(Array) && lu.last.first == tag
	      lu = lu.last
	    else
	      a = [tag]
	      lu << a
	      lu = a
	    end
	  }
	  lu << [:li, *inline(token[2])]

	when :pre, :blockquote
	  if ar.last && ar.last.first == tag
	    ar.last[1] << "\n"+token[1]
	  else
	    ar << [tag, token[1]]
	  end

	when :dl
	  a = []
	  a << [:dt, *inline(token[1])] if token[1]
	  a << [:dd, *inline(token[2])] if token[2]
	  if ar.last && ar.last.first == tag
	    ar.last << a[0]
	    ar.last << a[1] if a[1]
	  else
	    ar << [tag, *a]
	  end

	when :table
	  token.shift
	  table_ar = token.map {|td|
	    inline_ar = inline(td)
	    inline_ar << '' if inline_ar.empty?
	    [:td] + inline_ar
	  }
	  tr = [:tr] + table_ar
	  if ar.last && ar.last.first == tag
	    ar.last << tr
	  else
	    ar << [tag, tr]
	  end

	when :text
	  line_ar = inline(token[1])
	  if ar.last && ar.last.is_a?(Array) && ar.last.first == :p
	    ar[-1] << "\n" if ar.last.last != [:br]
	    ar[-1] += line_ar
	  else
	    ar << [:p, *line_ar]
	  end

	when :empty
	  ar << ["\n"]

	when :plugin
	  ar << parse_plugin(token)

	when :html
	  ar << parse_html(token)

	else
	  ar << token
	end
      }

      nar = []
      ar.each {|block|
	tag = block.first
	case tag
	when :blockquote
	  str = block[1]

	  tokens = TextTokenizer.tokenize(str)
	  tree = make_tree(tokens)		# Recursive.
	  nar << [tag, *tree]

	when :p
	  while block[1] == [:br]
	    block.delete_at(1)
	  end
	  while block.last == [:br]
	    block.pop
	  end
	  nar << block
	else
	  nar << block
	end
      }

      return nar
    end

    def self.inline(str)
      return str if str.is_a? Array

      tokens = InlineTokenizer.tokenize(str)
      tree = InlineParser.make_tree(tokens)
      return tree
    end

    def self.parse_plugin(token)
      method = token[1].to_s
      param = token[2].to_s
      plugin = [:plugin, {:method=>method, :param=>param}]
      plugin << token[3].to_s if token[3]
      return plugin
    end

    def self.parse_html(token)
      str = token[1]
      wabisabi = HtmlToWabisabi.parse(str)

      v = WabisabiValidator.valid?(wabisabi)
      if v == true
	return [:html, *wabisabi]
      else
	return [:div, {:class=>'error'}, "can not use [#{v}]"]
      end
    end

  end
end

if $0 == __FILE__
  if ARGV[0] == '-b'
    $bench = true
  else
    require 'qwik/testunit'
    $test = true
  end
end

if defined?($test) && $test
  class TestParser < Test::Unit::TestCase
    def ok(e, str)
      tokens = Qwik::TextTokenizer.tokenize(str)
      ok_eq(e, Qwik::TextParser.make_tree(tokens))
    end

    def test_all
      # test none
      ok([], '')
      ok([["\n"]], "#t")

      # test p
      ok([[:p, 't']], 't')
      ok([[:p, 's', "\n", 't']], "s\nt")
      ok([[:p, 's'], ["\n"], [:p, 't']], "s\n\nt")
      ok([[:p, 's', [:br], 't']], "s~\nt~")

      ok([[:dl, [:dt, 'dt1'], [:dd, 'dd1']], [:p, 'p1'],
	       [:dl, [:dd, 'dd2']]], ":dt1:dd1\np1\n::dd2")

      # test header
      ok([[:h2, 't']], '*t')
      ok([[:h2, 't'], [:p, 't']], "*t\nt")
      ok([[:h3, 't']], '**t')
      ok([[:h4, 't']], '***t')
      ok([[:h5, 't']], '****t')
      ok([[:h6, 't']], '*****t')
      ok([[:h6, '*t']], '******t')
      ok([[:h6, '**t']], '*******t')

      # test_ignore_space
      ok([[:h2, 't']], '* t')
      ok([[:h2, 't']], '*t ')
      ok([[:h2, 't']], '* t ')
      ok([[:h3, 't']], '** t')
      ok([[:h3, 't']], '**t ')
      ok([[:h3, 't']], '** t ')

      # test listing
      ok([[:ul, [:li, 't']]], '-t')
      ok([[:ul, [:ul, [:li, 't']]]], '--t')
      ok([[:ul, [:ul, [:ul, [:li, 't']]]]], '---t')
      ok([[:ul, [:li, 't']], [:p, 't']], "-t\nt")
      ok([[:ul, [:li, 't'], [:li, 't']]], "-t\n-t")
      ok([[:ul, [:li, 't'], [:ul, [:li, 't']]]], "-t\n--t")
      ok([[:ul, [:ul, [:li, 't']], [:li, 't']]], "--t\n-t")
      ok([[:ul, [:ul, [:li, 't']], [:li, 't'], [:ul, [:li, 't']]]],
	     "--t\n-t\n--t")
      ok([[:ol, [:li, 't']]], "+t")
      ok([[:ul, [:li, 't']], [:ol, [:li, 't']]], "-t\n+t")
      ok([[:ul, [:li, 't1']], ["\n"], [:ul, [:li, 't2']]], "-t1\n\n-t2")
      ok([["\n"], [:ul, [:li, 't1'], [:li, 't2']]], "\n-t1\n-t2")

      # test blockquote
      ok([[:blockquote, [:p, 't']]], ">t")
      ok([[:blockquote, [:p, 's', "\n", 't']]], ">s\n>t")
      ok([[:blockquote, [:ul, [:li, 's'], [:li, 't']]]], ">-s\n>-t")

      # test dl
      ok([[:dl, [:dt, 'dt'],[:dd, 'dd']]], ':dt:dd')
      ok([[:dl, [:dt, 'dt']]], ':dt')
      ok([[:dl]], ':')
      ok([[:dl]], '::')
      ok([[:dl, [:dd, 'dd']]], '::dd')
      ok([[:dl, [:dt, 'dt'], [:dd, 'dd'], [:dt, 'dt2'], [:dd, 'dd2']]],
	     ":dt:dd\n:dt2:dd2")
      ok([[:dl, [:dt, 'dt'], [:dd, 'dd'], [:dd, 'dd2']]], ":dt:dd\n::dd2")

      # test pre
      ok([[:pre, 't']], ' t')
      ok([[:pre, "s\nt"]], " s\n t")

      ok([[:pre, "s\n"]], "{{{\ns\n}}}")
      ok([[:pre, "s\nt\n"]], "{{{\ns\nt\n}}}")
      ok([[:pre, "#s\n"]], "{{{\n#s\n}}}")

      ok([[:pre, 't1'], ["\n"], [:pre, 't2']], " t1\n\n t2")

      # test_table
      ok([[:table, [:tr, [:td, 't']]]], ',t')
      ok([[:table, [:tr, [:td, 't1'], [:td, 't2']]]], ',t1,t2')
      ok([[:table, [:tr, [:td, ''], [:td, 't2']]]], ',,t2')
      ok([[:table, [:tr, [:td, 's']], [:tr, [:td, 't']]]], ",s\n,t")
      ok([[:table, [:tr, [:td, 's1'], [:td, 's2']],
		 [:tr, [:td, 't1'], [:td, 't2']]]], ",s1,s2\n,t1,t2")

      # test plugin
      ok([[:plugin, {:method=>'t', :param=>''}]], "{{t}}")
      ok([[:plugin, {:method=>'t', :param=>'a'}]], "{{t(a)}}")
      ok([[:plugin, {:method=>'t', :param=>""}, "s\n"]], "{{t\ns\n}}")
      ok([[:plugin, {:method=>'t', :param=>""}, "s1\ns2\n"]],
	     "{{t\ns1\ns2\n}}")

      # test_multiline
      ok([[:p, 's', "\n", 't']], "s\nt")
      ok([[:p, 's', [:br], 't']], "s~\nt~")
      ok([[:p, 's'], ["\n"], [:p, 't']], "s\n\nt")
      ok([[:p, 's', [:br], [:br], 't']], "s~\n~\nt~")

      str = <<'EOT'
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
EOT
      ok([[:p, 'p1'],
	       [:blockquote,  [:p, 'b1', [:br], 'b2'],
		 [:blockquote, [:p, 'bb1', [:br], 'bb2']],
		 [:p, 'b3', [:br], 'b4']],
	       [:p, 'p2']],
	     str)

      # test_html
      ok([[:html, "t\n"]], "<html>\nt\n</html>")
      ok([[:div, {:class=>'error'}, "can not use [script]"]],
	     "<html>\n<script>t</script>\n</html>")

      # test_ref
      ok([[:ul, [:li, [:a, {:href=>'http://e.com/'}, 't']]]],
	     "- [http://e.com/ t]")

      # test_hr
      ok([[:hr]], "====")

      # test_bug
      ok_eq("\226]", '–]')
      ok([[:p, [:a, {:href=>"\226].html"}, "\226]"]]], '[[–]]]')
    end

    def test_from_resolve
      # test_lines
      ok([[:ul, [:li, 't1'], [:li, 't2']]], "- t1\n- t2")
      ok([[:p, 't1'], [:ul, [:li, 't2']]], "t1\n- t2")

      # test_qwik_text
      ok([[:ul, [:li, 't']]], '- t')
      ok([[:ul, [:li, 's'], [:ul, [:li, 't']]]], "- s\n-- t")
      ok([[:ol, [:li, 't']]], "+ t")

      # test_ul
      ok([[:ul, [:li, 't1']], ["\n"], [:ul, [:li, 't2']]], "- t1\n\n- t2")
    end

    def test_format
      # test_inline
      ok([[:p, [:em, 't']]], "''t''")
      ok([[:p, [:a, {:href=>'t.html'}, 't']]], "[[t]]")
      ok([[:p, [:a, {:href=>'1.html'}, '1']]], "[[1]]")
      ok([[:p, [:plugin, {:method=>'interwiki', :param=>'Test:t'}, 'Test:t']]],
	 "[[Test:t]]")
      ok([[:plugin, {:method=>'t', :param=>''}]], "{{t}}")
      ok([[:p, 'a', [:plugin, {:method=>'t', :param=>''}, ''], 'b']], "a{{t}}b")
      ok([[:p, [:a, {:href=>'http://e.com/'}, 'http://e.com/']]],
	 'http://e.com/')
      ok([[:p, 'a ', [:a, {:href=>'http://e.com/'}, 'http://e.com/'], ' b']],
	 'a http://e.com/ b')

      # test_escape
      ok([[:h2, "'"]], "*'")
      ok([[:h2, "<"]], "*<")

      # test_sjis
      ok([[:h2, "\202\240"]], "* ‚ ")
      ok([[:h3, "\202\240"]], "** ‚ ")
      ok([[:h3, "\212\277\216\232"]], "** Š¿Žš")
      ok([[:h3, "\221\322"]], "** ‘Ò")

      # test ?
      ok([[:h2, [:a, {:href=>'t.html'}, 't']]], "*[[t]]")
      ok([[:h2, [:a, {:href=>'t.html'}, 't']]], "* [[t]]")
      ok([[:h2, [:a, {:href=>'t.html'}, 't']]], "* [[t]] ")
      ok([[:h2, [:a, {:href=>'t.html'}, 't'], ' a']], "* [[t]] a")
      ok([[:h2, [:a, {:href=>'t.html'}, 't'], '  a']], "* [[t]]  a")

      # test_format
      ok([[:h2, "<"]], "*<")
      ok([[:p, [:strong, '']]], "''''''")
    end
  end
end
