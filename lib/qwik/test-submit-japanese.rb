# -*- coding: shift_jis -*-
# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/test-module-ml'
if $0 == __FILE__
  require 'qwik/server-memory'
  require 'qwik/farm'
  require 'qwik/group-site'
  require 'qwik/group'
  require 'qwik/password'
  $test = true
end

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

  def test_cp932
    qml = QuickML::Group.new(@ml_config, 'test@example.com')
    qml.setup_test_config

    mail = QuickML::Mail.new
    mail.read(
'From: bob@example.net
To: test@example.com
Content-Type: text/plain;
	charset=CP932;
	format=flowed
Content-Transfer-Encoding: base64
Mime-Version: 1.0 (Apple Message framework v926)
Subject: [test:27] =?CP932?Q?Re: __=83e=83X=83g?=
Date: Fri, 31 Oct 2008 17:08:25 +0900

h0A=
')
    mail.store_addresses
    qml.site_post(mail, true)
    ok_eq("\203e\203X\203g", @site['1'].get_title)
    ok_eq("* \203e\203X\203g\n{{mail(bob@example.net,0)\n\207@\n}}\n", @site['1'].load)
  end


  def test_cp932_quoted_printable
    qml = QuickML::Group.new(@ml_config, 'test@example.com')
    qml.setup_test_config

    mail = QuickML::Mail.new
    mail.read(
'From: bob@example.net
To: smd@qwik.jp
Content-Type: text/plain; charset=CP932; format=flowed
Content-Transfer-Encoding: quoted-printable
Mime-Version: 1.0 (Apple Message framework v926)
Date: Tue, 4 Nov 2008 18:19:37 +0900
Subject: test

=95=D4=90M
')
    mail.store_addresses
    qml.site_post(mail, true)
    ok_eq("test", @site['test'].get_title)
    ok_eq("* test\n{{mail(bob@example.net,0)\n返信\n}}\n", @site['test'].load)
  end
end

