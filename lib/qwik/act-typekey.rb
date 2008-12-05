# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
begin
  require 'qwik/typekey'
  $have_typekey = true
rescue LoadError
  $have_typekey = false
end

module Qwik
  class Action
    def pre_act_typekey
      if @req.query.length == 0
	return typekey_redirect_to_typekey
      end

      sitetoken = typekey_get_sitetoken
      return typekey_error_no_sitetoken if sitetoken.nil?

      tk = TypeKey.new(sitetoken, '1.1')
      key = typekey_get_publickey(tk)

      email = @req.query['email']
      name  = @req.query['name']
      nick  = @req.query['nick']
      ts    = @req.query['ts']		# time stamp
      sig   = @req.query['sig']
      # <email>::<name>::<nick>::<ts>::<site-token>
      begin
	tk.verify(email, name, nick, ts, sig)
      rescue VerifyFailed
	return c_notice(_('Verify failed.')) {
	  _('Verify failed.')
	}
      rescue TimeOutError
	return c_notice(_('Time out.')) {
	  _('Time out.')
	}
      end

      sid = session_store(email)
      @res.set_cookie('sid', sid)	# Set Session id by cookie

      return c_notice(_('Login')+' '+_('Success'), 'FrontPage.html') {
	[:p, [:a, {:href=>'FrontPage.html'}, _('Go next')]]
      }
    end

    def typekey_error_no_sitetoken
      return c_nerror(_('Cannot use.')) {
	[:p, _('There is no site token for TypeKey.')]
      }
    end

    def typekey_redirect_to_typekey
      sitetoken = typekey_get_sitetoken
      return typekey_error_no_sitetoken if sitetoken.nil?

      tk = TypeKey.new(sitetoken, '1.1')

      # http://example.com/test/.typekey
      ret_url = c_relative_to_absolute('.typekey')
      url = tk.get_login_url(ret_url, true)
      return c_nredirect('Go TypeKey', url)	# Redirect to TypeKey
    end

    TYPEKEY_SITETOKEN_FILE = 'typekey-sitetoken.txt'

    def typekey_get_sitetoken
      file = @config.etc_dir.path+TYPEKEY_SITETOKEN_FILE
      return nil if ! file.exist?
      return file.read.chomp
    end

    def typekey_get_publickey(tk)
      # Make cache timeout to 100 years.  Only for test.
     #tk.key_cache_timeout = 60 * 60 * 24 * 365 * 100	# 100 years
      tk.key_cache_timeout = 60 * 60 * 24 * 365 * 2	# 2 years
      cache_path = @config.cache_dir.path+'typekey-publickey.txt'
      tk.key_cache_path = cache_path.to_s
      return tk.get_key
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActTypekey < Test::Unit::TestCase
    include TestSession

    def test_act_typekey
      t_add_user
      t_site_open	# OPEN site

      res = session

      # test_get_sitetoken
      sitetoken = @action.typekey_get_sitetoken
      return if sitetoken.nil?	# Stop test here.
      eq 20, sitetoken.length

      # See the FrontPage.
      res = session '/test/'
      ok_title('FrontPage')

      # See the Login page.
      res = session('/test/.login') {|req|
	req.cookies.clear
      }
      ok_title('Login')

      # Redirect to TypeKey login page.
      res = session '/test/.typekey'
      eq 302, @res.status
      assert_match(%r|\Ahttps://www.typekey.com/t/typekey/login|,
		   @res['Location'])
      meta = @res.body.get_path('//meta[2]')
      assert_match(%r|url=https://www.typekey.com/t/typekey/login|,
		   meta[1][:content])

      # The client returned from the TypeKey login page.
      begin
	res = session '/test/.typekey?&ts=1111111111&email=guest@example.com&name=guestexample&nick=guest&sig=ttttttttttttttttttttttttttt=:LLLLLLLLLLLLLLLLLLLLLLLLLLL='
	ok_title('Verify failed.')
      rescue => e
	p 'failed.', e
      end

      begin
	res = session '/test/.typekey?&ts=1110026410&email=2005@eto.com&name=etocom&nick=eto&sig=tRUcIO6haAHv/vQSguPk2EijTrc=:LCUvoHCXFLaeO8SoldCKmFr2Guo='
	ok_title('Time out.')
      rescue => e
	p 'failed.', e
      end
    end

    def nutypekey_get_sitetoken
      file = @config.etc_dir.path+Qwik::Action::TYPEKEY_SITETOKEN_FILE
      return file.read.chomp
    end

    def test_typekey
      return if $0 != __FILE__	# just only for unit test.
      return if ! $have_typekey

      res = session

      sitetoken = 't'
      tk = TypeKey.new(sitetoken, '1.1')
      tk.key_cache_timeout = 60 * 60 * 24 * 365 * 100	# 100years
      tk.key_cache_path = (@config.cache_dir.path+'typekey-publickey.txt').to_s

      return_url = 'http://example.com/.typekey'
      eq 'https://www.typekey.com/t/typekey/login?t=t&_return=http://example.com/.typekey&v=1.1', tk.get_login_url(return_url)
      eq 'https://www.typekey.com/t/typekey/login?t=t&need_email=1&_return=http://example.com/.typekey&v=1.1', tk.get_login_url(return_url, true)
      eq 'https://www.typekey.com/t/typekey/logout?_return=http://example.com/.typekey', tk.get_logout_url(return_url)

      begin
	key = tk.get_key
	eq ['p', 'q', 'pub_key', 'g'], key.keys
      rescue
	p 'failed'
      end
    end

    def test_verify
      return if $0 != __FILE__	# just only for unit test.
      return if ! $have_typekey

      res = session
      sitetoken = @action.typekey_get_sitetoken
      tk = TypeKey.new(sitetoken, '1.1')
      tk.key_cache_timeout = 60 * 60 * 24 * 365 * 100	# 100years
      tk.key_cache_path = (@config.cache_dir.path+'typekey-publickey.txt').to_s

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
end
