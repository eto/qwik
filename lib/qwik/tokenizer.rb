# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

require 'strscan'

module Qwik
  class TextTokenizer
    MULTILINE = {
      :plugin => [
	/\A\{\{([^\(\)\{\}]+?)(?:\(([^\(\)\{\}]*?)\))?\z/,
	/\A\}\}\z/
      ],
      :pre => [
	/\A\{\{\{\z/,
	/\A\}\}\}\z/
      ],
      :html => [
	/\A\<html\>\z/,
	/\A\<\/html\>\z/
      ],
    }

    # Tokenize a text.
    def self.tokenize(str, br_mode=false)
      tokens = []
      in_multiline = {}

      scanner = StringScanner.new(str)
      while ! scanner.eos?
	line = scanner.scan(/.*$/)
	newline = scanner.scan(/\n/)

	line.chomp!

	# At the first, check if it is in a multiline block.
	last_token = tokens.last
	if last_token
	  last_tag = last_token[0] 
	  if in_multiline[last_tag]
	    if MULTILINE[last_tag][1] =~ line
	      in_multiline[last_tag] = nil
	    else
	      last_token[-1] += "#{line.chomp}\n"
	    end
	    next
	  end
	end

	line.chomp!

	# preprocess
	#line.gsub!(/&my-([0-9]+);/) {|m| "{{my_char(#{$1})}}" }

	case line
	when MULTILINE[:plugin][0]
	  in_multiline[:plugin] = true
	  tokens << [:plugin, $1.to_s, $2.to_s, '']
	when MULTILINE[:pre][0]
	  in_multiline[:pre] = true
	  tokens << [:pre, '']
	when MULTILINE[:html][0]
	  tokens << [:html, '']
	  in_multiline[:html] = true
	when /\A====+\z/, '-- ', /\A----+\z/		# hr
	  tokens << [:hr]
	when /\A(\-{1,3})(.+)\z/			# ul
	  tokens << [:ul, $1.size, $2.to_s.strip]
	when /\A(\+{1,3})(.+)\z/			# ol
	  tokens << [:ol, $1.size, $2.to_s.strip]
	when /\A>(.*)\z/				# blockquote
	  tokens << [:blockquote, $1.strip]
	when /\A[ \t](.*)\z/				# pre
	  tokens << [:pre, $1]
	when /\A\{\{([^\(\)\{\}]+?)(?:\(([^\(\)\{\}]*?)\))?\}\}\z/	# plugin
	  tokens << [:plugin, $1.to_s, $2.to_s]
	when '', /\A#/					# '', or comment.
	  tokens << [:empty]				# empty line
	when /\A([,|])(.*)\z/				# pre
	  re = Regexp.new(Regexp.quote($1), nil, 's')
	  ar = [:table] + $2.split(re).map {|a| a.to_s }
	  tokens << ar
	when /\A:(.*)\z/				# dl
	  rest = $1
	  dt, dd = rest.split(':', 2)
	  if dt && dt.include?('(')
	    if /\A(.*?\(.*\)[^:]*):(.*)\z/ =~ rest	# FIXME: Bad hack.
	      dt, dd = $1, $2
	    end
	  end
	  ar = [:dl]
	  ar << ((dt && ! dt.empty?) ? dt.to_s.strip : nil)
	  ar << ((dd && ! dd.empty?) ? dd.to_s.strip : nil)
	  tokens << ar
	when /\A([*!]{1,5})\s*(.+)\s*\z/		# h
	  h = $1
	  s = $2
	  s = s.strip
	  if s.empty?		# '* '
	    inline(tokens, line, br_mode)
	  else
	    tokens << [("h#{h.size+1}").intern, s]
	  end
	else
	  inline(tokens, line, br_mode)
	end
      end

      return tokens
    end

    private

    def self.inline(tokens, line, br_mode)
      if /~\z/s =~ line
	line = line.sub(/~\z/s, '{{br}}')	# //s means shift_jis
      elsif br_mode
	line = "#{line}{{br}}"
      end
      tokens << [:text, line]
    end
  end
end

if $0 == __FILE__
  $LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
  if ARGV[0] == '-b'
    $bench = true
  else
    require 'qwik/testunit'
    $test = true
  end
end

if defined?($test) && $test
  class TestTokenizer < Test::Unit::TestCase
    def ok(e, str)
      ok_eq(e, Qwik::TextTokenizer.tokenize(str))
    end

    def test_all
      ok([], '')
      ok([[:empty]], '#t')
      ok([[:hr]], '====')
      ok([[:text, '===']], '===')

      # test_h
      ok([[:text, '*']], '*')
      ok([[:h2, 't']], '*t')
      ok([[:h2, 't']], '* t')
      ok([[:h2, 't']], '*t ')
      ok([[:h2, 's t']], '* s t')
      ok([[:text, '* ']], '* ')
      ok([[:text, '*']], '*')
      ok([[:h3, 't']], '**t')
      ok([[:h4, 't']], '***t')
      ok([[:h5, 't']], '****t')
      ok([[:h6, 't']], '*****t')

      # test_!
      ok([[:h2, 't']], '! t')

      ok([[:text, '-']], '-')
      ok([[:ul, 1, 't']], '-t')
      ok([[:ul, 1, 't']], '- t')
      ok([[:ul, 2, 't']], '--t')
      ok([[:ul, 3, 't']], '---t')
      ok([[:ul, 3, '-t']], '----t') # uum...
      ok([[:ul, 1, '-']], '--')
      ok([[:hr]], '-- ')
      ok([[:hr]], '----')
      ok([[:text, '+']], '+')
      ok([[:ol, 1, 't']], '+t')
      ok([[:blockquote, 't']], '>t')
      ok([[:blockquote, 't']], '> t')

      # test dl
      ok([[:dl, 'dt', 'dd']], ':dt:dd')
      ok([[:dl, 'dt', nil]], ':dt')
      ok([[:dl, nil, nil]], ':')
      ok([[:dl, nil, 'dd']], '::dd')
      ok([[:dl, nil, nil]], '::')
      ok([[:dl, 'dt', 'dd'], [:dl, 'dt2', 'dd2']], ":dt:dd\n:dt2:dd2")

      ok([[:pre, 't']], ' t')
      ok([[:pre, 't']], "\tt")

      # test_table
      ok([[:table, 't']], ',t')
      #ok([[:table, 't']], ', t')
      ok([[:table, ' t']], ', t')
      ok([[:table, 's', 't']], ',s,t')
      ok([[:table, '', 't']], ',,t')
      ok([[:table, 't']], '|t')
      ok([[:table, '$t']], ',$t')
      ok([[:table, '$1']], ',$1')

      ok([[:text, '{t}']], '{t}')
      ok([[:plugin, 't', '']], '{{t}}')
      ok([[:plugin, 't', 'a']], '{{t(a)}}')
      ok([[:plugin, 't', '', '']], '{{t')
      ok([[:plugin, 't', 'a', '']], '{{t(a)')
      ok([[:plugin, 't', '', "s\n"]], "{{t\ns\n}}")
      ok([[:plugin, 't', 'a', "s\n"]], "{{t(a)\ns\n}}")

      ok([[:pre, "s\n"]], "{{{\ns\n}}}")
      ok([[:pre, "s\nt\n"]], "{{{\ns\nt\n}}}")
      ok([[:pre, "#s\n"]], "{{{\n#s\n}}}")

      ok([[:empty]], "\n")
      ok([[:text, 't']], 't')
      ok([[:text, 's'], [:text, 't']], "s\nt")
      ok([[:text, 's'], [:empty], [:text, 't']], "s\n\nt")

      # test_html
      ok([[:text, '<t']], '<t')
      ok([[:html, '']], '<html>')
      ok([[:html, "t\n"]], "<html>\nt\n</html>")
      ok([[:html, "<p>\nt\n</p>\n"]], "<html>\n<p>\nt\n</p>\n</html>")

      # test_sjis_bug
      ok([[:table, '•|', '•|']], ',•|,•|')
      ok([[:table, 's', 't']], '|s|t')
      ok([[:table, '•|', '•|']], '|•||•|')

      # test_multiline
      ok([[:text, 's'], [:text, 't']], "s\nt")
      ok([[:text, 's{{br}}'], [:text, 't{{br}}']], "s~\nt~")
      ok([[:text, 's'], [:empty], [:text, 't']], "s\n\nt")
      ok([[:text, "s{{br}}"], [:text, "{{br}}"], [:text, "t{{br}}"]],
	 "s~\n~\nt~")

      # test_ul
      ok([[:ul, 1, 't'], [:ul, 1, 't']], "-t\n-t")
      ok([[:ul, 1, 't'], [:empty], [:ul, 1, 't']], "-t\n\n-t")
      ok([[:empty], [:ul, 1, 't'], [:ul, 1, 't']], "\n-t\n-t")

      # test_multiline_pre
      ok([[:pre, 't']], ' t')
      ok([[:pre, 't1'], [:pre, 't2']], " t1\n t2")
      ok([[:pre, 't1'], [:empty], [:pre, 't2']], " t1\n\n t2")

      # test_ref
      # do not parse inline for this moment.
      ok([[:text, "[[t]]"]], "[[t]]")

      # test_super_pre
      ok([[:pre, "p\n"], [:text, 't']], "{{{\np\n}}}\nt\n")
      ok([[:pre, "#p\n"], [:text, 't']], "{{{\n#p\n}}}\nt\n")

      # test_in_bracket # bad hack
      ok([[:dl, 'dt', 'dd']], ':dt:dd')
      ok([[:dl, "dt(h:m)dt2", 'dd']], ":dt(h:m)dt2:dd")
      ok([[:dl, 'u', 'h://e.com/']], ':u:h://e.com/')
      ok([[:dl, "dt(h:m)", 'h://e.com/']], ":dt(h:m):h://e.com/")
      ok([[:dl, "dt(h:m)dt2", 'h://e.com/']], ":dt(h:m)dt2:h://e.com/")
    end
  end

  class TestTokenizerWithBR < Test::Unit::TestCase
    def ok(e, str)
      ok_eq(e, Qwik::TextTokenizer.tokenize(str, true))
    end

    def test_all
      ok([[:text, "==={{br}}"]], "===")
      ok([[:text, "*{{br}}"]], '*')
      ok([[:text, "* {{br}}"]], '* ')
      ok([[:text, "*{{br}}"]], '*')
      ok([[:text, "-{{br}}"]], '-')
      ok([[:text, "+{{br}}"]], "+")
      ok([[:text, "{t}{{br}}"]], "{t}")
      ok([[:text, "t{{br}}"]], 't')
      ok([[:text, "s{{br}}"], [:text, "t{{br}}"]], "s\nt")
      ok([[:text, "s{{br}}"], [:empty], [:text, "t{{br}}"]], "s\n\nt")

      # test table
      ok([[:table, 'a', 'b']], '|a|b|')

      # test_multiline
      ok([[:text, "s{{br}}"], [:text, "t{{br}}"]], "s\nt")
      ok([[:text, "s{{br}}"], [:text, "t{{br}}"]], "s~\nt~") # no change
      ok([[:text, "s{{br}}"], [:empty], [:text, "t{{br}}"]], "s\n\nt")
      ok([[:text, "s{{br}}"], [:text, "{{br}}"], [:text, "t{{br}}"]],
	 "s~\n~\nt~") # no change

      # test_ref
      ok([[:text, "[[t]]{{br}}"]], "[[t]]")
    end
  end
end

if defined?($bench) && $bench
  require 'qwik/bench-module-session'

  def ok(e, str)
    tokens = Qwik::TextTokenizer.tokenize(str)
    #ok_eq(e, tokens)
  end

  def generate_large_table(table_line_num)
    str = ''
    table_line_num.times {|n|
      str << "|#{n}|1|2|3|4|5|6|7|8|9|0\n"
    }
    return str
  end

# n=10, line=10000

# str.each vesrion.
#  6.050000   0.660000   6.710000 (  6.701044)
#  6.060000   0.640000   6.700000 (  6.707144)
#  6.140000   0.580000   6.720000 (  6.725063)

# strscan version.
#  5.770000   0.790000   6.560000 (  6.559884)
#  5.810000   0.750000   6.560000 (  6.568743)
#  6.030000   0.550000   6.580000 (  6.562864)

  def main
    n = 10
    str = generate_large_table(10000)
    BenchmarkModule::benchmark {
      n.times {
	ok([], str)
      }
    }
  end
  main
end
