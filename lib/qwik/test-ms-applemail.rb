# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/ml-session'
require 'qwik/test-module-ml'

if $0 == __FILE__
  $test = true
end

class TestMSAppleMail < Test::Unit::TestCase
  include TestModuleML

  def test_all
    send_normal_mail('bob@example.net')		# Bob creates a new ML.
    sendmail('bob@example.net', 'test@q.example.com', 'Apple Mail') {
"Mime-Version: 1.0 (Apple Message framework v623)
Content-Type: multipart/mixed; boundary=Apple-Mail-1-134582006
Subject: Apple Mail

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
	name=\"sounds.zip\"
Content-Disposition: attachment;
	filename=sounds.zip

UEsDBBQAAAAAAHiWSDMAAAAAAAAAAAAAAAANAAAAMDUxMDA3c291bmRzL1BLAwQUAAAACAB4lkgz
dW5kcy91bnJlYWwvZ25kX3YzLmFpZlBLBQYAAAAAEQARAMEEAACdHAYAAAA=

--Apple-Mail-1-134582006--
"
    }
    eq 'Apple Mail', @site['1'].get_title
    eq "* Apple Mail
{{mail(bob@example.net,0)
I attach a file using Apple Mail.

{{file(sounds.zip)}}
}}
",
	  @site['1'].load

    files = @site.files('1')
    eq true, files.exist?('sounds.zip')
  end
end
