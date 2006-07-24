# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'
require 'qwik/test-module-ml'
#require 'qwik/quickml'

class TestSubmitJapanese < Test::Unit::TestCase
  include TestModuleML

  def test_submit_1
    qml = QuickML::Group.new(@ml_config, 'test@example.com')
    qml.setup_test_config
    mail = post_mail(qml) { # 1st mail
'Date: Mon, 3 Feb 2001 12:34:56 +0900
From: "Test User" <bob@example.net>
To: "Test Mailing List" <test@example.com>
Subject: Re: [test:1] テスト 

テ。
' }
    ok_eq("テスト", @site['1'].get_title)
    ok_eq("* テスト\n{{mail(bob@example.net,0)\nテ。\n}}\n", @site['1'].load)

    mail = post_mail(qml) { # 2nd mail
'Date: Mon, 4 Feb 2001 12:34:56 +0900
From: "Guest User" <guest@example.com>
To: "Test Mailing List" <test@example.com>
Subject: Re: [test:2] テスト 

これもテ。
' }
    ok_eq("テスト", @site['1'].get_title)
    ok_eq("* テスト\n{{mail(bob@example.net,0)\nテ。\n}}\n{{mail(guest@example.com,0)\nこれもテ。\n}}\n", @site['1'].load) # the new mail is added.
  end

  def test_submit_with_attach_image
    qml = QuickML::Group.new(@ml_config, 'test@example.com')
    qml.setup_test_config
    mail = post_mail(qml) {
"Date: Sun, 01 Aug 2004 12:34:56 +0900
From: bob@example.net
To: test@example.com
Subject: =?iso-2022-jp?B?GyRCRTpJVSVGJTklSBsoQg==?=
Cc: guest@example.com
Message-Id: <nosuchmessageid@example.com>
MIME-Version: 1.0
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
    ok_eq("添付テスト", page.get_title)
    ok_eq("* 添付テスト
{{mail(bob@example.net,0)
テ。

{{file(1x1.png)}}
}}
", page.load)
    ok_eq(true, @site.files('1').exist?('1x1.png'))
  end
end
