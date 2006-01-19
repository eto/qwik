#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

# $use_charset = true
if defined?($use_charset) && $use_charset

$LOAD_PATH << '..' unless $LOAD_PATH.include?('..')

# $LOAD_PATH.unshift('../../../chise/ruby/lib')
CHISE_DIR = '/chise'
$LOAD_PATH.unshift(CHISE_DIR+'/ruby/lib') unless $LOAD_PATH.include?(CHISE_DIR+'/ruby/lib')
require 'chise'
require 'chise/ids'
include CHISE

module Qwik
  class Action
    def plg_define_char
      str = yield
      h = {}
      mode = nil
      i = nil

      ts = WikiText.new(str).tokens
      ts.each {|t|
	e = t[:e]
	case e
	when :definition_term_open, :definition_desc_open
	  mode = e
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
	er ="&my-"+h['my']+";"
	c = er.de_er.char
	h.each {|k, v|
	  c[k] = v
	}
      end
      ''
    end

    def my_char_ids(arg)
      arg = arg.to_s
      return '' if arg !~ /^[0-9]+$/
      er ="&my-"+arg+";"
      c = er.de_er.char
      ids = c.ids
      ids.to_s
    end

    def my_char_kage_url
      'http://127.0.0.1:5100/'
    end

    def plg_my_char(arg)
      ids = my_char_ids(arg).to_utf8
      return '' if ids.length == 0
      ids = ids.de_er

      n = ids.gsub(/#0/, IDC_LR).
	gsub(/#1/, IDC_AB).
	gsub(/#2/, IDC_LM).
	gsub(/#3/, IDC_AM).
	gsub(/#4/, IDC_FS).
	gsub(/#5/, IDC_FA).
	gsub(/#6/, IDC_FB).
	gsub(/#7/, IDC_FL).
	gsub(/#8/, IDC_UL).
	gsub(/#9/, IDC_UR).
	gsub(/#a/i, IDC_LL).
	gsub(/#b/i, IDC_OV)

      ids = n
      
      ar = []
      ids.to_a.each {|ch|
	ar << sprintf('u%04x',ch.ucs)
      }
      pngfile = ar.join('')+'.gothic.png'
      url = my_char_kage_url
      s = [:img, {:src=>(url+pngfile), :style=>"width:1em;", :alt=>pngfile}]
      s
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
      page = @site[n]
      page = @site.create(n) if page.nil?
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
      ok_wi("<img src='#{url}u2ff0u6728u68ee.gothic.png' style='width:1em;'/>", page.load)
      page.store("&my-1;")
      ok_wi("<img src='#{url}u2ff0u6728u68ee.gothic.png' style='width:1em;'/>", page.load)
      page.store("{{my_char(2)}}")
      ok_wi("<img src='#{url}u2ff0u68eeu68ee.gothic.png' style='width:1em;'/>", page.load)

      page.store("{{my_char(a)}}")
      ok_wi('', page.load)

      #    page.store("&my-3;") #‚»‚ñ‚È‚Ì‘¶İ‚µ‚Ä‚¢‚È‚¢
      #    ok_wi("<p></p>\n", page.load) #‚â‚Á‚Ï‚è’†‚Í‹ó‚ÆB

      page.store("{{my_char_ids(1)}}")
      ok_wi("<p>#0–ØX</p>\n", page.load)
      page.store("{{my_char_ids(2)}}")
      ok_wi("<p>#0XX</p>\n", page.load)

      @site.delete(n)
      ok_eq(false, @site.exist?(n))
    end

    def test_charset2
      n = 'CharTest'
      page = @site[n]
      page = @site.create(n) if page.nil?
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

      ok_wi('', page.load) # eval the _chartest here.
      ok_eq("#0–ØX", "&my-1;".de_er.char.ids)
      ok_eq("#0XX", "&my-2;".de_er.char.ids)
      ok_eq("–Ø", "&U-6728;".de_er)
      #    ok_eq("#1–ØX", "&my-3;".de_er.char.ids)
      #    ok_eq("OVsd", "&my-2;".de_er.char.ids)
      page.store("&my-1;")
      url = @action.my_char_kage_url
      ok_wi("<img src='#{url}u2ff0u6728u68ee.gothic.png' style='width:1em;'/>", page.load)

      @site.delete(n)
      ok_eq(false, @site.exist?(n))
    end
  end

  #class TestChiseBasic < Test::Unit::TestCase
  class TestChiseBasic
    include TestSession

    def test_utf8
      @char = "š".su.char
      ok_eq("\273\372", "š".se)
      ok_eq("\345\255\227", "š".su)
      ok_eq("\273\372", "š".su.ue)
      ok_eq("\216\232", "š")
      ok_eq("\273\372", "š".se)
      ok_eq("\345\255\227", "š".su)
      ok_eq("\216\232", "š".su.us)
    end

    def test_er
      @char = "š".su.char
      ok_eq(23383, "š".su.ucs)
      ok_eq(@char, Character.get("&J90-3B7A;"))
      ok_eq(@char, Character.get("&MCS-00005B57;"))
      ok_eq(@char, Character.get("&M-06942;"))
      ok_eq("š", "&J90-3B7A;".de_er.us)
      ok_eq("š", "&U5B57;".de_er.us)
      ok_eq("š", "&U-5B57;".de_er.us)
      ok_eq("š", "&U+5B57;".de_er.us)
      ok_eq("š", "&#x5B57;".de_er.us)
      ok_eq("š", "&#23383;".de_er.us)
    end

    def test_my
      @char = "š".su.char
      # private use area: 0xe000`0xf8ff
      k = Character.get(0xe001)
      ok_eq(0xe001, k.ucs)
      ok_eq("<\356\200\201,\#xe001>", k.inspect)

      k = "&#xe001;".de_er.char
      ok_eq(0xe001, k.ucs)

      k = "&my-0001;".de_er.char
      ok_eq(0xe001, k.ucs)
      k.ids = IDC_LR+"–ØX"
      ok_eq(IDC_LR+"–ØX", k.ids)
      ok_eq(IDC_LR+"–ØX", "&my-0001;".de_er.ids)
      u = 'http://home.fonts.jp:5100/'
      k.kage_url = u
      ok_eq(u, "&my-0001;".de_er.kage_url)

      k = "&my-0002;".de_er.char
      ok_eq(0xe002, k.ucs)
      k.ids = IDC_LR+"XX"
      ok_eq(IDC_LR+"XX", k.ids)
      ok_eq(IDC_LR+"XX", "&my-0002;".de_er.ids)

      "š".eu.mydepth = 1
      ok_eq(1, "š".eu.mydepth)
    end
  end
end

end
