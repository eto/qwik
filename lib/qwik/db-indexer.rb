# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

begin
#  require 'senna'
#  $have_senna_so = true
rescue LoadError
  $have_senna_so = false
end
$have_senna_so = false

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/util-pathname'

module Qwik
  class DBIndexer
    def initialize(path)
      @path = path

      @index = nil
      return if ! $have_senna_so

      @cache_path = @path+'.cache'
      @index_path = @cache_path+'index'
      check_directory

      @index = Senna::Index.new((@cache_path+'index').to_s)
    end

    def check(k, v)
      return update(k, v)
    end

    def put(k, v, time=nil)
      return update(k, v)
    end

    def update(k, v)
      return if @index.nil?

      # Try to read old content.
      pa = path(k)
      old = nil
      old = pa.get if pa.exist?

      # Avoid \0 from its contents.
      v = v.gsub("\0", '')if v.include?("\0")	# FIXME: Too ad hoc.

      return false if v == old		# Not necessary to update.

      result = @index.upd(k, old, v)	# FIXME: Take care of result?

      # Store new value to cached content.
      check_directory
      pa.open('wb') {|f| f.print(v) }

      return result
    end

    def search(key)
      return nil if @index.nil?

      records = @index.sel(key)
      return [] if records.nil? || records.nhits == 0

      ar = []
      while res = records.next
	ar << res
      end
      return ar
    end

    private

    def check_directory
      @cache_path.check_directory
      @index_path.check_directory
    end

    def path(k)
      return @index_path+(k+'.txt')
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
  class TestDBIndexer < Test::Unit::TestCase
    def setup_db
      config = Qwik::Config.new
      spath = config.super_dir.path
      path = './.test/'.path
      path.setup
      db = Qwik::FileSystemDB.new(path, spath)
      return path, db
    end

    def teardown_db(path)
      path.teardown
    end

    def test_all
      # setup
      path, db = setup_db

      # Initialize DBIndexer.
      indexer = Qwik::DBIndexer.new(path)
      db.register_observer(indexer)	# Regist to the DB.

      # Put test contents.
      db.put('a', 'This is a test.')
      db.put('b', 'This is a test, too.')

      # test_search
      if $have_senna_so
        ok_eq(['a', 'b'], indexer.search('test'))
        ok_eq(['b'], indexer.search('too'))
        ok_eq([], indexer.search('nosuch'))
      end

      teardown_db(path)
    end

    def test_pre_content
      # Setup db
      path, db = setup_db

      # Put test contents before to setup indexer.
      db.put('a', 'This is a test.')
      db.put('b', 'This is a test, too.')

      # Initialize DBIndexer.
      indexer = Qwik::DBIndexer.new(path)
      db.register_observer(indexer)	# Regist to the DB.

      # test_search
      if $have_senna_so
        ok_eq(['a', 'b'], indexer.search('test'))
        ok_eq(['b'], indexer.search('too'))
        ok_eq([], indexer.search('nosuch'))
      end

      teardown_db(path)
    end
  end
end
