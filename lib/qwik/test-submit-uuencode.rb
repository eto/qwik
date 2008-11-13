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

class TestSubmitUuencode < Test::Unit::TestCase
  include TestModuleML

  def test_all
    qml = QuickML::Group.new(@ml_config, 'test@example.com')
    qml.setup_test_config

    base64 =
'begin 666 1x1a.png
MB5!.1PT*&@H````-24A$4@````$````!"`(```"0=U/>````#$E$051XVF/X
8__\_``7^`OXS$I44`````$E%3D2N0F""
`
end
'

    mail = post_mail(qml) {
"Date: Mon, 3 Feb 2001 12:34:56 +0900
From: bob@example.net
To: test@example.com
Subject: UuencodeImage
Content-Type: multipart/mixed; boundary=\"------------Boundary_iGrnGAlmY.rxNIm\"

--------------Boundary_iGrnGAlmY.rxNIm
Content-Type: text/plain; charset=ISO-2022-JP
Content-Transfer-Encoding: 7bit

This is a test.
--------------Boundary_iGrnGAlmY.rxNIm
Content-Type: application/octet-stream; name=\"1x1a.png\"
Content-Transfer-Encoding: x-uuencode
Content-Disposition: attachment; filename=\"1x1a.png\"

#{base64}
" }

    mail1 = QuickML::Mail.new
    mail1.read(mail.parts[1])
    ok_eq('application/octet-stream', mail1.content_type)
    ok_eq("attachment; filename=\"1x1a.png\"",
		 mail1['Content-Disposition'])
    ok_eq('1x1a.png', mail1.filename)
    ok_eq('x-uuencode', mail1['Content-Transfer-Encoding'])
    ok_eq("\211PNG\r\n\032\n\000\000\000\rIHDR\000\000\000\001\000\000\000\001\010\002\000\000\000\220wS\336\000\000\000\fIDATx\332c\370\377\377?\000\005\376\002\3763\022\225\024\000\000\000\000IEND\256B`\202", mail1.decoded_body)

    page = @site['UuencodeImage']
    ok_eq('UuencodeImage', page.get_title)
    ok_eq('* UuencodeImage
{{mail(bob@example.net,0)
This is a test.

{{file(1x1a.png)}}
}}
', page.load)
  end
end
