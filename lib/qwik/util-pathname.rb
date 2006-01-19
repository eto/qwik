#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

require 'pathname'

$LOAD_PATH << '..' unless $LOAD_PATH.include?('..')

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

  def add(str)
    return self.open('ab') {|f| f.print str }
  end

  def get_first
    return self.open('rb') {|f| f.gets }
  end

  def check_directory
    if self.exist?
      if ! self.directory?
	raise "#{self.to_s} is not directory. failed."
      end
      return	# The directory is already exist.
    end
    self.mkdir
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
	raise self.to_s+' is not directory. failed.'
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
      assert_instance_of(Pathname, 't'.path)
      ok_eq('t', 't'.path.to_s)

      # test_path_path
      assert_instance_of(Pathname, 't'.path.path)

      # test_to_win_dir
      ok_eq('c:/t', '/cygdrive/c/t'.path.to_win_dir)

      # test_extname
      ok_eq('', 't'.path.extname)
      ok_eq('.txt', 't.txt'.path.extname)
      ok_eq('.gz', 't.tar.gz'.path.extname)

      # test_ext
      ok_eq('txt', 't.txt'.path.ext)
      ok_eq('gz', 't.tar.gz'.path.ext)

      # test_put
      'test.txt'.path.put('t')

      # test_read
      eq('t', 'test.txt'.path.read)

      # test_add
      'test.txt'.path.add('t')
      eq('tt', 'test.txt'.path.read)

      # test_get_first
      'test.txt'.path.put("s\nt\n")
      eq("s\nt\n", 'test.txt'.path.read)
      eq("s\n", 'test.txt'.path.get_first)

      # teardown
      eq(true, 'test.txt'.path.exist?)
      'test.txt'.path.unlink
      eq(false, 'test.txt'.path.exist?)
    end

    def test_check_directory
      return if $0 != __FILE__		# Only for unit test.

      dir = 'test'.path
      dir.erase_all if dir.exist?
      dir.rmtree if dir.exist?
      dir.rmdir if dir.exist?
      ok_eq(false, dir.exist?)

      dir.check_directory
      ok_eq(true, dir.exist?)

      dir.check_directory		# Check again cause no error.
      ok_eq(true, dir.exist?)

      dir.erase_all
      dir.rmdir
      ok_eq(false, dir.exist?)
    end

    def test_check_directory_raise
      return if $0 != __FILE__		# Only for unit test.

      # Make a plain text file.
      file = 't.txt'.path
      file.put('t')

      # Try to create a directory with the same name cause exception.
      assert_raise(RuntimeError) {
	file.check_directory
      }
      file.unlink
    end

    def test_erase_all
      dir = 'test'.path
      dir.check_directory		# mkdir

      file = 'test/t.txt'.path		# Create a dummy file.
      file.put('t')
      ok_eq(true, file.exist?)

      dir.erase_all
      ok_eq(false, file.exist?)		# The file is deleted.
      ok_eq(true, dir.exist?)		# But the directory is remained here.
    end

    def test_check_pathname
      dir = 'test'.path
      dir.rmtree if dir.exist?
      dir.rmdir  if dir.exist?

      dir.mkdir
      ok_eq(true, dir.exist?)

      file = dir+'t'
      file.put('test')
      ok_eq(true, file.exist?)
      dir.rmtree
      ok_eq(false, dir.exist?)
    end

    def test_chdir     
      pwd = Dir.pwd
      Dir.chdir('/') {
	assert_not_equal(pwd, Dir.pwd)
      }
      ok_eq(pwd, Dir.pwd)
    end
  end
end
