# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/testunit'

class CheckUuencode < Test::Unit::TestCase
  def test_uuencode
    ok_eq('', [''].pack('u'))
    ok_eq("!80``\n", ['a'].pack('u'))
    ok_eq("#86)C\n", ['abc'].pack('u'))
    ok_eq("$86)C9```\n", ['abcd'].pack('u'))
    ok_eq("M86%A86%A86%A86%A86%A86%A86%A86%A86%A86%A86%A86%A86%A86%A86%A\n",
	  ['a'*45].pack('u'))
    ok_eq("M86%A86%A86%A86%A86%A86%A86%A86%A86%A86%A86%A86%A86%A86%A86%A\n!80``\n", ['a'*46].pack('u'))
    ok_eq("&86)C9&5F\n#9VAI\n", ['abcdefghi'].pack('u6'))

    ok_eq([''], ''.unpack('u'))
    ok_eq([''], ''.unpack('u'))
    ok_eq(['a'], "!80``\n".unpack('u'))
    ok_eq(['abc'], "#86)C\n".unpack('u'))
    ok_eq(['abcd'], "$86)C9```\n".unpack('u'))
    ok_eq(['a'*45], "M86%A86%A86%A86%A86%A86%A86%A86%A86%A86%A86%A86%A86%A86%A86%A\n".unpack('u'))
    ok_eq(['a'*46], "M86%A86%A86%A86%A86%A86%A86%A86%A86%A86%A86%A86%A86%A86%A86%A\n!80``\n".unpack('u'))
    ok_eq(['abcdefghi'], "&86)C9&5F\n#9VAI\n".unpack('u6'))

    png = "\211PNG\r\n\032\n\000\000\000\rIHDR\000\000\000\001\000\000\000\001\010\002\000\000\000\220wS\336\000\000\000\fIDATx\332c\370\377\377?\000\005\376\002\3763\022\225\024\000\000\000\000IEND\256B`\202"
    uu = "MB5!.1PT*&@H````-24A\$4@````\$````!\"`(```\"0=U/>````#\$E\$051XVF/X\n8__\\_``7^`OXS\$I44`````\$E%3D2N0F\"\"\n"
    ok_eq(uu, [png].pack('u'))
    ok_eq([png], uu.unpack('u'))
  end
end
