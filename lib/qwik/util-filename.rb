# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

# Thanks to Mr. Shuhei Yamamoto

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/util-string'
require 'qwik/util-charset'

module Qwik
  class Filename
    def self.encode(str)
      str = str.to_filename_charset
      str = str.gsub(/\342\200\276/n) {
	'~'
      }
      str = str.gsub(/([^ 0-9A-Za-z_.\/-]+)/n) {
	'=' + $1.unpack('H2' * $1.size).join('=').upcase
      }
      return str
    end

    def self.decode(str)
      str = str.gsub(/((?:=[0-9a-fA-F]{2})+)/n) {
	[$1.delete('=')].pack('H*')
      }
      str = str.to_filename_charset
      return str
    end

    def self.contain_multibyte?(filename)
      filename.each_byte {|byte|
	if 0x7f < byte || byte == ?\e
	  return true
	end
      }
      return false
    end

    def self.extname(filename)
      return File.extname(filename).sub(/\A\./, '')
    end

    ALLOWABLE_CHARACTERS_FOR_PATH_RE = /\A[\/ 0-9A-Za-z_.-]+\z/

    def self.allowable_characters_for_path?(f)
      return true if ALLOWABLE_CHARACTERS_FOR_PATH_RE =~ f
      return false
    end

    private

    ALLOWABLE_CHARACTERS_RE = /\A[ 0-9A-Za-z_.-]+\z/

    def self.allowable_characters?(f)
      return true if ALLOWABLE_CHARACTERS_RE =~ f
      return false
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestFilename < Test::Unit::TestCase
    include TestSession

    def test_all
      c = Qwik::Filename

      # test_encode
      ok_eq('t', c.encode('t'))
      ok_eq(' ', c.encode(' '))
      ok_eq('=E3=81=82', c.encode("‚ "))
      ok_eq('=E3=81=82', c.encode("\202\240"))
      ok_eq('=E3=81=82.txt', c.encode("\202\240.txt"))

      # test_bug
      ok_eq('=7E', c.encode('~'))
      ok_eq('=7E', c.encode('~'.set_sjis))

      # test_decode
      ok_eq('t', c.decode('t'))
      ok_eq(' ', c.decode(' '))
      ok_eq("\343\201\202", c.decode('=E3=81=82'))
      ok_eq("\343\201\202.txt", c.decode('=E3=81=82.txt'))

      # test_contain_multibyte?
      ok_eq(false, c.contain_multibyte?('t'))
      ok_eq(false, c.contain_multibyte?('t t'))
      ok_eq(true,  c.contain_multibyte?("\202\240"))

      # test_allowable_characters?
      ok_eq(true,  c.allowable_characters?('t'))
      ok_eq(true,  c.allowable_characters?('t t'))
      ok_eq(true,  c.allowable_characters?('t.-_t'))
      ok_eq(true,  c.allowable_characters?('t..t'))
      ok_eq(false, c.allowable_characters?("\202\240"))
      ok_eq(false,  c.allowable_characters?('t/t'))

      # test_allowable_characters_for_path?
      ok_eq(true,  c.allowable_characters_for_path?('t/t'))

      # test_extname
      ok_eq('txt',  c.extname('t.txt'))
    end
  end
end
