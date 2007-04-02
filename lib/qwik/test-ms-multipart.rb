# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/ml-session'
require 'qwik/test-module-ml'

if $0 == __FILE__
  $test = true
end

class TestMSMultipart < Test::Unit::TestCase
  include TestModuleML

  def test_all
    # Alice create a new ML
    send_normal_mail('alice@example.net')
    ok_log ["[test]: New ML by alice@example.net",
	     "[test]: Add: alice@example.net",
	     "[test]: QwikPost: test"], 0..2

    # Send a multipart mail.
    sendmail('alice@example.net', 'test@q.example.com', 'multipart') {
"Mime-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Type: Multipart/Mixed;
 boundary=\"--Next_Part(Wed_Oct_16_19:21:12_2002_747)--\"

----Next_Part(Wed_Oct_16_19:21:12_2002_747)--
Content-Type: Text/Plain; charset=us-ascii
Content-Transfer-Encoding: 7bit

test
----Next_Part(Wed_Oct_16_19:21:12_2002_747)--
Content-Type: Text/Plain; charset=us-ascii
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename=\"foobar.txt\"

foobar

----Next_Part(Wed_Oct_16_19:21:12_2002_747)----
" }
    ok_log ["[test]: QwikPost: multipart", "[test:2]: Send:"]

    # Send a Japanese mail.
    sendmail('alice@example.net', 'test@q.example.com',
	     "=?iso-2022-jp?B?GyRCJEYkOSRIGyhC?=") {
'Content-Type: text/plain; charset=ISO-2022-JP

“ú–{Œê‚Å‚·‚æ
' }
    ok_log ["[test]: QwikPost: 1", "[test:3]: Send:"]

    # Send a Japanese multipart mail.
    sendmail('alice@example.net', 'test@q.example.com',
	     "=?iso-2022-jp?B?GyRCJF4kayRBJFEhPCRIGyhC?=") {
"Mime-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Type: Multipart/Mixed;
 boundary=\"--Next_Part(Wed_Oct_16_19:21:12_2002_747)--\"

----Next_Part(Wed_Oct_16_19:21:12_2002_747)--
Content-Type: Text/Plain; charset=iso-2022-jp
Content-Transfer-Encoding: 7bit

‚Ä‚·‚Æ
----Next_Part(Wed_Oct_16_19:21:12_2002_747)--
Content-Type: Text/Plain; charset=us-ascii
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename=\"foobar.txt\"

foobar

----Next_Part(Wed_Oct_16_19:21:12_2002_747)----
" }
    ok_log ["[test]: QwikPost: 2", "[test:4]: Send:"]

    unsubscribe 'alice@example.net'		# close ML
    ok_log ["[test]: Remove: alice@example.net",
	     "[test]: ML Closed",
	     "[test]: Unsubscribe: alice@example.net"]
  end
end
