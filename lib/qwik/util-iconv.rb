#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

require 'iconv'

$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'
require 'qwik/util-charset'

class String
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

if $0 == __FILE__
  require 'qwik/testunit'
  require 'qwik/util-kconv'
  $test = true
end

if defined?($test) && $test
  class TestIconv < Test::Unit::TestCase
    def test_iconv
      ok_eq('Žš', 'Žš'.sjistou8.u8tosjis)
      ok_eq('Žš', 'Žš'.sjistoeuc.euctou8.u8toeuc.euctosjis)
      ok_eq('Žš', 'Žš'.sjistojis.jistou8.u8tojis.jistosjis)

      # test_sjistou8
      ok_eq("\343\201\202", '‚ '.sjistou8)
      ok_eq('UTF-8', '‚ '.sjistou8.charset)

      # test_u8tosjis
      ok_eq("\202\240", "\343\201\202".u8tosjis)
      ok_eq('Shift_JIS', "\343\201\202".u8tosjis.charset)

      # test_sjistoeuc
      ok_eq("\244\242", '‚ '.sjistoeuc)
      ok_eq('EUC-JP', '‚ '.sjistoeuc.charset)

      # test_euctou8
      ok_eq("\343\201\202", "\244\242".euctou8)
      ok_eq('UTF-8', "\244\242".euctou8.charset)

      # test_u8toeuc
      ok_eq("\244\242", "\343\201\202".u8toeuc)
      ok_eq('EUC-JP', "\343\201\202".u8toeuc.charset)

      # test_sjistojis
      ok_eq("\e$B$\"\e(B", "‚ ".sjistojis)
      ok_eq('ISO-2022-JP', "‚ ".sjistojis.charset)

      # test_jistou8
      ok_eq("\343\201\202", "\e$B$\"\e(B".jistou8)
      ok_eq('UTF-8', "\e$B$\"\e(B".jistou8.charset)

      # test_u8tojis
      ok_eq("\e$B$\"\e(B", "\343\201\202".u8tojis)
      ok_eq('ISO-2022-JP', "\343\201\202".u8tojis.charset)

      # test_illegal_sequence
      # last \202 is illegal
      ok_eq("\202\240?", "\343\201\202\202".u8tosjis)
      # first \202 is illegal
      ok_eq("?\202\240", "\202\343\201\202".u8tosjis)

      # test_annoying_character
      ok_eq("\343\200\234", '`'.sjistou8)
      ok_eq('`', "\343\200\234".u8tosjis)
    end
  end
end
