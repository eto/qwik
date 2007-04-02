# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

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
    def test_normalize
      c = MailAddress
      assert_equal 'foo@example.com', c.normalize('foo@example.com')
      assert_equal 'foo@example.com', c.normalize('foo@ExampLE.CoM')
      assert_equal 'foo@example.com', c.normalize("\"foo\"@ExampLE.CoM")
      # Do not normalize name part.
      assert_equal 'Foo@example.com', c.normalize('Foo@example.com')
    end

    def test_valid?
      c = MailAddress
      assert_equal true,  c.valid?('user@example.com')
      assert_equal true,  c.valid?('valid+@example.com')
      assert_equal true,  c.valid?('+valid@example.com')
      assert_equal true,  c.valid?('_@example.com')
      assert_equal true,  c.valid?('us..er@example.com')
      # Make this address valid.  System uses this address for local account.
      assert_equal true,  c.valid?('user@localdomain')
      assert_equal false, c.valid?(nil)
      assert_equal false, c.valid?('')
      assert_equal false, c.valid?('invalid!@example.com')
      assert_equal false, c.valid?('invalid')
      assert_equal false, c.valid?('user@example..com')
    end

    def test_obfuscate
      c = MailAddress
      assert_equal 'user@e...', c.obfuscate('user@example.com')
      assert_equal '2006@e...', c.obfuscate('2006@example.com')
    end

    def test_obfuscate_str
      c = MailAddress
      assert_equal 'user@e...', c.obfuscate_str('user@example.com')
      assert_equal 'a t@e... b s@f... c',
	c.obfuscate_str('a t@e.com b s@f.com c')
    end
  end
end
