# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

CHISE_DIR = File.expand_path(File.dirname(__FILE__)+'/../../../chise/ruby/lib')
$use_charset = CHISE_DIR.path.exist?

if defined?($use_charset) && $use_charset
$LOAD_PATH << CHISE_DIR unless $LOAD_PATH.include? CHISE_DIR
require 'chise'
require 'chise/ids'

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    def plg_define_char
      str = yield
      mode = nil
      i = nil

      h = {}
      tokens = c_tokenize(str)
      tokens.each {|t|
	e = t[0]
	case e
	when :dt
	  # not yet.
	when :dd
	  # not yet.
	when :definition_term_close, :definition_desc_close
	  mode = nil
	when :normal_text
	  s = t[:s]
	  if mode == :definition_term_open
	    i = s
	  elsif mode == :definition_desc_open
	    h[i] = s
	  end
	end
      }

      if h['my']
	c = "&my-#{h['my']};".de_er.char
	h.each {|k, v|
	  c[k] = v
	}
      end

      return
    end

    def my_char_ids(arg)
      return unless /\A[0-9]+\z/ =~ arg.to_s
      return "&my-#{arg};".de_er.char.ids.to_s
    end

    def my_char_kage_url
      return 'http://127.0.0.1:5100/'
    end

    def plg_my_char(arg)
      ids = my_char_ids(arg).to_utf8
      return if ids.empty?
      ids = ids.de_er

      n = ids.gsub(/#0/, CHISE::IDC_LR).
	gsub(/#1/, CHISE::IDC_AB).
	gsub(/#2/, CHISE::IDC_LM).
	gsub(/#3/, CHISE::IDC_AM).
	gsub(/#4/, CHISE::IDC_FS).
	gsub(/#5/, CHISE::IDC_FA).
	gsub(/#6/, CHISE::IDC_FB).
	gsub(/#7/, CHISE::IDC_FL).
	gsub(/#8/, CHISE::IDC_UL).
	gsub(/#9/, CHISE::IDC_UR).
	gsub(/#a/i, CHISE::IDC_LL).
	gsub(/#b/i, CHISE::IDC_OV)

      ids = n
      
      base = ids.to_a.map {|ch|
	sprintf('u%04x',ch.ucs)
      }.join
      pngfile = "#{base}.gothic.png"
      return [:img, {:src=>"#{my_char_kage_url}#{pngfile}",
	  :style=>"width:1em;", :alt=>pngfile}]
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
# $use_charset = false
 #class TestActCharset < Test::Unit::TestCase
  class TestActCharset
    include TestSession

    def test_charset
      n = 'CharTest'
      page = @site.create(n)
      page.store('test')
      ok_eq(true, @site.exist?(n))
      ok_wi('test', 'test')
      ok_eq('test', page.load)
      ok_eq('test', @site[n].load)
      ok_wi('test', page.load)

      str = "{{define_char
:my:1
:ids:#0–ØX
}}

{{define_char
:my:2
:ids:#0XX
}}
"
      page.store(str)

      ok_wi('', page.load)
      ok_eq("#0–ØX", "&my-1;".de_er.char.ids)
      ok_eq("#0XX", "&my-2;".de_er.char.ids)

      url = @action.my_char_kage_url
      page.store("{{my_char(1)}}")
      ok_wi("<img src='#{url}u2ff0u6728u68ee.gothic.png' style='width:1em;'/>",
	    page.load)
      page.store("&my-1;")
      ok_wi("<img src='#{url}u2ff0u6728u68ee.gothic.png' style='width:1em;'/>",
	    page.load)
      page.store("{{my_char(2)}}")
      ok_wi("<img src='#{url}u2ff0u68eeu68ee.gothic.png' style='width:1em;'/>",
	    page.load)

      page.store("{{my_char(a)}}")
      ok_wi('', page.load)

      #page.store("&my-3;")		# does not exist.
      #ok_wi("<p></p>\n", page.load)	# It's empty.

      page.store("{{my_char_ids(1)}}")
      ok_wi("<p>#0–ØX</p>\n", page.load)
      page.store("{{my_char_ids(2)}}")
      ok_wi("<p>#0XX</p>\n", page.load)

      @site.delete(n)
      ok_eq(false, @site.exist?(n))
    end

    def test_charset2
      n = 'CharTest'
      page = @site.create(n)
      str = "{{define_char
:my:1
:ids:#0–ØX
}}

{{define_char
:my:2
:ids:#0XX
}}

{{define_char
:my:3
:ids:#1&U-6728;X
}}
"
      page.store(str)

      ok_wi('', page.load)	# Eval the _chartest here.
      ok_eq("#0–ØX", "&my-1;".de_er.char.ids)
      ok_eq("#0XX", "&my-2;".de_er.char.ids)
      ok_eq("–Ø", "&U-6728;".de_er)
     #ok_eq("#1–ØX", "&my-3;".de_er.char.ids)
     #ok_eq("OVsd", "&my-2;".de_er.char.ids)
      page.store("&my-1;")
      url = @action.my_char_kage_url
      ok_wi("<img src='#{url}u2ff0u6728u68ee.gothic.png' style='width:1em;'/>",
	    page.load)

      @site.delete(n)
      ok_eq(false, @site.exist?(n))
    end
  end

 #class TestChiseBasic < Test::Unit::TestCase
  class TestChiseBasic
    include TestSession

    def test_utf8
      @char = "š".su.char
      assert_equal "\273\372", "š".se
      assert_equal "\345\255\227", "š".su
      assert_equal "\273\372", "š".su.ue
      assert_equal "\216\232", "š"
      assert_equal "\273\372", "š".se
      assert_equal "\345\255\227", "š".su
      assert_equal "\216\232", "š".su.us
    end

    def test_er
      @char = "š".su.char
      assert_equal 23383, "š".su.ucs
      assert_equal @char, CHISE::Character.get("&J90-3B7A;")
      assert_equal @char, CHISE::Character.get("&MCS-00005B57;")
      assert_equal @char, CHISE::Character.get("&M-06942;")
      assert_equal "š", "&J90-3B7A;".de_er.us
      assert_equal "š", "&U5B57;".de_er.us
      assert_equal "š", "&U-5B57;".de_er.us
      assert_equal "š", "&U+5B57;".de_er.us
      assert_equal "š", "&#x5B57;".de_er.us
      assert_equal "š", "&#23383;".de_er.us
    end

    def test_my
      @char = "š".su.char
      # private use area: 0xe000`0xf8ff
      k = CHISE::Character.get(0xe001)
      assert_equal 0xe001, k.ucs
      assert_equal "<\356\200\201,\#xe001>", k.inspect

      k = "&#xe001;".de_er.char
      assert_equal 0xe001, k.ucs

      k = "&my-0001;".de_er.char
      assert_equal 0xe001, k.ucs
      k.ids = CHISE::IDC_LR+"–ØX"
      assert_equal CHISE::IDC_LR+"–ØX", k.ids
      assert_equal CHISE::IDC_LR+"–ØX", "&my-0001;".de_er.ids
      u = 'http://home.fonts.jp:5100/'
      k.kage_url = u
      assert_equal u, "&my-0001;".de_er.kage_url

      k = "&my-0002;".de_er.char
      assert_equal 0xe002, k.ucs
      k.ids = CHISE::IDC_LR+"XX"
      assert_equal CHISE::IDC_LR+"XX", k.ids
      assert_equal CHISE::IDC_LR+"XX", "&my-0002;".de_er.ids

      "š".eu.mydepth = 1
      assert_equal 1, "š".eu.mydepth
    end
  end
end

end
