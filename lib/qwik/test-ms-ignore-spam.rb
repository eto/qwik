# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/ml-session'
require 'qwik/test-module-ml'

if $0 == __FILE__
  $test = true
end

class TestMSIgnoreSpam < Test::Unit::TestCase
  include TestModuleML

  def test_all
    send_normal_mail('bob@example.net')		# Bob creates a new ML.

    # normail mail
    sendmail('bob@example.net', 'test@q.example.com', 'test mail') {
"This is a test."
    }
    eq true, @site.exist?('1')
    eq 'test mail', @site['1'].get_title
    eq "* test mail\n{{mail(bob@example.net,0)\nThis is a test.\n}}\n",
      @site['1'].load

    # spammer's mail
    res = sendmail('spammer@example.org', 'test@q.example.com', 'spam mail') {
"This is a spam mail."
    }

    eq ["spammer@example.org"], $quickml_sendmail[3]
    eq "To: spammer@example.org
From: test@q.example.com
Subject: [QuickML] Error: spam mail

You are not a member of the mailing list:
<test@q.example.com>

Did you send a mail with a different address from the address registered in the mailing list?
Please check your 'From:' address.

-- 
Info: http://example.com/

----- Original Message -----
Subject: spam mail
To: test@q.example.com
From: spammer@example.org
Date: 

The original body is omitted to avoid spam trouble.
", $quickml_sendmail[4]

  end
end
