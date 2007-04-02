# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

# Special mode, not for general use.

module Qwik
  class EmodePreProcessor
    def self.emode?(str)
      /\A============================================================/ =~ str
    end

    HMARK = {
      'h2' => '*',
      'h3' => '**'
    }

    def self.preprocess(str)
      next_line = nil
      num = 0
      ar = []
      str.each {|line|
	line.chomp!
	if next_line
	  if next_line == 'h2'
	    num += 1
	  end
	  if /\A([●■])(.*)\z/s =~ line
	    ar << HMARK[next_line] + $2
	  else
	    if next_line == 'h2'
	      ar << '*' + num.to_s
	    else
	      ar << "===="
	    end
	    next_line = add_line(next_line, ar, line)
	  end
	  next_line = nil
	else
	  next_line = add_line(next_line, ar, line)
	end
      }
      return ar.join("\n")
    end

    def self.add_line(next_line, ar, line)
      case line
      when /\A(=+)\z/		# only =
	return 'h2'
      when /\A(------+)/	# only -
	return 'h3'
      when /\A([→・])(.*)\z/s
	ar << '-'+$2
	return next_line
      when /\A([●■])(.*)\z/s
	ar << '***'+$2
	return next_line
      end

      ignore_chars = [?\s, ?-, ?*, ?>, ?|, ?,, ?{, ?}]
      if ignore_chars.include?(line[0]) || line.empty?
	ar << line
	return next_line
      end

      ar << line+"{{br}}"
      return next_line
    end
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  $test = true
end

if defined?($test) && $test
  class TestEmodePreProcessor < Test::Unit::TestCase
    def ok(e, str)
      str = "============================================================\n"+str
      ok_eq(e, Qwik::EmodePreProcessor.preprocess(str))
    end

    def test_all
      c = Qwik::EmodePreProcessor

      # test_emode?
      eq(false, !!c.emode?(''))
      eq(true,  !!c.emode?("============================================================"))

      # test_preprocess
      ok('*t', "●t")
      ok("*1\n-t", "・t")
      ok("*1\nt{{br}}", 't')
      ok("*t\nt1{{br}}\nt2{{br}}", "●t\nt1\nt2")
      ok("*t\nt1{{br}}\n====\nt2{{br}}",
	 "●t\nt1\n------------------------------------------------------------\nt2")
      #ok("*t\n>t1{{br}}\n>t2{{br}}", "●t\n>t1\n>t2") # impossible...
      ok("*t\n>t1\n>t2", "●t\n>t1\n>t2")
      ok("*1\n-", '-')
      ok('*1',
	 '------------------------------------------------------------')

      # test_sjis_bug
      ok("*1\nー{{br}}\nt{{br}}", "ー\nt")

      # test_br
      ok("*1\n{{{\nt{{br}}\n}}}", "{{{\nt\n}}}")

      # test_multiline
      ok("*1\na{{br}}\n\nb{{br}}", "a\n\nb")
    end
  end
end
