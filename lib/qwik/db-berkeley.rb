# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

begin
  require 'bdb'
  $have_bdb_so = true
rescue LoadError
  $have_bdb_so = false
end

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/util-pathname'
require 'qwik/db-b-backup'

module Qwik
  class BerkeleyDB
    include Enumerable

    def initialize(path, spath)
      @path = path
      raise 'No such dir. '+@path.to_s unless @path.directory?
      @path_h = {}
      @spath = spath
      @spath_h = {}

      @db = open_db(@path+'pages.db')
      @mtime_db = open_db(@path+'mtime.db')

      @backupdb = BackupBDB.new(@path)
    end
    attr_reader :backupdb

    def open_db(path)
      options = 0
      options = BDB::CREATE | BDB::EXCL unless path.exist? # don't over write
      begin
	db = BDB::Hash.open(path.to_s, nil, options)
      rescue => e
	p 'e is '+e
	@path.each_entry {|pa|
	  if /\.db\z/ =~ pa.to_s
	    p pa
	    (@path+pa).unlink
	  end
	}
	$try ||= 0
	$try += 1
	retry if $try < 5
	raise e
      end
      return db
    end

    def close
      @backupdb.close
      @db.close
      @mtime_db.close
    end

    def exist?(k)
      begin
	return true if baseexist?(k)
	return true if spath(k).exist?
      rescue
	return false
      end
      return false
    end

    def baseexist?(k)
      v = db_get(k)
      return true if v
      begin
	return true if path(k).exist?
      rescue
	return false
      end
      return false
    end

    def create(k)
      touch(k) unless exist?(k)
    end

    def get(k)
      v = db_get(k)
      return v if v
      if  path(k).exist?
	str = path(k).get
	mtime = path(k).mtime
	db_put(k, str, mtime)
	return str
      end
      return spath(k).get if spath(k).exist?
      ''
    end

    def db_get(k)
      begin
	@db.get(k)
      rescue BDB::Fatal => e
	return if e.message == 'closed DB'
	raise e
      end
    end

    def mtime(k)
      v = db_get(k)
      if v
	num = @mtime_db.get(k)
	return Time.at(num.to_i)
      end
      return  path(k).mtime if  path(k).exist?
      return spath(k).mtime if spath(k).exist?
      Time.at(0) # the file is already deleted.
    end

    def add(k, v, time=Time.now)
      # FIXME: use @db.add(k, v) instead
      put(k, get(k)+v, time)
    end

    def put(k, v, time=Time.now)
      db_put(k, v, time)
      @backupdb.put(k, time, v)
      path(k).open('wb'){|f| f.print(v) } # write through
    end
    alias set put

    def db_put(k, v, mtime)
      @db.put(k, v)
      @mtime_db.put(k, mtime.to_i.to_s)
    end

    def touch(k)
      add(k, '') # add null String
    end

    def delete(k)
      put(k, nil)
      path(k).unlink if path(k).exist?
    end

    def each
      ar = []
      @db.each {|k, v|
	next if v.nil?
	ar << k
      }
      dir = @path.to_s
      Dir.foreach(dir) {|file|
	f = dir+'/'+file
	next unless FileTest.file?(f)
	base = file.to_s
	if /\A([_A-Za-z0-9]+)\.txt\z/ =~ base
	  b = $1
	  ar << b if !ar.include?(b)
	end
      }
      ar.sort.each {|k|
	yield(k)
      }
    end

    def last_page_time # mtime of the newest page
      t = map {|k| mtime(k) }.max
      t = Time.at(0) if t.nil?
      t
    end

    # QuickML support
    def last_article_time # mtime of the newest file
      max = maxfile = nil
      @path.each_entry {|file|
	f = @path+file
	next unless f.file?
	base = file.to_s
	next if /\A\./ =~ base ||
	  base == ',config' ||
	  base == '_GroupConfig.txt' ||
	  base == ',charset' ||
	  base == '_GroupCharset.txt'
	next if /\.db\z/ =~ base
	mt = f.mtime
	if max.nil? || max < mt
	  max = mt 
	  maxfile = f
	end
      }
      max # return nil if there is no file.
    end

    private

    def path(k)
      gen_path(@path, @path_h, k)
    end

    def spath(k)
      gen_path(@spath, @spath_h, k)
    end

    def gen_path(path, h, k)
      pa = h[k]
      return pa if pa
      raise 'Character type error '+k unless /\A([_A-Za-z0-9]+)\z/ =~ k
      h[k] = path+(k+'.txt')
      h[k]
    end
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  require 'qwik/config'
  require 'qwik/farm'
  require 'qwik/server-memory'
  require 'qwik/test-module-session'
  $test = true
end

if defined?($test) && $test
  class TestBerkeleyDB < Test::Unit::TestCase
    include TestSession

    def test_bdb
      @pagedb = @site.db

      ok_eq(false, @pagedb.exist?('1'))

      @pagedb.create('1')
      ok_eq(true, @pagedb.exist?('1'))
      ok_eq('', @pagedb.get('1'))

      @pagedb.put('1', 't')
      ok_eq('t', @pagedb.get('1'))

      assert_instance_of(Time, @pagedb.mtime('1'))

      @pagedb.add('1', 's')
      ok_eq('ts', @pagedb.get('1'))

      assert_instance_of(Time, @pagedb.last_page_time)

      assert_instance_of(Time, @pagedb.last_article_time)

      @pagedb.each {|f|
	assert_instance_of(String, f)
      }

      @pagedb.touch('1')

      @pagedb.delete('1')
      ok_eq(false, @pagedb.exist?('1'))

#      page = @pagedb.db_get('1') # db_get should be private.
#      ok_eq(nil, page)
#      page = @pagedb.get('1')
#      ok_eq('', page)

      @pagedb.touch('1')
      ok_eq(true, @pagedb.exist?('1'))

      @pagedb.delete('1')
      ok_eq(false, @pagedb.exist?('1'))

      ok_eq(true,  @pagedb.exist?('_SideMenu'))
      ok_eq(false, @pagedb.baseexist?('_SideMenu'))

      # test_not_exist
      @pagedb = @site.db

      ok_eq(false, @pagedb.exist?('1'))

      @pagedb.put('1', 't')
      ok_eq(true, @pagedb.exist?('1'))

      # test_super_files
      @pagedb = @site.db

      page = @site['_SiteConfig']
      assert_match(/theme/, page.get)

      @dir.erase_all_for_test

      page = @site['_SiteConfig']
      assert_match(/theme/, page.get)
    end
  end

  class CheckBerkeleyDB < Test::Unit::TestCase
    def test_bdb
      return if $0 != __FILE__		# Only for separated test.

      path = 'test.db'.path
      path.unlink if path.exist?
      options = BDB::CREATE | BDB::EXCL	# Do not over write.
      db = BDB::Hash.open(path.to_s, nil, options)
      db.put('1', 't')
      ok_eq('t', db.get('1'))
      db.close
      path.unlink if path.exist?
    end
  end
end
