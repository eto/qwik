# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

require 'strscan'

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class InlineTokenizer
    URL = '(?:http|https|ftp|mailto|file):[a-zA-Z0-9;/?:@&=+$,\-_.!~*\'()#%]+'
    SPECIAL = '^\[\]\'=\{\}'

    # Parse a line into tokens using regexp.
    def self.regexp_tokenize(str)
      line_ar = []

      while 0 < str.length
	first_character = str[0]
	rest = str[1, str.length-1]

	case first_character

	when ?'		# ''t'' or '''t'''
	  if /\A'''(?!:')/ =~ str
	    line_ar << :"'''"
	    str = $'
	  elsif /\A''/ =~ str
	    line_ar << :"''"
	    str = $'
	  else
	    line_ar << first_character.chr
	    str = rest
	  end

	when ?=		# ==t==
	  if /\A==/ =~ str
	    line_ar << :'=='
	    str = $'
	  else
	    line_ar << first_character.chr
	    str = rest
	  end

	when ?[		# [[t]]

	  if /\A\[\[(.+?)\]\]/s =~ str	# [[title|url]] format
	    line_ar << [:ref, $1]
	    str = $'

	  elsif /\A\[([^\[\]\s]+?) ([^\[\]\s]+?)\]/ =~ str
	    # [url title] format
	    line_ar << [:ref, $2+'|'+$1]
	    str = $'

	  else
	    line_ar << first_character.chr
	    str = rest
	  end

	when ?{		# {{t}}
	  if /\A\{\{([^\(\)]+?)(?:\((.*?)\))?\s*\}\}/ =~ str # {{t(a)}}
	    ar = [:plugin, $1]
	    ar << $2 if $2
	    line_ar << ar
	    str = $'
	  else
	    line_ar << first_character.chr
	    str = rest
	  end

	else
	  if /\A#{URL}/s =~ str
	    href = $&
	    line_ar << [:url, href]
	    str  = $'

	  elsif /\A[^#{SPECIAL}]+/s =~ str
	    m = $&
	    after = $'

	    if /([^a-zA-Z\d]+)(#{URL})/ =~ m
	      s = $` + $1
	      line_ar << s
	      str = $2 + $' + after
	    else
	      line_ar << m
	      str = after
	    end

	  else
	    if /\A(.+?)([^#{SPECIAL}])/s =~ str
	      line_ar << $1
	      str = $2 + $'
	    else
	      line_ar << str
	      str = ''
	    end
	  end

	end
      end

      return line_ar
    end

    # Parse a line into tokens using strscan.
   #def self.strscan_tokenize(str)
    def self.tokenize(str)
      line_ar = []

      org_kcode = $KCODE
      $KCODE = 's'

      s = StringScanner.new(str)

      while ! s.eos?
	if s.scan(/'''(?!:')/)
	  line_ar << :"'''"

	elsif s.scan(/''(?!:')/)
	  line_ar << :"''"

	elsif s.scan(/==/)
	  line_ar << :'=='

	elsif s.scan(/\[\[(.+?)\]\]/s)	# [[title|url]] format
	  line_ar << [:ref, s[1]]

	elsif s.scan(/\[([^\[\]\s]+?) ([^\[\]\s]+?)\]/s) # [url title] format
	  line_ar << [:ref, s[2]+'|'+s[1]]

	elsif s.scan(/\{\{([^\(\)]+?)(?:\((.*?)\))?\s*\}\}/)	# {{t(a)}}
	  ar = [:plugin, s[1]]
	  ar << s[2] if s[2]
	  line_ar << ar

	elsif s.scan(/#{URL}/s)
	  href = s.matched 
	  line_ar << [:url, href]

	elsif s.scan(/[^#{SPECIAL}]+/s)
	  m = s.matched

	  if /([^a-zA-Z\d]+)(#{URL})/ =~ m
	    ss = $` + $1

	    line_ar << ss

	    skip_str = ss
	    s.unscan
	    s.pos = s.pos + skip_str.length

	  else
	    line_ar << m
	  end

	elsif s.scan(/(.+?)([^#{SPECIAL}])/s)
	  ss = s[1]
	  line_ar << ss
	  s.unscan
	  s.pos = s.pos + ss.length

	else
	  ss = s.string
	  line_ar << ss[s.pos..ss.length]
	  s.terminate

	end
      end

      $KCODE = org_kcode

      line_ar
    end

  end
end

if $0 == __FILE__
  if ARGV[0] == '-b'
    $bench = true
  else
    $test = true
  end
end

if defined?($test) && $test
  require 'qwik/testunit'

  class TestInlineTokenizer < Test::Unit::TestCase
    def ok(e, str)
      ok_eq(e, Qwik::InlineTokenizer.tokenize(str))
    end

    def test_common
      ok([], '')
      ok(['t'], 't')

      # test em, strong and del
      ok([:"''", 't', :"''"], "''t''")
      ok([:"'''", 't', :"'''"], "'''t'''")
      ok(["'"], "'")
      ok(["'", 't'], "'t")
      ok([:'==', 't', :'=='], '==t==')
      ok(['='], '=')
      ok(['=', 't'], '=t')

      # reference
      ok([[:ref, 't']], '[[t]]')
      ok([[:ref, 's|t']], '[[s|t]]')
      ok([']'], ']')
      ok(['[', 't', ']'], '[t]')
      ok([[:ref, 'C++']], '[[C++]]')

      # plugin
      ok([[:plugin, 't']], '{{t}}')
      ok([[:plugin, 't', 'a']], '{{t(a)}}')
      ok(['{', 't', '}'], '{t}')

      # url
      ok([[:url, 'http://e.com/']], 'http://e.com/')
      ok(['t ', [:url, 'http://e.com/'], ' a'], 't http://e.com/ a')
      ok([[:url, 'https://e.com/']], 'https://e.com/')

      # test_all
      ok(['a ', :"''", 'b', :"''", ' ', :"'''", 'c', :"'''", ' ',
	       :==, 'd', :==, ' ', [:ref, 'e'], ' ',
	       [:plugin, 'f'], ' ', [:url, 'http://e.com/'], ' g'],
	     "a ''b'' '''c''' ==d== [[e]] {{f}} http://e.com/ g")

      # test_wiliki_style
      ok(['[', 'u', ']'], '[u]')
      ok([[:ref, 't|u']], '[u t]')
      ok([[:ref, 't|http://e.com/']], '[http://e.com/ t]')

      # test_ref
      ok([[:ref, 't|u']], '[[t|u]]')
      ok([[:ref, 't']], '[[t]]')
      ok([[:ref, '.attach']], '[[.attach]]')
      ok([[:ref, '.attach/t.txt']], '[[.attach/t.txt]]')
      ok([[:ref, '.attach/s t.txt']], '[[.attach/s t.txt]]')

      ok([[:ref, "\203|\203X\203^\201["]], '[[ポスター]]')
      ok(["\202\240", [:ref, "\203|\203X\203^\201["], "\202\240"],
	     'あ[[ポスター]]あ')

      # test_bug
      ok([:"'''", 't', :"''"], "'''t''")

      # test_sjis_bug
      ok_eq("\226]", '望')
      ok(["\226]"], '望')
      ok([[:ref, "\226]"]], '[[望]]')
    end

  end
end

if defined?($bench) && $bench
  require 'qwik/bench-module-session'

  def ok(e, str)
    tokens = Qwik::InlineTokenizer.tokenize(str)
    #ok_eq(e, tokens)
  end

# 10000 times.

# Regexp version.
#  4.550000   0.990000   5.540000 (  5.527012)
#  4.600000   0.870000   5.470000 (  5.485405)
#  4.310000   1.210000   5.520000 (  5.571910)

# strscan version.
#  4.010000   0.300000   4.310000 (  4.314455)
#  3.960000   0.340000   4.300000 (  4.305931)
#  4.080000   0.230000   4.310000 (  4.310803)

  def main
    n = 10000

    BenchmarkModule::benchmark {
      n.times {
	ok(['a ', :"''", 'b', :"''", ' ', :"'''", 'c', :"'''", ' ',
	     :==, 'd', :==, ' ', [:ref, 'e'], ' ',
	     [:plugin, 'f'], ' ', [:url, 'http://e.com/'], ' g'],
	   "a ''b'' '''c''' ==d== [[e]] {{f}} http://e.com/ g")
      }
    }
  end
  main
end
