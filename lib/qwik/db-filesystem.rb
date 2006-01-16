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
  class FileSystemDB
    include Enumerable

    def initialize(path, spath)
      @path = path
      @path_h = {}
      @spath = spath
      @spath_h = {}

      @observer = []
    end

    # FIXME: Obsolete this method.
    def backupdb
      # FIXME: Check if it is the backupdb.
      return @observer[0]
    end

    def check_integrity(ob)
      self.each {|k|
	v = self.get(k)
	ob.check(k, v)
      }
    end

    def register_observer(ob)
      check_integrity(ob)
      @observer << ob
    end

    def close
      # do nothing
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
      if  path(k).exist?
	return path(k).read
      end
      return spath(k).read if spath(k).exist?
      return ''		# Not nil.
    end

    def mtime(k)
      return  path(k).mtime if  path(k).exist?
      return spath(k).mtime if spath(k).exist?
      return Time.at(0)		# Not nil.  The file is already deleted.
    end

    def add(k, v)
      put(k, get(k)+v)
    end

    def put(k, v, time=nil)
      # FIXME: Should make it atomic.  Use mutex.
      path(k).put(v)
      if time
	time = Time.at(time) if time.is_a?(Integer)
	path(k).utime(time, time)
      else
	time = Time.now
      end

    # @backupdb.put(k, time, v)
      @observer.each {|ob|
	ob.put(k, v, time)
      }
    end
    alias set put

    def touch(k)
      add(k, '')	# add null String
    end

    def delete(k)
      path(k).unlink if path(k).exist?
    end

    def each(with_super=false)
      ar =  get_dir_list(@path.to_s)
      ar += get_dir_list(@spath.to_s) if with_super
      ar.sort.each {|b|
	yield(b)
      }
    end

    def each_all(&b)
      each(true, &b)
    end

    def last_page_time # mtime of the newest page
      t = map {|k| mtime(k) }.max
      t = Time.at(0) if t.nil?
      return t
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

	mt = f.mtime
	if max.nil? || max < mt
	  max = mt 
	  maxfile = f
	end
      }
      return max # return nil if there is no file.
    end

    private

    def path(k)
      return gen_path(@path, @path_h, k)
    end

    def spath(k)
      return gen_path(@spath, @spath_h, k)
    end

    def gen_path(path, h, k)
      pa = h[k]
      return pa if pa
      raise 'Character type error '+k unless /\A([_A-Za-z0-9]+)\z/ =~ k
      h[k] = path+(k+'.txt')
      return h[k]
    end

    def get_dir_list(dir)
      ar = []
      #qp dir
      Dir.foreach(dir) {|file|
	f = dir+'/'+file
	next unless FileTest.file?(f)
	base = file.to_s
	if /\A([_A-Za-z0-9]+)\.txt\z/ =~ base
	  b = $1
	  ar << b
	end
      } 
      return ar
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
  class TestFileSystemDB < Test::Unit::TestCase
    def test_fsdb
      # setup
      config = Qwik::Config.new
#      config[:debug] = true
      spath = config.super_dir.path
      path = './test/'.path
      path.setup
      db = Qwik::FileSystemDB.new(path, spath)

      # test_exist?
      ok_eq(false, db.exist?('1'))

      # test_create
      db.create('1')
      ok_eq(true, db.exist?('1'))
      ok_eq('', db.get('1'))

      # test_put
      db.put('1', 't')
      ok_eq('t', db.get('1'))

      # test_put_with_time
      db.put('1', 't', Time.at(0))
      ok_eq(0, db.mtime('1').to_i)	# test_mtime
      # test_put_with_time_num
      db.put('1', 't', 1)
      ok_eq(1, db.mtime('1').to_i)

      # test_last_page_time
      ok_eq(Time.at(1), db.last_page_time)
      # test_last_article_time
      ok_eq(Time.at(1), db.last_article_time)

      # test_add
      db.add('1', 's')
      ok_eq('ts', db.get('1'))

      # test_get_dir_list
      ar = []
      db.instance_eval {
	dir = @path.to_s
	ar += get_dir_list(dir)
      }
      ok_eq(['1'], ar)

      # test_get_dir_list_spath
      ar = []
      db.instance_eval {
	dir = @spath.to_s
	ar += get_dir_list(dir)
      }
      ok_eq(true, ar.include?('FrontPage'))

      # test_each
      db.each {|f|
	assert_instance_of(String, f)
      }

      # test_each_all
      db.each(true) {|f|
	assert_instance_of(String, f)
      }
      db.each_all {|f|
	assert_instance_of(String, f)
      }

      # test_backup_db
     #assert_instance_of(Qwik::BackupDB, db.backup_db('1'))

      # test_touch
      db.touch('1')

      # test_delete
      db.delete('1')
      ok_eq(false, db.exist?('1'))

      # test_super_pages
      ok_eq(true,  db.exist?('_SideMenu'))
      ok_eq(false, db.baseexist?('_SideMenu'))

      # teardown
      path.teardown
    end
  end
end
