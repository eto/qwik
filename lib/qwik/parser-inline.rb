# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class InlineParser
    URL = '(?:http|https|ftp|mailto|file):[a-zA-Z0-9;/?:@&=+$,\-_.!~*\'()#%]+'

    INLINE_PATTERNS = {
      :"'''"=>:strong,
      :"''"=>:em,
      :'=='=>:del,
    }

    def self.make_tree(line_ar)
      root = []
      stack = []
      stack << root
      in_tag = {}

      line_ar.each {|t|
	if t.is_a?(Symbol)
	  if in_tag[t]
	    in_tag[t] = nil
	    if stack.last.length == 1	# bad hack
	      stack.last << ''
	    end
	    stack.pop if 1 < stack.length
	  else
	    in_tag[t] = true
	    ar = [INLINE_PATTERNS[t]]
	    stack.last << ar
	    stack << ar
	  end

	else
	  if t.is_a? Array
	    elem = t.first
	    case elem
	    when :ref
	      stack.last << parse_ref(t[1])
	    when :plugin
	      stack.last << parse_plugin(t)
	    when :url
	      stack.last << [:a, {:href=>t[1]}, t[1]]
	    else
	      # do nothing
	    end

	  else
	    stack.last << t
	  end
	end
      }

      # bad hack
      if stack.last.length == 1 && stack.last.is_a?(Array) &&
	  stack.last.first.is_a?(Symbol)
	stack.last << ''
      end

      return root
    end

    def self.parse_plugin(t)
      method = t[1].to_s
      param = t[2].to_s
      data = t[3].to_s
      return [:br] if method == 'br'	# shortcut
      return [:plugin, {:method=>method, :param=>param}, data]
    end

    def self.parse_ref(uri)
      text, uri = $1, $2 if /\A([^|]*)\|(.+)\z/s =~ uri
      if text.nil? or text.empty?
        text = uri
      end

      case uri
      when /\A#{URL}/o
        if /\.(?:jpg|jpeg|png|gif)\z/i =~ uri
          [:img, {:src=>uri, :alt=>text}]
        else
          [:a, {:href=>uri}, text]
        end
      when /\A(.+?):(.+)\z/
        [:plugin, {:method=>'interwiki', :param=>uri}, text]
      else
        uri = "#{uri}.html" unless uri.include?('.')
        [:a, {:href=>uri}, text]
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
  require 'qwik/tokenizer-inline'

  class TestInlineParser < Test::Unit::TestCase
    def ok(e, str)
      tokens = Qwik::InlineTokenizer.tokenize(str)
      tree = Qwik::InlineParser.make_tree(tokens)
      ok_eq(e, tree)
    end

    def test_all
      ok([], '')
      ok(['t'], 't')

      # test em, strong and del
      ok([[:em, 't']], "''t''")
      ok([[:strong, 't']], "'''t'''")
      ok([[:strong, 't', [:em, '']]], "'''t''")
      ok(["'"], "'")
      ok(["'", 't'], "'t")
      ok([[:del, 't']], '==t==')
      ok(['='], '=')
      ok(['=', 't'], '=t')
      ok(['a ',[:em,'b ',[:strong,'c'],' d'],' e'], "a ''b '''c''' d'' e")
      # FIXME: Take care of incomplete patterns.
      ok([[:em, 'a', [:strong, 'b', [:del, 'c']]]], "''a'''b==c")
      ok([[:strong, '']], "''''''")
      ok(['a', [:em, 'b', [:strong, 'c'], 'd'], 'e'], "a''b'''c''d'''e")
      ok(['a', [:del, 'b', [:em, 'c'], 'd'], 'e'], "a==b''c==d''e")

      # test_ref
      ok([[:a, {:href=>'t.html'}, 't']], '[[t]]')
      ok([[:a, {:href=>'t.html'}, 's']], '[[s|t]]')
      ok([[:a, {:href=>'http://e.com/'}, 'e']], '[[e|http://e.com/]]')
      ok([[:plugin, {:method=>'interwiki', :param=>'w:p'}, 'w:p']],
	 '[[w:p]]')
      ok([']'], ']')
      ok(['[', 't', ']'], '[t]')
      ok([[:a, {:href=>'http://e.com/'}, 't']], '[http://e.com/ t]')

      ok([[:a, {:href=>'C++.html'}, 'C++']], '[[C++]]')

      # test_plugin
      ok([[:plugin, {:method=>'t', :param=>''}, '']], '{{t}}')
      ok([[:plugin, {:method=>'t', :param=>'a'}, '']], '{{t(a)}}')
      ok(['{', 't', '}'], '{t}')
      #ok(['{', '{', '}}'], '{{}}')	# regexp version.
      ok(['{{}}'], '{{}}')		# strscan version.
      ok([[:br]], '{{br}}') # shotcut

      # test_url
      ok([[:a, {:href=>'http://e.com/'}, 'http://e.com/']], 'http://e.com/')
      ok([[:a, {:href=>'https://e.com/'}, 'https://e.com/']],
	 'https://e.com/')
      ok(['t ', [:a, {:href=>'http://e.com/'}, 'http://e.com/'], ' a'],
	 't http://e.com/ a')

      # test etc. at a time
      ok(['a ', [:em, 'b'], ' ', [:strong, 'c'], ' ', [:del, 'd'], ' ',
	   [:a, {:href=>'e.html'}, 'e'], ' ',
	   [:plugin, {:method=>'f', :param=>''}, ''], ' ',
	   [:a, {:href=>'http://e.com/'}, 'http://e.com/'], ' g'],
	 "a ''b'' '''c''' ==d== [[e]] {{f}} http://e.com/ g")

      # test_img
      ok([[:img, {:alt=>'http://e.com/t.jpg', :src=>'http://e.com/t.jpg'}]],
	 '[[http://e.com/t.jpg]]')
      ok([[:img, {:alt=>'m', :src=>'http://e.com/t.jpg'}]],
	 '[[m|http://e.com/t.jpg]]')

      # test_security
      ok([[:a, {:href=>'t.html'}, 't']], '[[t]]')
      ok([[:a, {:href=>'http://e.com/'}, 'http://e.com/']],
	 '[[http://e.com/]]')
      ok([[:plugin, {:param=>'javascript:t', :method=>'interwiki'},
	     'javascript:t']],
	 '[[javascript:t]]') # Treated as InterWiki
      ok([[:a, {:href=>"&{alert('hello');};.html"}, "&{alert('hello');};"]],
	 "[[&{alert('hello');};]]")

      # test_bug
      ok([[:a, {:href=>"\226].html"}, "\226]"]], '[[–]]]')
    end
  end

  class TestInlineParser_parse_ref < Test::Unit::TestCase
    def ok(e, str)
      ok_eq(e, Qwik::InlineParser.parse_ref(str))
    end

    def test_all
      # normal ref
      ok([:a, {:href=>'t.html'}, 't'], 't')
      ok([:a, {:href=>'http://e.com/'}, 'http://e.com/'], 'http://e.com/')

      # with title
      ok([:a, {:href=>'t.html'}, 's'], 's|t')
      ok([:a, {:href=>'http://e.com/'}, 's'], 's|http://e.com/')

      # interwiki
      ok([:plugin, {:param=>'s:t', :method=>'interwiki'}, 's:t'], 's:t')
      ok([:plugin, {:param=>'s:t', :method=>'interwiki'}, 'foo'], 'foo|s:t')

      # test_plugin_ref
      ok([:a, {:href=>'.attach'}, '.attach'], '.attach')
      ok([:a, {:href=>'.attach/t.txt'}, '.attach/t.txt'], '.attach/t.txt')
      ok([:a, {:href=>'.attach/s t.txt'}, '.attach/s t.txt'],
	 '.attach/s t.txt')

      # test_img
      ok([:img, {:alt=>'http://e.com/t.jpg', :src=>'http://e.com/t.jpg'}],
	 'http://e.com/t.jpg')
      ok([:img, {:alt=>'s', :src=>'http://e.com/t.jpg'}],
	 's|http://e.com/t.jpg')

      # test security
      ok([:a, {:href=>"&{alert('hello');};.html"}, "&{alert('hello');};"],
	 "&{alert('hello');};")

      # test_sjis_bug
      ok_eq("\203|\203X", 'ƒ|ƒX')
      ok([:a, {:href=>"\203|\203X.html"}, "\203|\203X"], 'ƒ|ƒX')

      # test_bug
      ok_eq("\226]", '–]')
      ok([:a, {:href=>"\226].html"}, "\226]"], '–]')

      # abnormal cases
      ok([:a, {:href=>'|.html'}, '|'],      '|')
      ok([:a, {:href=>'|.html'}, '|'],      '||')
      ok([:a, {:href=>'||.html'}, '||'],    '|||')
      ok([:a, {:href=>'s|.html'}, 's|'],    's|')
      ok([:a, {:href=>'s.html'},  's'],    '|s')
      ok([:a, {:href=>'http://example.com'}, 'http://example.com'],    '|http://example.com')
      ok([:plugin, {:param=>'s:t', :method=>'interwiki'}, 's:t'], '|s:t')
    end
  end
end

if defined?($bench) && $bench
  require 'qwik/bench-module-session'

  def ok(e, str)
    tree = Qwik::InlineParser.parse(str)
  end

  def main
    n = 10000

# 10000 times.
#  5.460000   0.220000   5.680000 (  5.683599)
#  5.460000   0.180000   5.640000 (  5.641708)
#  5.480000   0.350000   5.830000 (  5.840561)

    BenchmarkModule::benchmark {
      n.times {
	ok(['a ', [:em, 'b'], ' ', [:strong, 'c'], ' ', [:del, 'd'], ' ',
	     [:a, {:href=>'e.html'}, 'e'], ' ',
	     [:plugin, {:method=>'f', :param=>''}, ''], ' ',
	     [:a, {:href=>'http://e.com/'}, 'http://e.com/'], ' g'],
	   "a ''b'' '''c''' ==d== [[e]] {{f}} http://e.com/ g")
      }
    }
  end
  main
end
