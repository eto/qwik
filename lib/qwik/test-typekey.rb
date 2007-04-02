# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/typekey'
require 'qwik/testunit'
require 'qwik/config'
require 'qwik/util-pathname'
$test = true

class TestTypekey < Test::Unit::TestCase
  def typekey_get_sitetoken(config)
    file = config.etc_dir.path+'typekey-sitetoken.txt'
    return nil if ! file.exist?
    return file.open {|f| f.gets }.chomp
  end

  def test_typekey
    return if $0 != __FILE__	# just only for unit test.
    config = Qwik::Config.new

    sitetoken = 't'
    tk = TypeKey.new(sitetoken, '1.1')
    tk.key_cache_timeout = 60 * 60 * 24 * 365 * 100	# 100years
    tk.key_cache_path = (config.cache_dir.path+'typekey-publickey.txt').to_s

    return_url = 'http://e.com/.typekey'
    ok_eq('https://www.typekey.com/t/typekey/login?t=t&_return=http://e.com/.typekey&v=1.1', tk.get_login_url(return_url))
    ok_eq('https://www.typekey.com/t/typekey/login?t=t&need_email=1&_return=http://e.com/.typekey&v=1.1', tk.get_login_url(return_url, true))
    ok_eq('https://www.typekey.com/t/typekey/logout?_return=http://e.com/.typekey', tk.get_logout_url(return_url))

    begin
      key = tk.get_key
      ok_eq(['p', 'q', 'pub_key', 'g'], key.keys)
    rescue
      p 'failed'
    end
  end

  def test_verify
    return if $0 != __FILE__	# just only for unit test.
    config = Qwik::Config.new

    sitetoken = typekey_get_sitetoken(config)
    tk = TypeKey.new(sitetoken, '1.1')
    tk.key_cache_timeout = 60 * 60 * 24 * 365 * 100	# 100years
    tk.key_cache_path = (config.cache_dir.path+'typekey-publickey.txt').to_s

    ts = '1111111111'
    email = 'guest@example.com'
    name = 'guestexample'
    nick = 'guest'
    sig = 'ttttttttttttttttttttttttttt=:LLLLLLLLLLLLLLLLLLLLLLLLLLL='

    begin
      assert_raise(VerifyFailed){
	result = tk.verify(email, name, nick, ts, sig)
      }
    rescue => e
      p 'failed', e
    end
  end
end
