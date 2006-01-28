#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '..' unless $LOAD_PATH.include?('..')
require 'qwik/util-kconv'
require 'qwik/util-iconv'

class String
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
      qp kconv_charset, charset
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
    #qp self.charset
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

module Qwik
  module Charset
    UTF8 = 'utf-8'
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  require 'qwik/qp'
  $test = true
end

if defined?($test) && $test
  class TestUtilCharset < Test::Unit::TestCase
    def test_all
      #test_charset
      s = "\202\240"
      ok_eq(nil, s.charset)
      ok_eq("\202\240", s.set_charset('Shift_JIS'))
      ok_eq('Shift_JIS', s.charset)

      # test_guess
      ok_eq('UTF-8', "\343\201\202".guess_charset)
      ok_eq('Shift_JIS', "\202\240".guess_charset)	# ‚ 
      ok_eq('EUC-JP', "\244\242".guess_charset)
      ok_eq('ISO-2022-JP', "\e$B$\"\e(B".guess_charset)

      # test_to
      s = "\202\240".set_sjis
      ok_eq("\343\201\202", s.to_utf8)
      ok_eq("\202\240", s.to_sjis)
      ok_eq("\244\242", s.to_euc)
      ok_eq("\e$B$\"\e(B", s.to_jis)
    end
  end
end
