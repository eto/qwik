# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    # ============================== verify
    # called from act-login.rb:41
    def check_session
      sid = @req.cookies['sid']		# get session id from cookie.
      return if sid.nil? || sid.empty?	# return if you don't have session id.
      sdb = @memory.sessiondb
      user = sdb.get(sid)	# Get user from SessionDB.
      return if user.nil?	# return if there is no session id.
      @req.user = user	# OK! I have your sesssion id.  I know who you are.
      @req.auth = 'session'
    end

    # ============================== login
    # called from act-login, act-typkey and this file.
    def session_store(user)
      sdb = @memory.sessiondb
      sid = sdb.generate_sid	# Make a new session id.
      sdb.put(sid, user)	# Store the session id to session db.
      return sid
    end

    # ============================== logout
    def session_clear
      sid = @req.cookies['sid']	# Get sid from cookie.
      return if sid.nil? || sid.empty?	# return if you don't have session id.
      sdb = @memory.sessiondb
      user = sdb.get(sid)	# Get user from SessionDB.
      return if user.nil?	# return if there is no session id.
      sdb.clear(sid)
    end
  end

  class SessionDB
    DEFAULT_EXPIRE_TIME = 60 * 60 * 24 * 14	# 2 weeks

    def initialize(config)
      @config = config
      @config.cache_dir.path.check_directory
      @path = @config.cache_dir.path+'sid'
      @path.check_directory
      @expire_time = DEFAULT_EXPIRE_TIME
    end

    def generate_sid
      str = Time.now.to_i.to_s+':'+rand.to_s
      return str.md5hex
    end

    def path(sid)
      @path + sid
    end

    def put(sid, user)
      path(sid).put(user)
    end

    def clear(sid)
      file = path(sid)
      return nil if ! file.exist?
      file.unlink # delete it
    end

    def get(sid)
      return if sid.nil? || sid.empty?
      file = path(sid)
      return nil if ! file.exist?
      mtime = file.mtime
      diff = Time.now.to_i - mtime.to_i
      if @expire_time < diff
	clear(sid)
	return nil
      end
      str = file.read
      return str
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestCommonSession < Test::Unit::TestCase
    include TestSession

    def test_all
      # not yet
    end
  end

  class TestSessionDB < Test::Unit::TestCase
    def test_all
      if defined?($test_memory)
	@memory = $test_memory
      else
	@memory = Qwik::ServerMemory.new(@config)
      end

      sdb = @memory.sessiondb

      # test generate session id
      sid = sdb.generate_sid
      ok_eq(32, sid.length)
      assert_match(/\A[0-9a-f]+\z/, sid)

      # test put
      sdb.put(sid, 'user@e.com')
      file = sdb.path(sid)
      ok_eq(true, file.exist?)

      # test get empty
      ok_eq(nil, sdb.get(nil))
      ok_eq(nil, sdb.get(''))

      # test get
      user = sdb.get(sid)
      ok_eq('user@e.com', user)

      mtime = file.mtime
      oldtime = Time.at(mtime.to_i - 60 * 60 * 24 * 100) # 100 days ago.
      file.utime(oldtime, oldtime)

      # test session expired
      user = sdb.get(sid)
      ok_eq(nil, user)
      ok_eq(false, file.exist?)
    end
  end
end
