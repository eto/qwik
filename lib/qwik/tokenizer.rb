#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

require 'strscan'

$LOAD_PATH << '..' unless $LOAD_PATH.include?('..')
#require 'qwik/tokenizer-inline'

module Qwik
  class TextTokenizer
    # Terminal regexp
    TERMINAL_REGEXP = {
      :plugin	=> /\A\}\}\z/,
      :pre	=> /\A\}\}\}\z/,
      :html	=> /\A\<\/html\>\z/,
    }

    # Tokenize a string into line tokens.
    def self.tokenize(str, br_mode=false)
      page_ar = []
      in_tag = {}

      scanner = StringScanner.new(str)
      while ! scanner.eos?
	line = scanner.scan(/.*$/)
	newline = scanner.scan(/\n/)

	line.chomp!

	# At the first, check if it is in a tag branch to them.
	last_token = page_ar.last
	if last_token
	  last_tag = last_token[0] 
	  if in_tag[last_tag]
	    if TERMINAL_REGEXP[last_tag] =~ line
	      in_tag[last_tag] = nil
	    else
	      last_token[-1] += "#{line.chomp}\n"
	    end
	    next
	  end
	end

	line.chomp!

	# preprocess
	#line.gsub!(/&my-([0-9]+);/) {|m| "{{my_char(#{$1})}}" }

	first_character = line[0]	# The first character,
	rest = line[1, line.length-1]	# and the rest of the line.

	case first_character
	when nil, ?#	# The line is '', or comment.
	  page_ar << [:empty]	# empty line

	when ?*		# h
	  if /\A(\*{1,5})(.+)\z/ =~ line
	    h = $1
	    s = $2.to_s	# Since $2 maybe nil, convert it to str.
	    s = s.strip
	    if 0 < s.length
	      page_ar << [("h#{h.size+1}").intern, s]
	    else	# '* '
	      inline(page_ar, line, br_mode)
	    end
	  else		# '*'
	    inline(page_ar, line, br_mode)
	  end

	when ?=		# hr
	  if /\A====+\z/ =~ line
	    page_ar << [:hr]
	  else
	    inline(page_ar, line, br_mode)
	  end

	when ?-		# ul
	  if line == '-- ' || /\A----+\z/ =~ line	# Ad hoc hr mode.
	    page_ar << [:hr]
	  elsif /\A(\-{1,3})(.+)\z/ =~ line
	    page_ar << [:ul, $1.size, $2.to_s.strip]
	  else
	    inline(page_ar, line, br_mode)
	  end

	when ?+		# ol
	  if /\A(\+{1,3})(.+)\z/ =~ line
	    page_ar << [:ol, $1.size, $2.to_s.strip]
	  else
	    inline(page_ar, line, br_mode)
	  end

	when ?>		# blockquote
	  page_ar << [:blockquote, rest.strip]

	when ?:		# dl
	  dt, dd = rest.split(':', 2)
	  if dt && dt.include?("(")
	    if /\A(.*?\(.*\)[^:]*):(.*)\z/ =~ rest	# FIXME: Bad hack.
	      dt, dd = $1, $2
	    end
	  end
	  ar = [:dl]
	  ar << ((dt && dt != '') ? dt.to_s.strip : nil)
	  ar << ((dd && dd != '') ? dd.to_s.strip : nil)
	  page_ar << ar

	when ?\s, ?\t		# pre
	  page_ar << [:pre, rest]

	when ?, , ?|		# table
	  re = Regexp.new(Regexp.quote(first_character.chr), nil, 's')
	  ar = [:table] + rest.split(re).map {|a| a.to_s.strip }
	  page_ar << ar

	when ?{		# plugin or super pre
	  if /\A\{\{([^\(\)\{\}]+?)(?:\(([^\(\)\{\}]*?)\))?\}\}\z/ =~ line
	    page_ar << [:plugin, $1.to_s, $2.to_s]
	  elsif /\A\{\{([^\(\)\{\}]+?)(?:\(([^\(\)\{\}]*?)\))?\z/ =~ line
	    in_tag[:plugin] = true
	    page_ar << [:plugin, $1.to_s, $2.to_s, '']
	  elsif /\A\{\{\{/ =~ line
	    in_tag[:pre] = true
	    page_ar << [:pre, '']
	  else
	    inline(page_ar, line, br_mode)
	  end

	when ?<		# <html>
	  if line == "<html>"
	    page_ar << [:html, '']
	    in_tag[:html] = true
	  else
	    inline(page_ar, line, br_mode)
	  end

	else		# normal text
	  inline(page_ar, line, br_mode)
	end
      end

      page_ar
    end

    private

    def self.inline(page_ar, line, br_mode)
      if /~\z/s =~ line
	line = line.sub(/~\z/s, "{{br}}")	# //s means shift_jis
      elsif br_mode
	line = line+"{{br}}"
      end
      page_ar << [:text, line]
    end
  end
end

if $0 == __FILE__
  if ARGV[0] == '-b'
    $bench = true
  else
    require 'qwik/testunit'
    require 'qwik/qp'
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
      ok([[:empty]], "#t")
      ok([[:hr]], "====")
      ok([[:text, "==="]], "===")
      ok([[:text, '*']], '*')
      ok([[:h2, 't']], '*t')
      ok([[:h2, 't']], '* t')
      ok([[:text, '* ']], '* ')
      ok([[:text, '*']], '*')
      ok([[:h3, 't']], '**t')
      ok([[:h4, 't']], '***t')
      ok([[:h5, 't']], '****t')
      ok([[:h6, 't']], '*****t')
      ok([[:text, '-']], '-')
      ok([[:ul, 1, 't']], '-t')
      ok([[:ul, 1, 't']], '- t')
      ok([[:ul, 2, 't']], '--t')
      ok([[:ul, 3, 't']], '---t')
      ok([[:ul, 3, '-t']], '----t') # uum...
      ok([[:ul, 1, '-']], '--')
      ok([[:hr]], '-- ')
      ok([[:hr]], '----')
      ok([[:text, "+"]], "+")
      ok([[:ol, 1, 't']], "+t")
      ok([[:blockquote, 't']], ">t")
      ok([[:blockquote, 't']], "> t")

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
      ok([[:table, 't']], ', t')
      ok([[:table, 's', 't']], ',s,t')
      ok([[:table, '', 't']], ',,t')
      ok([[:table, 't']], '|t')
      ok([[:table, "$t"]], ",$t")
      ok([[:table, "$1"]], ",$1")

      ok([[:text, "{t}"]], "{t}")
      ok([[:plugin, 't', '']], "{{t}}")
      ok([[:plugin, 't', 'a']], "{{t(a)}}")
      ok([[:plugin, 't', '', '']], "{{t")
      ok([[:plugin, 't', 'a', '']], "{{t(a)")
      ok([[:plugin, 't', "", "s\n"]], "{{t\ns\n}}")
      ok([[:plugin, 't', 'a', "s\n"]], "{{t(a)\ns\n}}")

      ok([[:pre, "s\n"]], "{{{\ns\n}}}")
      ok([[:pre, "s\nt\n"]], "{{{\ns\nt\n}}}")
      ok([[:pre, "#s\n"]], "{{{\n#s\n}}}")

      ok([[:empty]], "\n")
      ok([[:text, 't']], 't')
      ok([[:text, 's'], [:text, 't']], "s\nt")
      ok([[:text, 's'], [:empty], [:text, 't']], "s\n\nt")

      # test_html
      ok([[:text, "<t"]], "<t")
      ok([[:html, '']], "<html>")
      ok([[:html, "t\n"]], "<html>\nt\n</html>")
      ok([[:html, "<p>\nt\n</p>\n"]], "<html>\n<p>\nt\n</p>\n</html>")

      # test_sjis_bug
      ok([[:table, "•|", "•|"]], ",•|,•|")
      ok([[:table, 's', 't']], '|s|t')
      ok([[:table, "•|", "•|"]], "|•||•|")

      # test_multiline
      ok([[:text, 's'], [:text, 't']], "s\nt")
      ok([[:text, "s{{br}}"], [:text, "t{{br}}"]], "s~\nt~")
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
