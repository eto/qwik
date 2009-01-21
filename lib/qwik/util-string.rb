# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

require 'md5'

$LOAD_PATH << 'compat' unless $LOAD_PATH.include? 'compat'
require 'base64'

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/util-charset'

class String
  def xchomp
    return self.chomp("\n").chomp("\r")
  end

  # Used from parser.rb
  def chompp
    return self.sub(/[\n\r]+\z/, '')
  end

  def normalize_eol
    return self.xchomp+"\n"
  end

  def normalize_newline
    return self.gsub("\r\n", "\n").gsub("\r", "\n")
  end

  def sub_str(pattern, replace)
    return sub(Regexp.new(Regexp.escape(pattern)), replace)
  end

  def md5
    return MD5.digest(self)
  end

  def md5hex
    return MD5.hexdigest(self)
  end

  def base64
    return Base64.encode64(self).chomp
  end

  # ============================== escape
  # Copied from cgi.rb
  def escape
    return self.gsub(/([^ a-zA-Z0-9_.-]+)/n) {
      '%' + $1.unpack('H2' * $1.size).join('%').upcase
    }.tr(' ', "+")
  end

  def unescape
    return self.tr("+", ' ').gsub(/((?:%[0-9a-fA-F]{2})+)/n) {
      [$1.delete('%')].pack('H*')
    }
  end

  def unescapeHTML
    return self.gsub(/&(.*?);/n) {
      match = $1.dup
      case match
      when /\Aamp\z/ni	then "&"
      when /\Aquot\z/ni	then "'"
      when /\Agt\z/ni	then ">"
      when /\Alt\z/ni	then "<"
      else
	"&#{match};"
      end
    }
  end

  def mb_length
    case self.charset || self.guess_charset
    when 'UTF-8';       return self.split(//u).length
    when 'Shift_JIS';   return self.split(//s).length
    when 'EUC-JP';      return self.split(//e).length
    end
    return self.length
  end

  def mb_substring(s,e)
    case self.charset || self.guess_charset
    when 'UTF-8';       return self.split(//u)[s...e].to_s
    when 'Shift_JIS';   return self.split(//s)[s...e].to_s
    when 'EUC-JP';      return self.split(//e)[s...e].to_s
    end
    return self[s...e]
  end
 
  # Copied from gonzui-0.1
  # Use this method instead of WEBrick::HTMLUtils.escape for performance reason.
  EscapeTable = {
    "&" => "&amp;",
    '"' => "&quot;",
    '<' => "&lt;",
    '>' => "&gt;",
  }
  def escapeHTML
    string = self
    return string.gsub(/[&"<>]/n) {|x| EscapeTable[x] }
  end
end

if $0 == __FILE__
  require 'test/unit'
  $test = true
end

if defined?($test) && $test
  class TestString < Test::Unit::TestCase
    def test_string
      # test_xchomp
      assert_equal '', ''.xchomp
      assert_equal '', "\n".xchomp
      assert_equal '', "\r".xchomp
      assert_equal '', "\r\n".xchomp
      assert_equal "\n", "\n\r".xchomp
      assert_equal 't', 't'.xchomp
      assert_equal 't', "t\r".xchomp
      assert_equal 't', "t\n".xchomp

      # test_chompp
      assert_equal '', "\n\r".chompp
      assert_equal '', "\n\r\n\r".chompp

      # test_normalize_eol
      assert_equal "\n", ''.normalize_eol
      assert_equal "\n", "\n".normalize_eol
      assert_equal "t\n", 't'.normalize_eol
      assert_equal "t\n", "t\n".normalize_eol

      # test_normalize_newline
      assert_equal "\n", "\n".normalize_newline
      assert_equal "\n", "\r".normalize_newline
      assert_equal "\n", "\r\n".normalize_newline
      assert_equal "\n\n", "\n\r".normalize_newline
      assert_equal "\na\n", "\ra\r".normalize_newline
      assert_equal "\na\n", "\r\na\r\n".normalize_newline
      assert_equal "\n\na\n\n", "\n\ra\n\r".normalize_newline

      # test_sub_str
      assert_equal 'a:b', 'a*b'.sub_str('*', ':')

      # test_md5
      assert_instance_of String, 't'.md5
      assert_equal 16, 't'.md5.length
      assert_equal "\343X\357\244\211\365\200b\361\r\3271ked\236", 't'.md5
      assert_instance_of String, 't'.md5hex
      assert_equal 32, 't'.md5hex.length
      assert_equal 'e358efa489f58062f10dd7316b65649e', 't'.md5hex
      assert_equal 'dA==', 't'.base64
    end

    def test_escape
      # test_escape
      assert_equal('A', 'A'.escape)
      assert_equal("+", ' '.escape)
      assert_equal('%2B', "+".escape)
      assert_equal('%21', "!".escape)
      assert_equal("ABC%82%A0%82%A2%82%A4+%2B%23", "ABC‚ ‚¢‚¤ +#".escape)

      # test_unescape
      assert_equal('A', '%41'.unescape)
      assert_equal(' ', "+".unescape)
      assert_equal("!", '%21'.unescape)
      assert_equal("ABC‚ ‚¢‚¤ +#", "ABC%82%A0%82%A2%82%A4+%2B%23".unescape)

      # test_escapeHTML
      assert_equal("&lt;", "<".escapeHTML)
      assert_equal("&gt;", ">".escapeHTML)
      assert_equal("&amp;", "&".escapeHTML)
      assert_equal("&lt;a href=&quot;http://e.com/&quot;&gt;e.com&lt;/a&gt;",
		   '<a href="http://e.com/">e.com</a>'.escapeHTML)

      # test_unescapeHTML
      assert_equal("<", "&lt;".unescapeHTML)
      assert_equal(">", "&gt;".unescapeHTML)
      assert_equal("&", "&amp;".unescapeHTML)
      assert_equal("<a href='http://e.com/'>e.com</a>",
		   "&lt;a href=&quot;http://e.com/&quot;&gt;e.com&lt;/a&gt;".unescapeHTML)
    end

    def test_mb_length
      str = "“ú–{Œê•¶Žš—ñ"
      assert_equal(6,str.mb_length)

      str = "English"
      assert_equal(7,str.mb_length)
    end

    def test_mb_substring
      str = "“ú–{Œê•¶Žš—ñ"
      assert_equal("–{Œê•¶",str.mb_substring(1,4))

      str = "English"
      assert_equal("ngl",str.mb_substring(1,4))
    end
  end
end
