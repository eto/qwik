#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

require 'kconv'

$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'
require 'qwik/util-charset'

class String
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
end

if $0 == __FILE__
  require 'qwik/testunit'
  $test = true
end

if defined?($test) && $test
  class TestKconv < Test::Unit::TestCase
    def test_all
      # test_sjistoeuc
      ok_eq("\244\242", '‚ '.sjistoeuc)
      ok_eq('EUC-JP', '‚ '.sjistoeuc.charset)

      # test_euctosjis
      ok_eq('‚ ', "\244\242".euctosjis)
      ok_eq('Shift_JIS', "\244\242".euctosjis.charset)

      # test_sjistojis
      ok_eq("\e$B$\"\e(B", '‚ '.sjistojis)
      ok_eq('ISO-2022-JP', '‚ '.sjistojis.charset)

      # test_jistosjis
      ok_eq('‚ ', "\e$B$\"\e(B".jistosjis)
      ok_eq('Shift_JIS', "\e$B$\"\e(B".jistosjis.charset)

      # test_euctojis
      ok_eq("\e$B$\"\e(B", "\244\242".euctojis)
      ok_eq('ISO-2022-JP', "\244\242".euctojis.charset)

      # test_jistoeuc
      ok_eq("\244\242", "\e$B$\"\e(B".jistoeuc)
      ok_eq('EUC-JP', "\e$B$\"\e(B".jistoeuc.charset)

      # test_some_characters
      ok_eq("\e$B4A;z\e(B", 'Š¿Žš'.sjistojis)
    end
  end
end
