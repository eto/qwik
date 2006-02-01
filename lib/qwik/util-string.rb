#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

require 'md5'

$LOAD_PATH << 'compat' unless $LOAD_PATH.include? 'compat'
require 'base64'

$LOAD_PATH << '..' unless $LOAD_PATH.include?('..')

class String
  def xchomp
    return self.chomp("\n").chomp("\r")
  end

  # Used from parser.rb
  def chompp
    return self.sub(/[\n\r]+\z/, "")
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
    #qp self.length, caller(1)[0]
    return MD5.hexdigest(self)
  end

  def base64
    return Base64.encode64(self).chomp
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  $test = true
end

if defined?($test) && $test
  class TestUtilString < Test::Unit::TestCase
    def test_string
      # test_xchomp
      ok_eq('', ''.xchomp)
      ok_eq("", "\n".xchomp)
      ok_eq("", "\r".xchomp)
      ok_eq("", "\r\n".xchomp)
      ok_eq("\n", "\n\r".xchomp)
      ok_eq('t', 't'.xchomp)
      ok_eq('t', "t\r".xchomp)
      ok_eq('t', "t\n".xchomp)

      # test_chompp
      ok_eq("", "\n\r".chompp)
      ok_eq("", "\n\r\n\r".chompp)

      # test_normalize_eol
      ok_eq("\n", "".normalize_eol)
      ok_eq("\n", "\n".normalize_eol)
      ok_eq("t\n", 't'.normalize_eol)
      ok_eq("t\n", "t\n".normalize_eol)

      # test_normalize_newline
      ok_eq("\n", "\n".normalize_newline)
      ok_eq("\n", "\r".normalize_newline)
      ok_eq("\n", "\r\n".normalize_newline)
      ok_eq("\n\n", "\n\r".normalize_newline)
      ok_eq("\na\n", "\ra\r".normalize_newline)
      ok_eq("\na\n", "\r\na\r\n".normalize_newline)
      ok_eq("\n\na\n\n", "\n\ra\n\r".normalize_newline)

      # test_sub_str
      ok_eq('a:b', 'a*b'.sub_str('*', ':'))

      # test_md5
      assert_instance_of(String, 't'.md5)
      ok_eq(16, 't'.md5.length)
      ok_eq("\343X\357\244\211\365\200b\361\r\3271ked\236", 't'.md5)
      assert_instance_of(String, 't'.md5hex)
      ok_eq(32, 't'.md5hex.length)
      ok_eq('e358efa489f58062f10dd7316b65649e', 't'.md5hex)
      ok_eq("dA==", 't'.base64)
    end
  end
end
