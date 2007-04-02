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
  $test = true
end

class TestSubmitQuotedPrintable < Test::Unit::TestCase
  include TestModuleML

  def test_all
    qml = QuickML::Group.new(@ml_config, 'test@example.com')
    qml.setup_test_config
    mail = post_mail(qml) {
'Date: Mon, 3 Feb 2001 12:34:56 +0900
From: user@gmail.com
To: test@example.com
Subject: [qwik-users:217] Gmail=?iso-2022-jp?B?GyRCJCwbKEJKSVMbJEIlKCVzJTMhPCVHJSMbKEI=?= 
 =?iso-2022-jp?B?GyRCJXMlMCRLO0VNTUpROTkbKEI=?=
Content-Type: text/plain; charset=ISO-2022-JP
Content-Transfer-Encoding: quoted-printable

=1B$B$3$s$K$A$O!#=1B(B

--=20
user
' }
    ok_eq('quoted-printable', mail['Content-Transfer-Encoding'])
    ok_eq('[qwik-users:217] GmailがJISエンコーディングに仕様変更'.set_sourcecode_charset.to_mail_charset, mail['Subject'])
#    ok_eq('GmailがJISエンコーディングに仕様変更',
#	  mail.get_clean_subject)
    ok_eq("こんにちは。\n\n-- \nuser\n".set_sourcecode_charset.to_mail_charset, mail.decoded_body)
    page = @site['1']
    ok_eq('GmailがJISエンコーディングに仕様変更', page.get_title)
#    ok_eq("* GmailがJISエンコーディングに仕様変更\n{{mail(user@gmail.com,0)\nこんにちは。\n\n-- \nuser\n}}\n", page.load)
  end
end
