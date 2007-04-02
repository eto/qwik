# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'pathname'
require 'qwik/db-berkeley'

module Qwik
  class BackupBDB
    def initialize(path)
      @backup_path = path+'.backup'
      @db = open_db(path+'backup.db')
    end

    def open_db(path)
      options = 0
      unless path.exist? # don't over write
	options = BDB::CREATE | BDB::EXCL
      end
      db = BDB::Hash.open(path.to_s, nil, options)
      return db
    end

    def close
      @db.close
    end

    def path(k, time) # k is String, t is Time
      t = time.to_i.to_s
      @backup_path+(t+'_'+k)
    end
    private :path

    def exist?(k, time)
      v = db_get(k, time)
      return true if v
      path(k, time).exist?
    end

    def get(k, time)
      v = db_get(k, time)
      return v if v
      if  path(k, time).exist?
	str = path(k, time).open {|f| f.read }
	put(k, time, v)
	return str
      end
      ''
    end

    def db_get(k, time)
      @db.get(make_key(k, time))
    end

    def make_key(k, time)
      k+','+time.to_i.to_s
    end
    private :db_get, :make_key

    def put(k, time, v)
      @db.put(make_key(k, time), v)
    end
    alias set put

    def each_by_key(key)
      ar = []
      # FIXME: use each_by_prefix(key+',') instead
      @db.each {|k, v|
	next if v.nil?
	if /\A#{key},([0-9]+)\z/ =~ k # begin with key?
	  time = Time.at($1.to_i)
	  ar << [v, time]
	end
      }

      if @backup_path.exist?
	@backup_path.each_entry {|file|
	  f = @backup_path+file
	  next unless f.file?
	  base = file.to_s
	  if /\A([0-9]+)_#{key}\z/ =~ base # end with key ?
	    time = Time.at($1.to_i)
	    v = get(key, time)
	    ar << [v, time]
	  end
	}
      end

      ar.sort_by {|v, time|
	time
      }.each {|v, time|
	yield(v, time)
      }
    end
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  require 'qwik/config'
  require 'qwik/test-module-path'
  $test = true
end

if defined?($test) && $test
  class TestBackupBDB < Test::Unit::TestCase
    def setup
      @config = Qwik::Config.new
      @config[:db] = 'bdb'
      @dir = 'test/'.path
      @dir.setup
      path = @dir
      spath = @config.super_dir.path
      @pagedb = Qwik::BerkeleyDB.new(path, spath)
    end

    def teardown
      @pagedb.close if @pagedb
      @dir.teardown
    end

    def test_backupdb
      @pagedb.create('1')
      @pagedb.put('1', 't', Time.at(1))

      budb = @pagedb.backupdb
      assert_instance_of(Qwik::BackupBDB, budb)

      budb.each_by_key('1') {|v, time|
	assert_instance_of(String, v)
	assert_instance_of(Time, time)
	s = budb.get('1', time)
	assert_instance_of(String, s)
	eq v, s
      }

      #put
      #exist?
    end
  end
end
