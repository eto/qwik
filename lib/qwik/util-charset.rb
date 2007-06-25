# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

require 'kconv'
require 'iconv'

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

class String
  # ============================== kconv
  def sjistoeuc
    self.kconv(Kconv::EUC, Kconv::SJIS).set_euc
  end

  def euctosjis
    self.kconv(Kconv::SJIS, Kconv::EUC).set_sjis
  end

  def sjistojis
    self.kconv(Kconv::JIS, Kconv::SJIS).set_jis
  end

  def jistosjis
    self.kconv(Kconv::SJIS, Kconv::JIS).set_sjis
  end

  def euctojis
    self.kconv(Kconv::JIS, Kconv::EUC).set_jis
  end

  def jistoeuc
    self.kconv(Kconv::EUC, Kconv::JIS).set_euc
  end

  # ============================== iconv
  def sjistou8;	Iconv.iconv_to_from('UTF-8', 'Shift_JIS', self)	end
  def u8tosjis;	Iconv.iconv_to_from('Shift_JIS', 'UTF-8', self)	end
  def euctou8;	Iconv.iconv_to_from('UTF-8', 'EUC-JP', self)	end
  def u8toeuc;	Iconv.iconv_to_from('EUC-JP', 'UTF-8', self)	end
  def jistou8;	Iconv.iconv_to_from('UTF-8', 'ISO-2022-JP', self)	end
  def u8tojis
    iconv = Iconv.new('ISO-2022-JP', 'UTF-8')
    out = iconv.iconv(self)+iconv.close
    out.set_charset('ISO-2022-JP')
    out
  end

  # ============================== charset
  def set_charset(charset)
    @charset = charset
    return self
  end

  def charset
    return @charset if defined?(@charset)
    return nil
  end

  def set_utf8;	set_charset('UTF-8')		end
  def set_sjis;	set_charset('Shift_JIS')	end
  def set_euc;	set_charset('EUC-JP')		end
  def set_jis;	set_charset('ISO-2022-JP')	end

  KCONV_TO_CHARSET = {
   #Kconv::AUTO		=> '?',
    Kconv::JIS		=> 'ISO-2022-JP',
    Kconv::EUC		=> 'EUC-JP',
    Kconv::SJIS		=> 'Shift_JIS',
   #Kconv::BINARY	=> '?BINARY',
   #Kconv::NOCONV	=> '?NOCONV',
    Kconv::ASCII	=> 'ASCII',
    Kconv::UTF8		=> 'UTF-8',
    Kconv::UTF16	=> 'UTF-16',
    Kconv::UTF32	=> 'UTF-32',
   #Kconv::UNKNOWN	=> '?',
  }

  def guess_charset
    kconv_charset = Kconv::guess(self)
    charset = KCONV_TO_CHARSET[kconv_charset]
    if /\A\?/ =~ charset
      #p kconv_charset, charset
    end
    return charset
  end

  def guess_charset!
    set_charset(self.guess_charset)
    return self
  end

  # tosjis is used in kconv.rb
  def to_sjis
    raise 'Undefined charset.' if self.charset.nil?
    case self.charset
    when 'ASCII';	return self
    when 'UTF-8';	return self.u8tosjis
    when 'Shift_JIS';	return self
    when 'EUC-JP';	return self.euctosjis
    when 'ISO-2022-JP';	return self.jistosjis
    end
    raise 'Unknown charset.'
  end

  # toeuc is used in kconv.rb
  def to_euc
    raise 'Undefined charset.' if self.charset.nil?
    case self.charset
    when 'ASCII';	return self
    when 'UTF-8';	return self.u8toeuc
    when 'Shift_JIS';	return self.sjistoeuc
    when 'EUC-JP';	return self
    when 'ISO-2022-JP';	return self.jistoeuc
    end
    raise 'Unknown charset.'
  end

  # tojis is used in kconv.rb
  def to_jis
    raise 'Undefined charset.' if self.charset.nil?
    case self.charset
    when 'ASCII';	return self
    when 'UTF-8';	return self.u8tojis
    when 'Shift_JIS';	return self.sjistojis
    when 'EUC-JP';	return self.euctojis
    when 'ISO-2022-JP';	return self
    end
    raise 'Unknown charset.'
  end

  def to_utf8
   #raise 'Undefined charset.' if self.charset.nil?
    self.guess_charset! if self.charset.nil?
    case self.charset
    when 'ASCII';	return self
    when 'UTF-8';	return self
    when 'Shift_JIS';	return self.sjistou8
    when 'EUC-JP';	return self.euctou8
    when 'ISO-2022-JP';	return self.jistou8
    end
    raise 'Unknown charset.'
  end

  # Some use case.
  alias set_mail_charset	set_jis
  alias set_page_charset	set_sjis	# This can be changed.
  alias set_sourcecode_charset	set_sjis	# This can be changed.
  alias set_xml_charset		set_utf8
  alias set_url_charset		set_utf8
  alias set_filename_charset	set_utf8

  alias to_mail_charset		to_jis
  alias to_page_charset		to_sjis
  alias to_xml_charset		to_utf8
  alias to_url_charset		to_utf8
  alias to_filename_charset	to_utf8

  def page_to_xml
    self.set_page_charset.to_xml_charset
  end
end

class Iconv
  UNKNOWN_CHARACTER = '?'

  def self.iconv_to_from(to, from, str)
    iconv = Iconv.new(to, from)
    out = ''
    begin
      out << iconv.iconv(str)
    rescue Iconv::IllegalSequence => e	# FIXME: Merge with InvalidCharacter
      out << e.success
      ch, str = e.failed.split(//u, 2)
      out << UNKNOWN_CHARACTER
      retry
    rescue Iconv::InvalidCharacter => e
      out << e.success
      ch, str = e.failed.split(//u, 2)
      out << UNKNOWN_CHARACTER
      retry
    end
    out.set_charset(to)
    return out
  end

  def self.iconv_to_utf8(from, str)
    to = 'UTF-8'
    iconv = Iconv.new(from, to)
    out = ''
    begin
      out << iconv.iconv(str)
    rescue Iconv::IllegalSequence => e
      out << e.success
      ch, str = e.failed.split(//u, 2)
      if respond_to?(:unknown_unicode_handler)
	u = ch.unpack('U').first
	out << unknown_unicode_handler(u)
      else
	out << UNKNOWN_CHARACTER
      end
      retry
    end
    out.set_charset(to)
    return out
  end

  def self.unknown_unicode_handler (u)
    return sprintf("&#x%04x;", u)
  end
end

module Charset
  UTF8 = 'utf-8'
end

if $0 == __FILE__
  require 'test/unit'
  $test = true
end

if defined?($test) && $test
  class TestUtilCharset < Test::Unit::TestCase
    def test_kconv
      # test_sjistoeuc
      assert_equal "\244\242", '‚ '.sjistoeuc
      assert_equal 'EUC-JP', '‚ '.sjistoeuc.charset

      # test_euctosjis
      assert_equal '‚ ', "\244\242".euctosjis
      assert_equal 'Shift_JIS', "\244\242".euctosjis.charset

      # test_sjistojis
      assert_equal "\e$B$\"\e(B", '‚ '.sjistojis
      assert_equal 'ISO-2022-JP', '‚ '.sjistojis.charset

      # test_jistosjis
      assert_equal '‚ ', "\e$B$\"\e(B".jistosjis
      assert_equal 'Shift_JIS', "\e$B$\"\e(B".jistosjis.charset

      # test_euctojis
      assert_equal "\e$B$\"\e(B", "\244\242".euctojis
      assert_equal 'ISO-2022-JP', "\244\242".euctojis.charset

      # test_jistoeuc
      assert_equal "\244\242", "\e$B$\"\e(B".jistoeuc
      assert_equal 'EUC-JP', "\e$B$\"\e(B".jistoeuc.charset

      # test_some_characters
      assert_equal "\e$B4A;z\e(B", 'Š¿Žš'.sjistojis
    end

    def test_iconv
      assert_equal 'Žš', 'Žš'.sjistou8.u8tosjis
      assert_equal 'Žš', 'Žš'.sjistoeuc.euctou8.u8toeuc.euctosjis
      assert_equal 'Žš', 'Žš'.sjistojis.jistou8.u8tojis.jistosjis

      # test_sjistou8
      assert_equal "\343\201\202", '‚ '.sjistou8
      assert_equal 'UTF-8', '‚ '.sjistou8.charset

      assert_equal "\342\200\276", '~'.sjistou8

      # test_u8tosjis
      assert_equal "\202\240", "\343\201\202".u8tosjis
      assert_equal 'Shift_JIS', "\343\201\202".u8tosjis.charset

      # test_sjistoeuc
      assert_equal "\244\242", '‚ '.sjistoeuc
      assert_equal 'EUC-JP', '‚ '.sjistoeuc.charset

      # test_euctou8
      assert_equal "\343\201\202", "\244\242".euctou8
      assert_equal 'UTF-8', "\244\242".euctou8.charset

      # test_u8toeuc
      assert_equal "\244\242", "\343\201\202".u8toeuc
      assert_equal 'EUC-JP', "\343\201\202".u8toeuc.charset

      # test_sjistojis
      assert_equal "\e$B$\"\e(B", "‚ ".sjistojis
      assert_equal 'ISO-2022-JP', "‚ ".sjistojis.charset

      # test_jistou8
      assert_equal "\343\201\202", "\e$B$\"\e(B".jistou8
      assert_equal 'UTF-8', "\e$B$\"\e(B".jistou8.charset

      # test_u8tojis
      assert_equal "\e$B$\"\e(B", "\343\201\202".u8tojis
      assert_equal 'ISO-2022-JP', "\343\201\202".u8tojis.charset

      # test_illegal_sequence
      # last \202 is illegal
      assert_equal "\202\240?", "\343\201\202\202".u8tosjis
      # first \202 is illegal
      assert_equal "?\202\240", "\202\343\201\202".u8tosjis

      # test_annoying_character
      assert_equal "\343\200\234", '`'.sjistou8
      assert_equal '`', "\343\200\234".u8tosjis
    end

    def test_charset
      s = "\202\240"
      assert_equal nil, s.charset
      assert_equal "\202\240", s.set_charset('Shift_JIS')
      assert_equal 'Shift_JIS', s.charset

      # test_guess
      assert_equal 'UTF-8', "\343\201\202".guess_charset
      assert_equal 'Shift_JIS', "\202\240".guess_charset	# ‚ 
#      assert_equal 'EUC-JP', "\244\242".guess_charset
      assert_equal 'ISO-2022-JP', "\e$B$\"\e(B".guess_charset

      # test_to
      s = "\202\240".set_sjis
      assert_equal "\343\201\202", s.to_utf8
      assert_equal "\202\240", s.to_sjis
      assert_equal "\244\242", s.to_euc
      assert_equal "\e$B$\"\e(B", s.to_jis
    end

    def test_bug
      # $KCODE = 'u'
      assert_equal "~", "~".to_utf8
      assert_equal "\342\200\276", "~".set_sjis.to_utf8	# annoying...
      #assert_equal "\343\200\234", "`".to_utf8
      #assert_equal "\343\200\234", "`".set_sjis.to_utf8
    end
  end
end
