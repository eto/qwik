#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '..' unless $LOAD_PATH.include?('..')

class MailAddress
  def self.valid?(mail)
    return false if mail.nil?
    return false unless /\A([0-9a-zA-Z_.+-]+)@([0-9a-zA-Z_.-]+)\z/ =~ mail
    login_part = $1
    domain_part = $2
    return false if domain_part.include?('..')
    #return false if mail.include?('..')
    return true
  end

  def self.obfuscate(address)
    return address.sub(/(@.).*/, '\1...')
  end

  def self.obfuscate_str(str)
    str.gsub(/([0-9a-zA-Z_.-]+)@([0-9a-zA-Z_.-]+)\.([0-9a-zA-Z_-]+)/) {|mail|
      MailAddress.obfuscate(mail)
    }
  end

  # foo@ExampLE.CoM => foo@example.com
  # 'foo'@example.com => foo@example.com
  def self.normalize(mail)
    name, domain = mail.split('@')
    return mail if domain.nil?
    name.gsub!(/^"(.*)"$/, '\1')
    return "#{name}@#{domain.downcase}"
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  $test = true
end

if defined?($test) && $test
  class TestMailAddress < Test::Unit::TestCase
    alias ok_eq ok_eq

    def test_normalize
      c = MailAddress
      ok_eq('foo@example.com', c.normalize('foo@example.com'))
      ok_eq('foo@example.com', c.normalize('foo@ExampLE.CoM'))
      ok_eq('foo@example.com', c.normalize("\"foo\"@ExampLE.CoM"))
    end

    def test_valid?
      c = MailAddress
      ok_eq(true,  c.valid?('user@example.com'))
      ok_eq(true,  c.valid?("valid+@example.com"))
      ok_eq(true,  c.valid?("+valid@example.com"))
      ok_eq(true,  c.valid?('_@example.com'))
      ok_eq(true,  c.valid?('us..er@example.com'))
      # Make this address valid for local account.
      ok_eq(true,  c.valid?('invalid@example'))
      ok_eq(false, c.valid?(nil))
      ok_eq(false, c.valid?(''))
      ok_eq(false, c.valid?("invalid!@example.com"))
      ok_eq(false, c.valid?('invalid'))
      ok_eq(false, c.valid?('user@example..com'))
    end

    def test_obfuscate
      c = MailAddress
      ok_eq('user@e...', c.obfuscate('user@example.com'))
    end

    def test_obfuscate_str
      c = MailAddress
      ok_eq('user@e...', c.obfuscate_str('user@example.com'))
      ok_eq('a t@e... b s@f... c',
	    c.obfuscate_str('a t@e.com b s@f.com c'))
    end
  end
end
