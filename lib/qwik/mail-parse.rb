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
require 'qwik/mail'

module QuickML
  class Mail
    # Construct a mail from a mail string.
    def read (string)
      @bare = string || ''

      header, body = @bare.split(/\n\n/, 2)
      @body = body || ''

      attr = nil
      header.split("\n").each {|line|
	line = line.xchomp
	if /^(\S+):\s*(.*)/ =~ line
	  attr = $1
	  push_field(attr, $2)
	elsif attr
	  concat_field(line)
	end
      }
      @charset = Mail.get_charset(self['Content-Type'])
      @content_type = Mail.get_content_type(self['Content-Type'])
    end

    def store_addresses
      @mail_from = self.from
      (self.collect_to + self.collect_cc).each {|addr|
	self.add_recipient(addr)
      }
    end

    # Create a new mail
    def self.create
      mail = Mail.new
      mail.read(yield)
      mail.store_addresses
      return mail
    end

    # Generate a mail for test.
    def self.generate
      mail = Mail.new
      mail.read(yield.set_sourcecode_charset.to_mail_charset)
      mail.store_addresses
      return mail
    end

    private

    def push_field (key, value)
      # Use Array for preserving order of the header
      field = [key, value]
      @header.push(field)
    end

    def concat_field (value)
      lastfield = @header.last
      @header.pop
      push_field(lastfield.first, lastfield.last + "\n" + value)
    end
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  $test = true
end

if defined?($test) && $test
  class TestMailGenerate < Test::Unit::TestCase
    def test_all
      str = 'Date: Mon, 3 Feb 2001 12:34:56 +0900
From: "Test User" <user@e.com>
To: "Test Mailing List" <test@example.com>
Subject: Re: [test:1] Test Mail

This is a test.
'
      # test_read
      mail = QuickML::Mail.new
      mail.read(str)

      # test_bare
      ok_eq(str, mail.bare)

      # test_body
      ok_eq("This is a test.\n", mail.body)

      # test_charset
      ok_eq(nil, mail.charset)

      # test_content_type
      ok_eq(nil, mail.content_type)

      # test_from
      ok_eq('user@e.com', mail.from)

      # test_header
      header = nil
      mail.instance_eval {
	header = @header
      }
      ok_eq([['Date', 'Mon, 3 Feb 2001 12:34:56 +0900'],
	      ['From', "\"Test User\" <user@e.com>"],
	      ['To', "\"Test Mailing List\" <test@example.com>"],
	      ['Subject', 'Re: [test:1] Test Mail']],
	    header)
    end

    def test_create
      str = 'Date: Mon, 3 Feb 2001 12:34:56 +0900
From: "Test User" <user@e.com>
To: "Test Mailing List" <test@example.com>
Subject: Re: [test:1] Test Mail

‚ 
'
      mail = QuickML::Mail.create { str }
      ok_eq("\202\240\n", mail.body)
    end

    def test_generate
      str = 'Date: Mon, 3 Feb 2001 12:34:56 +0900
From: "Test User" <user@e.com>
To: "Test Mailing List" <test@example.com>
Subject: Re: [test:1] Test Mail

‚ 
'
      mail = QuickML::Mail.generate { str }
      ok_eq("\e$B$\"\e(B\n", mail.body)
    end

  end
end
