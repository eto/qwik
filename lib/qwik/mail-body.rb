# -*- coding: shift_jis -*-
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
    def to_s
      str = ''
      self.each_field {|key, value|
	str << "#{key}: #{value}\n"
      }
      str << "\n"
      str << @body
      return str
    end

    # ml-processor.rb:102:      @mail.empty_body? ||
    def empty_body?
      return Mail.empty_body?(@body)
    end

    # group-mail.rb:38:      if mail.plain_text_body?
    # group-site.rb:116:      if sub_mail.plain_text_body?
    def plain_text_body?
      Mail.plain_text_body?(self['Content-Type'],
			    self['Content-Transfer-Encoding'])
    end

    def get_body
      body = ''
      self.each_part {|mail|
	if mail.plain_text_body?
	  body << mail.body.chomp.chomp+"\n"
	end
      }
      return body
    end

    # by eto
    def decoded_body
      return Mail.decode_body(self['Content-Transfer-Encoding'], @body)
    end

    # ==================== Class methods.
    def self.empty_body?(body)
      return false if 100 < body.length
      # Substitute spaces in Shift_JIS to ordinaly spaces.
      body = body.tosjis.gsub("\201@") { ' ' }
      return true if /\A\s*\Z/s =~ body
      return false
    end

    def self.plain_text_body?(ct, cte)
      return true if (ct.empty? || /\btext\/plain\b/i =~ ct) &&
	(cte.empty? || /^[78]bit$/i =~ cte || /^base64$/i =~ cte || /quoted-printable/i =~ cte)
      return false
    end

    def self.decode_body(enc, body)
      return Mail.decode_base64(body) if /base64/i =~ enc
      return Mail.decode_uuencode(body) if /x-uuencode/i =~ enc
      return Mail.decode_quoted_printable(body) if /quoted-printable/i =~ enc
      return body
    end

    def self.decode_base64(str)
      return Base64.decode64(str)
    end

    def self.decode_uuencode(str)
      uu = ''
      str.each {|line|
	next  if /\Abegin/ =~ line
	break if /\Aend/ =~ line
	uu << line
      }
      return uu.unpack('u').first
    end

    def self.decode_quoted_printable(str)
      str = str.gsub(/[ \t]+$/no, '')
      str.gsub!(/=\r?\n/no, '')
      str.gsub!(/=([0-9A-F][0-9A-F])/no) { $1.hex.chr }
      return str
    end

    # group-mail.rb:168:      mail.body = Mail.join_parts(parts, mail.boundary)
    # ml-processor.rb:188:        body = Mail.join_parts(parts, @mail.boundary)
    def self.join_parts (parts, boundary)
      body = ''
      body << "--#{boundary}\n"
      body << parts.join("--#{boundary}\n")
      body << "--#{boundary}--\n"
      return body
    end

  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  $test = true
end

if defined?($test) && $test
  class TestMailBody < Test::Unit::TestCase
    def test_all
      mail = QuickML::Mail.new

      # test_to_s
      ok_eq("\n", mail.to_s)

      # test_empty_body?
      ok_eq(true, mail.empty_body?)

      # test_plain_text_body?
      ok_eq(true, mail.plain_text_body?)
    end

    def test_class_method
      c = QuickML::Mail

      # test_empty_body?
      #ok_eq(false, mail.empty_body?)
      ok_eq("\201@", '　')
      ok_eq(true, c.empty_body?(''))
      ok_eq(true, c.empty_body?(' '))
      ok_eq(true, c.empty_body?(' '*100))
      ok_eq(true, c.empty_body?("\n"*100))
      ok_eq(true, c.empty_body?("\t"*100))
      ok_eq(true, c.empty_body?("\201@"*50))
      ok_eq(false, c.empty_body?("\201@"*100))
      ok_eq(false, c.empty_body?(' '*101))
      ok_eq(false, c.empty_body?('a'))

      # test_plain_text_body?
      ok_eq(true, c.plain_text_body?('', ''))
      ok_eq(true, c.plain_text_body?('text/plain; charset="ascii"', ''))
      ok_eq(false, c.plain_text_body?("multipart/mixed; boundary='boundary'", ''))
      ok_eq(false, c.plain_text_body?("image/png; name='1x1.png'", ''))

      # test_decode_body
      ok_eq('', c.decode_body('', ''))

      # test_decode_base64
      ok_eq('', c.decode_base64(''))
      ok_eq('', c.decode_base64('t'))

      # test_decode_uuencode
      ok_eq('', c.decode_uuencode(''))
      ok_eq('', c.decode_uuencode('t'))

      # test_decode_quoted_printable
      ok_eq('', c.decode_quoted_printable(''))
      ok_eq('t', c.decode_quoted_printable('t'))

      # test_join_parts
      ok_eq("--b\ns--b\nt--b--\n", c.join_parts(['s', 't'], 'b'))
    end
  end
end
