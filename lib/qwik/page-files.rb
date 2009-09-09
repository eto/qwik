# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

require 'fileutils'

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/util-pathname'
require 'qwik/page-images'
require 'qwik/util-filename'

module Qwik
  class AlreadyExist < StandardError; end
  class CanNotUseJapaneseCharacter < StandardError; end
  class FileNotExist < StandardError; end
  class FailedToDelete < StandardError; end
  class CanNotAccessParentDirectory < StandardError; end

  module AttachModule
    # FIXME: AttachModule#path should be private.
    def path(filename)
      @attach_path.check_directory
      return @attach_path + Filename.encode(filename)
    end

    def exist?(filename)
      return path(filename).exist?
    end

    def get(filename)
      return path(filename).read
    end

    def overwrite(filename, content)
      put(filename, content, true)
    end

    def put(filename, content, overwrite=nil, time=nil)
      raise AlreadyExist if ! overwrite && exist?(filename)

      put_internal(filename, content, time)

      return nil
    end

    def total
      t = 0
      self.each {|f|
        s = self.path(f).size?
        t += s if s
      }
      return t
    end

    def fput(filename, content, overwrite=nil, time=nil)	# obsolete
      # overwrite is always ignored.
      res = filename
      if exist?(filename)
	res, num = search_unused {|num| another_file(num, filename) }
      end

      put_internal(res, content, time)

      return res	# Return result.
    end

    def another_file(num, filename)
      return "#{num}-#{filename}"	# '1-t.txt'
    end

    DEFAULT_BACKUP = false
    def delete(filename, backup = DEFAULT_BACKUP)
      fpath = path(filename)
      raise FileNotExist if ! fpath.exist?

      if backup		# Move to backup.
	dirpath = fpath.dirname
	basepath = fpath.basename
	moveto_basepath = ".._#{Time.now.to_i}_"+basepath
	moveto_path = dirpath + moveto_basepath
	FileUtils.mv(fpath.to_s, moveto_path.to_s)
      else
	fpath.unlink	# Real unilnk.
      end

      raise FailedToDelete if exist?(filename)

      return nil
    end

    def list
      return [] unless @attach_path.directory?
      ar = []
      @attach_path.each_entry {|file|
	next if file.directory?
	next if file.to_s == 'CVS'
	next if /\A\./ =~ file.to_s
	ar << Filename.decode(file.to_s)
      }
      return ar.sort!
    end

    def each
      return unless @attach_path.directory?
      self.list.each {|a|
	yield(a)
      }
    end

    private

    def put_internal(filename, content, time=nil)
      path(filename).put(content)
      set_time(filename, time) if time
    end

    def set_time(filename, time)
      time = Time.at(time) if time.is_a?(Integer)
      path(filename).utime(time, time)
    end

    MAX = 1000
    def search_unused
      (1..MAX).each {|num|
	f = yield(num)
	return f, num if ! exist?(f)
      }
      raise 'MAX Exceed.'
    end
  end

  class PageFiles
    include Enumerable
    include AttachModule

    def initialize(site_dir, key)
      @attach_path = site_dir.path+"#{key}.files"
    end
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  require 'qwik/test-module-path'
  $test = true
end

if defined?($test) && $test
  require 'qwik/test-module-public'

  class TestPageFiles < Test::Unit::TestCase
    include TestModulePublic

    def setup_files
      dir = '.test/'.path
      dir.setup
      files = Qwik::PageFiles.new(dir.to_s, '1')

      d = dir+'.attach'
      d.teardown if d.exist?

      return [dir, files]
    end

    def teardown_files(dir)
      dir.teardown
    end

    def test_page_attach
      dir, files = setup_files

      # test_not_exist
      ok_eq(false, files.exist?('t.txt'))

      # test_put
      files.fput('t.txt', 't')
      ok_eq(true, files.exist?('t.txt'))

      # test_load_file
      # FIXME: The path should not be accesible.
#      path = files.path('t.txt')
#      ok_eq('./test/1.files/t.txt', path.to_s)
#      ok_eq('t', path.get)

      # test_get
      ok_eq('t', files.get('t.txt'))

      # test_list
      ok_eq(['t.txt'], files.list)

      # test_each
      files.each {|f|
	ok_eq('t.txt', f)	# Only one file here.
      }

      # test_delete
      files.delete('t.txt')
      ok_eq(false, files.exist?('t.txt'))

      # test_security
#      path = files.path('t/t.txt') # ok
#      assert_raise(Qwik::CanNotAccessParentDirectory) {
#	path = files.path('../t.txt') # bad
#      }

      teardown_files(dir)
    end

    def test_fput
      dir, files = setup_files

      # test_with_japanese_filename
      files.fput("\202\240.txt", 't')
      ok_eq(["\343\201\202.txt"], files.list)
      ok_eq(true, files.exist?("\202\240.txt"))

      # test_with_japanese_filename_twice
      files.fput("\202\240.txt", 't2')	# with same name.
      ok_eq(["1-\343\201\202.txt", "\343\201\202.txt"], files.list)
      ok_eq(true, files.exist?("1-\202\240.txt"))

      files.delete("\202\240.txt")
      ok_eq(false, files.exist?("\202\240.txt"))
      files.delete("1-\202\240.txt")
      ok_eq(false, files.exist?("1-\202\240.txt"))

      teardown_files(dir)
    end

    # test file size total
    def test_total
      dir, files = setup_files

      # save file size 1
      files.fput("size1.txt",'1')
      ok_eq(1,files.total)

      # save file size 10
      files.fput("size10.txt",'1'*10)

      # check if total file size is 1 + 10
      ok_eq(11,files.total)

      # delete file, size 1
      files.delete("size1.txt")
      ok_eq(10,files.total)
    end
  end
end
