# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/util-pathname'

module Qwik
  class Site
    def erase_all
      @pages.erase_all
    end
  end

  class Pages
    def erase_all
      @db.erase_all
      @pages = {}
    end
  end

  class FileSystemDB
    def erase_all
      # do nothing
    end
  end

  # test-module-bdb
  module BDBEraseAllModule
    def bdb_erase_all(db)
      begin
	db.each {|k, v|
	  db[k] = nil
	}
      rescue Fatal => e
	return if e.message == 'closed DB'
	raise e
      end
    end
  end

  class BerkeleyDB
    include BDBEraseAllModule

    def erase_all
      @backupdb.erase_all
      bdb_erase_all(@db)
      @mtime_db.erase_all
    end
  end

  class BackupBDB
    include BDBEraseAllModule

    def erase_all
      bdb_erase_all(@db)
    end
  end
end

class Pathname
  def erase_all_for_test
    self.each_entry {|file|
      base = file.to_s
      next if base == '.' || base == '..'

      f = self + file

      if f.directory?
	f.erase_all_for_test	# Recursive.
	next
      end

      if f.exist?
	f.unlink
      end
    }
  end

  def setup
    self.teardown if self.directory?
    self.check_directory
  end

  def teardown
    unless self.directory?
      return
    end
    self.erase_all_for_test
  end

  # test-module-bdb
  def erase_db(f)
    begin
      erase_all_db(f)
    rescue => e
      return
    end
  end

  def erase_all_db(f)
    return unless f.exist?
    db = BDB::Hash.new(f.to_s, nil, 0)
    db.each {|k, v|
      db[k] = nil
    }
    db.close
  end
  private :erase_db, :erase_all_db
end
