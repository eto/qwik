# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

require 'pathname'

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

class String
  def path
    return Pathname.new(self)
  end
end

class Pathname
  def path
    return self
  end

  # /cygdrive/c -> c:
  def to_win_dir
    return self.to_s.sub(%r!\A/cygdrive/(\w)!) {|a| $1+':' }
  end

  def ext
    return (self.extname.to_s).sub(/\A\./, '')
  end

  def write(str)
    return self.open('wb') {|f| f.print str }
  end
  alias put write

  def append(str)
    return self.open('ab') {|f| f.print str }
  end
  alias add append

  def get_first
    return self.open('rb') {|f| f.gets }
  end

  def check_directory
    if self.exist?
      if ! self.directory?
	raise "#{self} is not directory. failed."
      end
      return	# The directory is already exist.
    end
    self.mkpath
  end

  def erase_all
    self.each_entry {|file|
      base = file.to_s
      next if base == '.' || base == '..'
      f = self + file
      if f.directory?
	f.erase_all
	next
      end
      if f.exist?
	f.unlink
      end
    }
  end

  def remove_directory
    if self.exist?
      if self.directory?
	self.rmtree
	self.rmdir if self.directory?
      else
	raise "#{self} is not directory. failed."
      end
    end
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  require 'qwik/test-module-path'
  $test = true
end

if defined?($test) && $test
  class TestUtilPathname < Test::Unit::TestCase
    def test_all
      # test_string_path
      assert_instance_of Pathname, 't'.path
      assert_equal 't', 't'.path.to_s

      # test_path_path
      assert_instance_of Pathname, 't'.path.path

      # test_to_win_dir
      assert_equal 'c:/t', '/cygdrive/c/t'.path.to_win_dir

      # test_extname
      assert_equal '', 't'.path.extname
      assert_equal '.txt', 't.txt'.path.extname
      assert_equal '.gz', 't.tar.gz'.path.extname

      # test_ext
      assert_equal 'txt', 't.txt'.path.ext
      assert_equal 'gz', 't.tar.gz'.path.ext

      # test_write
      'test.txt'.path.write('t')

      # test_read
      assert_equal 't', 'test.txt'.path.read

      # test_append
      'test.txt'.path.append('t')
      assert_equal 'tt', 'test.txt'.path.read

      # test_get_first
      'test.txt'.path.write("s\nt\n")
      assert_equal "s\nt\n", 'test.txt'.path.read
      assert_equal "s\n", 'test.txt'.path.get_first

      # teardown
      assert_equal true, 'test.txt'.path.exist?
      'test.txt'.path.unlink
      assert_equal false, 'test.txt'.path.exist?
    end

    def test_check_directory
      return if $0 != __FILE__		# Only for unit test.

      dir = 'testdir'.path
      dir.erase_all if dir.exist?
      dir.rmtree if dir.exist?
      dir.rmdir if dir.exist?
      assert_equal false, dir.exist?

      dir.check_directory
      assert_equal true, dir.exist?

      dir.check_directory		# Check again cause no error.
      assert_equal true, dir.exist?

      dir.erase_all
      dir.rmdir
      assert_equal false, dir.exist?
    end

    def test_check_directory_raise
      return if $0 != __FILE__		# Only for unit test.

      # Make a plain text file.
      file = 't.txt'.path
      file.write('t')

      # Try to create a directory with the same name cause exception.
      assert_raise(RuntimeError) {
	file.check_directory
      }
      file.unlink
    end

    def test_erase_all
      dir = 'testdir'.path
      dir.check_directory		# mkdir

      file = 'testdir/t.txt'.path		# Create a dummy file.
      file.write('t')
      assert_equal true, file.exist?

      dir.erase_all
      assert_equal false, file.exist?	# The file is deleted.
      assert_equal true, dir.exist?	# But the directory is remained here.

      dir.rmdir
      assert_equal false, dir.exist?
    end

    def test_check_pathname
      dir = 'testdir'.path
      dir.rmtree if dir.exist?
      dir.rmdir  if dir.exist?

      dir.mkdir
      assert_equal true, dir.exist?

      file = dir+'t'
      file.write('test string')
      assert_equal true, file.exist?
      dir.rmtree
      assert_equal false, dir.exist?
    end

    def test_chdir     
      pwd = Dir.pwd
      Dir.chdir('/') {
	assert_not_equal(pwd, Dir.pwd)
      }
      assert_equal pwd, Dir.pwd
    end
  end
end
