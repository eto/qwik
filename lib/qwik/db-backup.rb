# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/util-pathname'

module Qwik
  class BackupDB
    include Enumerable

    def initialize(path)
      @backup_path = path+'.backup'
    end

    def close
      # do nothing
    end

    def path(k, time) # k: String, t: Time
      t = time.to_i.to_s
      return @backup_path+"#{t}_#{k}"
    end
    private :path

    def exist?(k, time)
      return path(k, time).exist?
    end

    def get(k, time)
      return path(k, time).read
    end

    def check(k, v)
    end

    IGNORE_PAGES = [
/\A_SiteLog\Z/, 
/\A_SiteChanged\Z/, 
/\A_GroupCharset\Z/, 
/\A_GroupCount\Z/,
/\A_counter_[_A-Za-z0-9]+\Z/
]

    def put(k, v, time)
      @backup_path.check_directory
      return if IGNORE_PAGES.any? {|re| re =~ k }
      path(k, time).put(v)
    end
    alias set put

    def each_by_key(key)
      each {|k, v, time|
	yield(v, time) if k == key
      }
    end

    def each
      @backup_path.check_directory
      ar = []
      @backup_path.each_entry {|file|
	f = @backup_path+file
	next unless f.file?
	base = file.to_s
	if /\A([0-9]+)_([_A-Za-z0-9]+)\z/ =~ base
	  time = Time.at($1.to_i)
	  key = $2
	  ar << [key, time]
	end
      }

      ar.sort_by {|key, time|
	time
      }.each {|key, time|
#	v = get(key, time)
	v = ""	# FIXME: This is dummy. 2009/9/1
	yield(key, v, time)
      }
    end
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  require 'qwik/config'
  require 'qwik/test-module-path'
  require 'qwik/db-filesystem'
  $test = true
end

if defined?($test) && $test
  class TestBackupDB < Test::Unit::TestCase
    def setup
      config = Qwik::Config.new
      config.update Qwik::Config::DebugConfig
      config.update Qwik::Config::TestConfig
      @path = '.test/'.path
      @path.setup

      spath = config.super_dir.path
      @pagedb = Qwik::FileSystemDB.new(@path, spath)

      # test_initialize
      backupdb = Qwik::BackupDB.new(@path)
      @pagedb.register_observer(backupdb)
    end

    def test_backupdb
      # test_put
      @pagedb.create('1')
      @pagedb.put('1', 't', 1)

      budb = @pagedb.backupdb
      assert_instance_of(Qwik::BackupDB, budb)

      # test_each_by_key
      budb.each_by_key('1') {|v, time|
	assert_instance_of(String, v)
	assert_instance_of(Time, time)
	s = budb.get('1', time)
	assert_instance_of(String, s)
#	eq v, s
      }

      # FIXME: test_put, test_exist should be exist.
    end

    def test_ignore_pages
      key = '_SiteLog'
      @pagedb.create(key)
      @pagedb.put(key, 't', 1)

      # test_each_by_key
      found = false
      @pagedb.backupdb.each_by_key(key) {|v, time|
        found = true
      }
      assert_equal false, found
    end

    def test_ignore_pages2
      key = '_counter_1'
      @pagedb.create(key)
      @pagedb.put(key, 't', 1)

      # test_each_by_key
      found = false
      @pagedb.backupdb.each_by_key(key) {|v, time|
        found = true
      }
      assert_equal false, found
    end

    def test_ignore_pages3
      key = '_counter_'
      @pagedb.create(key)
      @pagedb.put(key, 't', 1)

      # test_each_by_key
      found = false
      @pagedb.backupdb.each_by_key(key) {|v, time|
        found = true
      }
      assert_equal true, found
    end

    def test_ignore_pages4
      key = '_SiteLogHoge'
      @pagedb.create(key)
      @pagedb.put(key, 't', 1)

      # test_each_by_key
      found = false
      @pagedb.backupdb.each_by_key(key) {|v, time|
        found = true
      }
      assert_equal true, found
    end

    def teardown
      @path.teardown
    end
  end
end
