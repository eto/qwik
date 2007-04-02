# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/test-module-ml'

class TestSubmitForward < Test::Unit::TestCase
  include TestModuleML

  def test_forward_mail
    qml = QuickML::Group.new(@ml_config, 'test@example.com')
    qml.setup_test_config
    mail = post_mail(qml) {
"Date: Thu, 28 Apr 2005 07:17:20 +0900
From: bob@example.net
To: test@example.com
Subject: [Fwd: test mail]
Content-Type: multipart/mixed; boundary=\"------------080009010806060401020001\"

This is a multi-part message in MIME format.
--------------080009010806060401020001
Content-Type: text/plain; charset=ISO-2022-JP
Content-Transfer-Encoding: 7bit

I forward the test mail.
--------------080009010806060401020001
Content-Type: message/rfc822; name=\"test mail\"
Content-Transfer-Encoding: 7bit
Content-Disposition: inline; filename=\"test mail\"

From user@example.net  Fri Apr 22 11:31:51 2005
From: user@example.net
Subject: test mail
To: test@expample.com

This is a test.

--------------080009010806060401020001--
" }
    ok_eq("[Fwd: test mail]", mail['Subject'])
    ok_eq("[Fwd: test mail]", @site['1'].get_title)
    ok_eq("* [Fwd: test mail]
{{mail(bob@example.net,0)
I forward the test mail.

{{file(test mail)}}
}}
", @site["1"].load)
    ok_eq(true, @site.files('1').exist?('test mail'))
    str = @site.files('1').path('test mail').read
    ok_eq("From user@example.net  Fri Apr 22 11:31:51 2005
From: user@example.net
Subject: test mail
To: test@expample.com

This is a test.

", str)
  end
end
