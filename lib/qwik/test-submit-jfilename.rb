# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/test-module-session'
require 'qwik/test-module-ml'
#require 'qwik/quickml'

class TestSubmitForwardJapanese < Test::Unit::TestCase
  include TestModuleML

  def test_dummy
  end

  def nutest_japanese_file_name
    qml = QuickML::Group.new(@ml_config, 'test@example.com')
    qml.setup_test_config

    mail = post_mail(qml) {
"Date: Fri, 20 May 2005 15:21:55 +0900
From: bob@example.net
To: test@example.com
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



"}
    ok_eq('Attach Test', @site['1'].get_title)
    ok_eq("* Attach Test
{{mail(bob@example.net,0)
This is a test.

{{file(1x1.png)}}

}}
", @site["1"].load)
    ok_eq(true, @site.files('1').exist?('1x1.png'))
  end

  def nutest_forward_long
    qml = QuickML::Group.new(@ml_config, 'test@example.com')
    qml.setup_test_config
    mail = post_mail(qml) {
"Date: Thu, 28 Apr 2005 07:17:20 +0900
From: bob@example.net
To: 2005@eto.com
Subject: [Fwd: [itri-unei:00521] =?ISO-2022-JP?B?GyRCIVozTkRqTyJNbSFbGyhC?=
 =?ISO-2022-JP?B?GyRCSXRMZ0ZiJVIlIiVqJXMlMEZ8RHgkSyREJCQkRhsoQl0=?=
Content-Type: multipart/mixed;
 boundary='------------080009010806060401020001'

This is a multi-part message in MIME format.
--------------080009010806060401020001
Content-Type: text/plain; charset=ISO-2022-JP
Content-Transfer-Encoding: 7bit

“¯‚¶•û–@‚Å“]‘—‚µ‚Ü‚·B

--------------080009010806060401020001
Content-Type: message/rfc822;
 name=\"[itri-unei:00521] =?ISO-2022-JP?B?GyRCIVozTkRqTyJNbSFbSXRMZ0ZiJVIlIiVqGyhC?==?ISO-2022-JP?B?GyRCJXMlMEZ8RHgkSyREJCQkRhsoQg==?=\"
Content-Transfer-Encoding: 7bit
Content-Disposition: inline;
 filename=\"[itri-unei:00521] =?ISO-2022-JP?B?GyRCIVozTkRqTyJNbSFbSXRMZ0ZiJVIlIiVqGyhC?==?ISO-2022-JP?B?GyRCJXMlMEZ8RHgkSyREJCQkRhsoQg==?=\"


Date: Fri, 22 Apr 2005 11:31:34 +0900
From: s@e.com
Subject: [itri-unei:00521] =?ISO-2022-JP?B?GyRCIVozTkRqTyJNbSFbGyhC?=
	=?ISO-2022-JP?B?GyRCSXRMZ0ZiJVIlIiVqJXMlMEZ8RHgkSyREGyhC?=
	=?ISO-2022-JP?B?GyRCJCQkRhsoQg==?=
To: i-u@a.jp
Content-Type: text/plain; charset='ISO-2022-JP'
Content-Transfer-Encoding: 7bit

‚¨‚Í‚æ‚¤‚²‚´‚¢‚Ü‚·B

--------------080009010806060401020001--
" }

    qml.site_post(mail, true)
    ok_eq("[Fwd: test mail]", mail['Subject'])
    ok_eq("[Fwd: test mail]", @site['1'].get_title)
    ok_eq("* [Fwd: test mail]
{{mail(bob@example.net,0)
I forward the test mail.

{{file(test mail)}}

}}
",
	  @site['1'].load)
    ok_eq(true, @site.files('1').exist?('test mail'))
    str = @site.files('1').path('test mail').get
    ok_eq("From user@example.net  Fri Apr 22 11:31:51 2005
From: user@example.net
Subject: test mail
To: test@expample.com

This is a test.

", str)
  end
end
