# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/ml-session'
require 'qwik/test-module-ml'

if $0 == __FILE__
  $test = true
end

class TestMailSubmitWithJapaneseFilename < Test::Unit::TestCase
  include TestModuleML

  def test_all
    send_normal_mail 'bob@example.net'
    ok_log(['[test]: New ML by bob@example.net',
	     '[test]: Add: bob@example.net',
	     '[test]: QwikPost: test'], 0..2)

    sm('テスト') {
"Date: Fri, 20 May 2005 15:21:55 +0900
From: bob@example.net
To: test@q.example.com
Subject: Attach a file with japanese file name
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary=\"------_428D7194605E049A05F8_MULTIPART_MIXED_\"
Content-Transfer-Encoding: 7bit

--------_428D7194605E049A05F8_MULTIPART_MIXED_
Content-Type: text/plain; charset='ISO-2022-JP'
Content-Transfer-Encoding: 7bit

test.
--------_428D7194605E049A05F8_MULTIPART_MIXED_
Content-Type: application/octet-stream;
 name=\"=?ISO-2022-JP?B?MTdmeRskQk09OzslMyE8JUkkTjtYRGokSxsoQg==?=
 =?ISO-2022-JP?B?GyRCJEQkJCRGGyhCLmRvYw==?=\"
Content-Disposition: attachment;
 filename=\"=?ISO-2022-JP?B?MTdmeRskQk09OzslMyE8JUkkTjtYRGokSxsoQg==?=
 =?ISO-2022-JP?B?GyRCJEQkJCRGGyhCLmRvYw==?=\"
Content-Transfer-Encoding: base64

0M8R4KGxGuEAAAAAAAAAAAAAAAAAAAAAPgADAP7/CQAGAAAAAAAAAAAAAAABAAAAMAAAAAAAAAAA
AAAAAA==
--------_428D7194605E049A05F8_MULTIPART_MIXED_
Content-Type: application/octet-stream;
 name=\"=?ISO-2022-JP?B?GyRCPnBKc04uJUclNiUkJXMlMCVrITwlVxsoQg==?=
 =?ISO-2022-JP?B?Lnhscw==?=\"
Content-Disposition: attachment;
 filename=\"=?ISO-2022-JP?B?GyRCPnBKc04uJUclNiUkJXMlMCVrITwlVxsoQg==?=
 =?ISO-2022-JP?B?Lnhscw==?=\"
Content-Transfer-Encoding: base64

0M8R4KGxGuEAAAAAAAAAAAAAAAAAAAAAPgADAP7/CQAGAAAAAAAAAAAAAAABAAAAHAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAEwAAAAAQAAAAAAAA
--------_428D7194605E049A05F8_MULTIPART_MIXED_--
" }
    page = @site['1']
    eq 'テスト', page.get_title
    eq '* テスト
{{mail(bob@example.net,0)
test.

{{file(17fy予算コードの指定について.doc)}}


{{file(情報流デザイングループ.xls)}}
}}
',
	  page.get

    files = @site.files '1'
    # The files.list are encoded in UTF-8
    eq ["17fy\344\272\210\347\256\227\343\202\263\343\203\274\343\203\211\343\201\256\346\214\207\345\256\232\343\201\253\343\201\244\343\201\204\343\201\246.doc", "\346\203\205\345\240\261\346\265\201\343\203\207\343\202\266\343\202\244\343\203\263\343\202\260\343\203\253\343\203\274\343\203\227.xls"], files.list
    eq true, files.exist?('17fy予算コードの指定について.doc')
    eq true, files.exist?('17fy予算コードの指定について.doc'.set_sourcecode_charset.to_filename_charset)	# UTF-8 is allowed.
    eq true, files.exist?('17fy予算コードの指定について.doc'.set_sourcecode_charset.to_mail_charset)	# Any charsets are allowed.
    eq true, files.exist?('情報流デザイングループ.xls')
  end
end
