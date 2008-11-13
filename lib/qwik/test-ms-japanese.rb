# -*- coding: shift_jis -*-
# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/ml-session'
require 'qwik/test-module-ml'

if $0 == __FILE__
  require 'qwik/password'
  $test = true
end

class TestMSJapanese < Test::Unit::TestCase
  include TestModuleML

  def test_submit_1
    send_normal_mail('bob@example.net')
    ok_log(["[test]: New ML by bob@example.net",
	     "[test]: Add: bob@example.net",
	     "[test]: QwikPost: test"], 0..2)

    sm("テスト") { 'テ。' }
    ok_log("[test]: QwikPost: 1
[test:2]: Send:")
    eq "テスト", @site['1'].get_title
    eq "* テスト
{{mail(bob@example.net,0)
テ。
}}
", @site['1'].load

    sm("テスト") { 'これもテ。' }
    ok_log("[test]: QwikPost: 1
[test:3]: Send:")
    eq "テスト", @site['1'].get_title
    # The new mail is added.
    eq "* テスト
{{mail(bob@example.net,0)
テ。
}}
{{mail(bob@example.net,0)
これもテ。
}}
", @site['1'].load

    unsubscribe('bob@example.net')		# close ML
    ok_log("[test]: Remove: bob@example.net
[test]: ML Closed
[test]: Unsubscribe: bob@example.net")
  end

  def test_submit_with_attach_image
    send_normal_mail('bob@example.net')
    ok_log(["[test]: New ML by bob@example.net",
	     "[test]: Add: bob@example.net",
	     "[test]: QwikPost: test"], 0..2)

    sm("テスト") {
"MIME-Version: 1.0
Content-Type: multipart/mixed; boundary=\"------_410DDC04C7AD046D3600_MULTIPART_MIXED_\"
Content-Transfer-Encoding: 7bit

--------_410DDC04C7AD046D3600_MULTIPART_MIXED_
Content-Type: text/plain; charset='ISO-2022-JP'
Content-Transfer-Encoding: 7bit

テ。
--------_410DDC04C7AD046D3600_MULTIPART_MIXED_
Content-Type: image/png; name=\"1x1.png\"
Content-Disposition: attachment;
 filename=\"1x1.png\"
Content-Transfer-Encoding: base64

iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR42mP4//8/AAX+Av4zEpUU
AAAAAElFTkSuQmCC

--------_410DDC04C7AD046D3600_MULTIPART_MIXED_--
" }
    page = @site['1']
    eq "テスト", page.get_title
    eq true, @site.files('1').exist?('1x1.png')
  end

  def nu
    eq "* テスト
{{mail(bob@example.net,0)

テ。

{{file(1x1.png)}}

}}
", page.load
  end
end
