#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '../../lib' unless $LOAD_PATH.include?('../../lib')
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
      @backup_path+(t+'_'+k)
    end
    private :path

    def exist?(k, time)
      path(k, time).exist?
    end

    def get(k, time)
      path(k, time).read
    end

    def check(k, v)
    end

    def put(k, v, time)
      @backup_path.check_directory
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
	  v = get(key, time)
	  ar << [key, v, time]
	end
      }

      ar.sort_by {|key, v, time|
	time
      }.each {|key, v, time|
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
    def test_backupdb
      config = Qwik::Config.new

      path = './test/'.path
      path.setup

      spath = config.super_dir.path
      pagedb = Qwik::FileSystemDB.new(path, spath)

      # test_initialize
      backupdb = Qwik::BackupDB.new(path)
      pagedb.register_observer(backupdb)

      pagedb.create('1')
      pagedb.put('1', 't', 1)

      budb = pagedb.backupdb
      assert_instance_of(Qwik::BackupDB, budb)

      # test_each_by_key
      budb.each_by_key('1') {|v, time|
	assert_instance_of(String, v)
	assert_instance_of(Time, time)
	s = budb.get('1', time)
	assert_instance_of(String, s)
	ok_eq(v, s)
      }

      #put
      #exist?

      path.teardown
    end
  end
end
