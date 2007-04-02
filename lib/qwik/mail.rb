#
# Copyright (C) 2002-2004 Satoru Takabayashi <satoru@namazu.org> 
# Copyright (C) 2003-2006 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/mail-parse'
require 'qwik/mail-header'
require 'qwik/mail-body'
require 'qwik/util-string'

module QuickML
  class Mail
    def initialize
      @mail_from = nil
      @recipients = []
      @header = []
      @body = ''
      @charset = nil
      @content_type = nil
      @bare = nil
    end

    attr_accessor :mail_from
    attr_reader :recipients
    attr_accessor :body
    attr_reader :charset
    attr_reader :content_type
    attr_accessor :bare
  end
end

# TODO: Make special mode for Mr. Kaoru Misaki.
# Use the first line of the body as a subject.

if $0 == __FILE__
  require 'qwik/testunit'
  $test = true
end

if defined?($test) && $test
  class TestMail < Test::Unit::TestCase
    def gen_mail(&b)
      return QuickML::Mail.generate(&b)
    end

    def test_basic
      str = 'Date: Mon, 3 Feb 2001 12:34:56 +0900
From: "Test User" <user@e.com>
To: "Test Mailing List" <test@example.com>
Subject: Re: [test:1] Test Mail

This is a test.
'
      mail = gen_mail { str }

      # test_accessor
      eq 'user@e.com', mail.mail_from
      eq ['test@example.com'], mail.recipients
      eq "This is a test.\n", mail.body
      eq str, mail.bare

      # test_to_s
      eq str, mail.to_s

      # test_looping?
      eq false, mail.looping?

      # test_from
      eq 'user@e.com', mail.from

      # test_collect
      eq [], mail.collect_cc
      eq ['test@example.com'], mail.collect_to

      # test_decoded_body
      eq "This is a test.\n", mail.decoded_body

      # test_get_body
      eq "This is a test.\n", mail.get_body

      # test_parts
      eq ["This is a test.\n"], mail.parts

      eq nil, mail.filename		# test_filename
      assert(['test@example.com'], mail.valid?)	# test_valid?
      eq nil, mail.boundary		# test_boundary
      eq false, mail.multipart?		# test_multipart?

      # test_each_part
      mail.each_part {|mail|
	assert_instance_of(QuickML::Mail, mail)
      }
    end

    def test_multipart
      mail = gen_mail {
"Date: Mon, 3 Feb 2001 12:34:56 +0900
From: Test User <user@e.com>
To: test@example.com
Cc: guest@example.com
Subject: multipart test
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary=\"boundary\"
Content-Transfer-Encoding: 7bit

--boundary
Content-Type: text/plain; charset=\"ascii\"
Content-Transfer-Encoding: 7bit

body1

--boundary
Content-Type: text/plain; charset=\"ascii\"
Content-Transfer-Encoding: 7bit

body2

--boundary--
" }

      # test_accessor
      eq ['test@example.com', 'guest@example.com'], mail.recipients

      # test_collect
      eq ['guest@example.com'], mail.collect_cc

      # test_get_body
      eq "body1\nbody2\n", mail.get_body

      # test_parts
      eq ["Content-Type: text/plain; charset=\"ascii\"
Content-Transfer-Encoding: 7bit

body1

", "Content-Type: text/plain; charset=\"ascii\"
Content-Transfer-Encoding: 7bit

body2

"], mail.parts

      # test_parts
      mail0 = QuickML::Mail.new
      mail0.read(mail.parts[0])
      eq "body1\n\n", mail0.body

      mail1 = QuickML::Mail.new
      mail1.read(mail.parts[1])
      eq "body2\n\n", mail1.body

      # test_multipart
      eq true, mail.multipart?		# test_multipart?
      eq 'boundary', mail.boundary	# test_boundary

      # test_multipart_alternative
      mail['Content-Type'] = "multipart/alternative; boundary=\"b\""
      mail.instance_eval {
	@content_type = QuickML::Mail.get_content_type(self['Content-Type'])
      }
      eq 'multipart/alternative', mail.content_type
      eq "multipart/alternative; boundary=\"b\"",
	    mail['Content-Type']
      eq true, mail.multipart?		# test_multipart?
      eq 'b', mail.boundary		# test_boundary
    end

    def test_mail_with_image
      mail = gen_mail {
"Date: Mon, 3 Feb 2001 12:34:56 +0900
From: Test User <user@e.com>
To: test@example.com
Cc: guest@example.com
Subject: Attach Test
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary=\"------_410DDC04C7AD046D3600_MULTIPART_MIXED_\"
Content-Transfer-Encoding: 7bit

--------_410DDC04C7AD046D3600_MULTIPART_MIXED_
Content-Type: text/plain; charset='ascii'
Content-Transfer-Encoding: 7bit

Test with image.

--------_410DDC04C7AD046D3600_MULTIPART_MIXED_
Content-Type: image/png; name=\"1x1.png\"
Content-Disposition: attachment;
 filename=\"1x1.png\"
Content-Transfer-Encoding: base64

iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR42mP4//8/AAX+Av4zEpUU
AAAAAElFTkSuQmCC

--------_410DDC04C7AD046D3600_MULTIPART_MIXED_--
" }

      # test_get_body
      eq "Test with image.\n", mail.get_body

      # test_parts
      mail0 = QuickML::Mail.new
      mail0.read(mail.parts[0])
      eq 'text/plain', mail0.content_type
      eq "Test with image.\n\n", mail0.body

      mail1 = QuickML::Mail.new
      mail1.read(mail.parts[1])
      eq 'image/png', mail1.content_type
      eq "attachment;
 filename=\"1x1.png\"",
		 mail1['Content-Disposition']
      eq '1x1.png', mail1.filename
      eq 'base64', mail1['Content-Transfer-Encoding']
      eq "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR42mP4//8/AAX+Av4zEpUU\nAAAAAElFTkSuQmCC\n\n", mail1.body
      eq "\211PNG\r\n\032\n\000\000\000\rIHDR\000\000\000\001\000\000\000\001\010\002\000\000\000\220wS\336\000\000\000\fIDATx\332c\370\377\377?\000\005\376\002\3763\022\225\024\000\000\000\000IEND\256B`\202", mail1.decoded_body

      eq nil, mail.parts[2]
    end

    def test_inline_disposition
      mail = gen_mail {
"Date: Mon, 3 Feb 2001 12:34:56 +0900
From: user@e.com
To: test@example.com
Subject: This is an inline test.
MIME-Version: 1.0 (generated by SEMI 1.14.4 - Hosorogi)
Content-Type: multipart/mixed;
 boundary=\"Multipart_Thu_Apr_14_21:22:30_2005-1\"

--Multipart_Thu_Apr_14_21:22:30_2005-1
Content-Type: text/plain; charset=ISO-2022-JP

I attached sample.jpg.
--Multipart_Thu_Apr_14_21:22:30_2005-1
Content-Type: image/jpeg
Content-Disposition: inline; filename=\"sample.jpg\"
Content-Transfer-Encoding: base64

iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR42mP4//8/AAX+Av4zEpUU
AAAAAElFTkSuQmCC

" }
      mail1 = QuickML::Mail.new
      mail1.read(mail.parts[1])
      eq "inline; filename=\"sample.jpg\"", mail1['Content-Disposition']
      eq 'sample.jpg', mail1.filename
    end

    def test_apple_mail
      mail = gen_mail {
"Date: Mon, 3 Feb 2001 12:34:56 +0900
From: Test User <user@e.com>
To: test@example.com
Cc: guest@example.com
Subject: Apple Mail
Mime-Version: 1.0 (Apple Message framework v623)
Content-Type: multipart/mixed; boundary=Apple-Mail-1-134582006

--Apple-Mail-1-134582006
Content-Transfer-Encoding: 7bit
Content-Type: text/plain;
	charset=ISO-2022-JP;
	format=flowed

I attach a file using Apple Mail.
--Apple-Mail-1-134582006
Content-Transfer-Encoding: base64
Content-Type: application/zip;
	x-mac-type=5A495020;
	x-unix-mode=0755;
	x-mac-creator=53495421;
	name='sounds.zip'
Content-Disposition: attachment;
	filename=sounds.zip

iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR42mP4//8/AAX+Av4zEpUU
AAAAAElFTkSuQmCC

--Apple-Mail-1-134582006--
" }

      # test_get_body
      eq "I attach a file using Apple Mail.\n", mail.get_body

      # test_parts
      mail0 = QuickML::Mail.new
      mail0.read(mail.parts[0])
      eq 'text/plain', mail0.content_type
      eq "I attach a file using Apple Mail.\n", mail0.body

      mail1 = QuickML::Mail.new
      mail1.read(mail.parts[1])
      eq 'application/zip', mail1.content_type
      eq "attachment;\n\tfilename=sounds.zip", mail1['Content-Disposition']
      eq 'sounds.zip', mail1.filename
    end
  end

  class TestMLMailJapanese < Test::Unit::TestCase
    def gen_mail(&b)
      return QuickML::Mail.generate(&b)
    end

    def test_jmail
      str =
'Date: Mon, 3 Feb 2001 12:34:56 +0900
From: "Test User" <user@e.com>
To: "Test Mailing List" <test@example.com>
Subject: Re: [test:1] テスト 

これはテストです。
'
      mail = gen_mail { str }
      eq "これはテストです。\n".set_sourcecode_charset.to_mail_charset, mail.body
      eq str.set_sourcecode_charset.to_mail_charset, mail.bare
      eq "Re: [test:1] テスト ".set_sourcecode_charset.to_mail_charset, mail['Subject']
      eq "これはテストです。\n".set_sourcecode_charset.to_mail_charset, mail.get_body
    end

    def test_for_confirm
      str = 'To: test@example.com
From: bob@example.net
Subject: test

test
'
      mail = gen_mail { str }

      # test_accessor
      eq 'bob@example.net', mail.mail_from
      eq ['test@example.com'], mail.recipients
      eq "test\n", mail.body
    end
  end
end
