# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    def plg_aa
      content = yield
      return [:pre, {:class=>'aa'}, content]
    end

    def plg_show_aa(type=nil, message=nil, &b)
      s = aa_get(type, message, &b)
      return [:pre, {:class=>'aa'}, s]
    end

    def aa_get(type=nil, message=nil)
      if type.nil?
	raise unless block_given?
	return yield
      end

      aa, msg = aa_database
      a = aa[type]
      raise 'no such aa' if a.nil?
      m = msg[type]
      m = message if message
      a = a.gsub(/\$1/) { m }
      return a
    end

    def aa_database
      aa = {}
      msg = {}
      aa['smile'] = '(^_^) $1'
      msg['smile'] = 'Hi!'

      aa['モナー'] =
'　　 ∧＿∧　　／￣￣￣￣￣
　　（　´∀｀）＜　$1
　　（　　　　） 　＼＿＿＿＿＿
　　｜ ｜　|
　　（_＿）＿）
'
      msg['モナー'] = 'オマエモナー'
      aa['クマァ'] =
'　　　〇＿〇
　　 （　・(ｪ)・） 　＜$1
　　/J　▽J
　　し―-J
'
      msg['クマァ'] = 'ｸﾏｧ!'
      return [aa, msg]
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestAction < Test::Unit::TestCase
    include TestSession

    def test_aa
      # test_aa
      ok_wi([:pre, {:class=>'aa'}, "a\n"], "{{aa\na\n}}")

      # test_show_aa
      ok_wi([:pre, {:class=>'aa'}, "(^_^) Hi!"], '{{show_aa(smile)}}')
      ok_wi([:pre, {:class=>'aa'}, "(^_^) Bye!"], '{{show_aa(smile, Bye!)}}')
      ok_wi(/monar/, '{{show_aa(モナー, monar)}}')
      ok_wi(/kumar/, '{{show_aa(クマァ, kumar)}}')

      #eq true, @dir.exist?
      #eq false, (@dir+"test").exist?
    end
  end
end
