# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/ml-session'
require 'qwik/test-module-ml'

if $0 == __FILE__
  $test = true
end

class TestMSAttach < Test::Unit::TestCase
  include TestModuleML

  def test_submit_multipart
    send_normal_mail('bob@example.net')		# Bob creates a new ML.
    sendmail('bob@example.net', 'test@q.example.com', 'multipart test') {
"MIME-Version: 1.0
Content-Type: multipart/mixed; boundary=\"boundary\"
Content-Transfer-Encoding: 7bit

--boundary
Content-Type: text/plain; charset=\"ascii\"
Content-Transfer-Encoding: 7bit

test1

--boundary
Content-Type: text/plain; charset=\"ascii\"
Content-Transfer-Encoding: 7bit

test2

--boundary--
" }
    eq 'multipart test', @site['1'].get_title
    eq "* multipart test
{{mail(bob@example.net,0)
test1

test2
}}
", @site["1"].load
  end

  def test_submit_with_text
    send_normal_mail('bob@example.net')		# Bob creates a new ML.
    str =
"Message-Id: <nosuchmessageid@example.com>
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary=\"------_4119D7487CCF04869008_MULTIPART_MIXED_\"
Content-Transfer-Encoding: 7bit

--------_4119D7487CCF04869008_MULTIPART_MIXED_
Content-Type: text/plain; charset='ISO-2022-JP'
Content-Transfer-Encoding: 7bit

test
--------_4119D7487CCF04869008_MULTIPART_MIXED_
Content-Type: application/octet-stream; name=\"t.txt\"
Content-Disposition: attachment;
 filename=\"t.txt\"
Content-Transfer-Encoding: base64

dGVzdA0K

--------_4119D7487CCF04869008_MULTIPART_MIXED_
"
    sm('text file attach test') { str }
    page = @site.get_by_title('text file attach test')
    eq 'text file attach test', page.get_title
    eq '1', page.key
    eq "* text file attach test
{{mail(bob@example.net,0)
test

{{file(t.txt)}}
}}
", page.load
    files = @site.files('1')
    eq true, files.exist?('t.txt')
    #eq './test/1.files/t.txt', files.path('t.txt').to_s
    eq '.test/data/test/1.files/t.txt', files.path('t.txt').to_s
    str = files.path('t.txt').read
    eq "test\r\n", str

    # The same mail is sent to the ML again.
    sm('text file attach test') { str }
  end

  # FIXME: abandon...
  def nu
    eq "* text file attach test
{{mail(bob@example.net,0)
test

{{file(t.txt)}}
}}
{{mail(bob@example.net,0)
test

{{file(1-t.txt)}}
}}
", page.load
    eq true, @site.files(page.key).exist?('1-t.txt')

    # Once again.
    group.site_post(mail, true)
    page = @site.get_by_title('text file attach test')
    eq "* text file attach test
{{mail(bob@example.net,0)
test

{{file(t.txt)}}
}}
{{mail(bob@example.net,0)
test

{{file(1-t.txt)}}
}}
{{mail(bob@example.net,0)
test

{{file(2-t.txt)}}
}}
", page.load
    eq true, @site.files(page.key).exist?('2-t.txt')
  end

  def nutest_submit_with_image
    group = QuickML::Group.new(@ml_config, 'test@example.com')
    group.setup_test_config

    mail = QuickML::Mail.generate {
"Date: Sun, 01 Aug 2004 12:34:56 +0900
From: Test User <bob@example.net>
To: test@example.com
Subject: Attach Test
Cc: guest@example.com
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary=\"------_410DDC04C7AD046D3600_MULTIPART_MIXED_\"
Content-Transfer-Encoding: 7bit

--------_410DDC04C7AD046D3600_MULTIPART_MIXED_
Content-Type: text/plain; charset=\"ascii\"
Content-Transfer-Encoding: 7bit

This is a test.
--------_410DDC04C7AD046D3600_MULTIPART_MIXED_
Content-Type: image/png; name=\"1x1.png\"
Content-Disposition: attachment;
 filename=\"1x1.png\"
Content-Transfer-Encoding: base64

iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR42mP4//8/AAX+Av4zEpUU
AAAAAElFTkSuQmCC

--------_410DDC04C7AD046D3600_MULTIPART_MIXED_--
" }

    group.site_post(mail, true)
    eq 'Attach Test', @site['1'].get_title
    eq "* Attach Test
{{mail(bob@example.net,0)
This is a test.

{{file(1x1.png)}}
}}
",
	  @site['1'].load
    eq true, @site.files('1').exist?('1x1.png')
  end
end
