# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class LoadLibrary
    LIBDIR = File.dirname(__FILE__)
    ROOTLIBDIR = File.expand_path(LIBDIR+'/../')

    def self.load_libs_here(glob)
      dir = ROOTLIBDIR
      ar = list_files(dir, glob)
      add_load_path(dir)
      require_files(ar)
    end

    private

    def self.list_files(dir, glob)
      return Dir.glob("#{dir}/#{glob}").map {|f|
	f.sub("#{dir}/", '')
      }
    end

    def self.add_load_path(dir)
      dir = '..' if defined?($test) && $test
      $LOAD_PATH << dir unless $LOAD_PATH.include?(dir)
    end

    def self.require_files(ar)
      #before = $".dup
      ar.each {|f|
	require f
      }
      #after = $".dup
      #pp 'load success', after-before if before != after
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestLoadLib < Test::Unit::TestCase
    def test_all
      return if $0 != __FILE__	# just only for unit test.

      c = Qwik::LoadLibrary
      org_path = $LOAD_PATH.dup
      org_libs = $".dup

      # test list_files
      dir = Qwik::LoadLibrary::ROOTLIBDIR
      glob = 'qwik/act-*.rb'
      files = c.list_files(dir, glob)
      ok_eq(true, 0 < files.length)
      files.each {|f|
	assert_match(/\Aqwik\/act-[-a-z0-9]+\.rb\z/, f)
      }

      c.load_libs_here(glob)		# LOAD

      # LOAD_PATH is not changed.
      diff = $LOAD_PATH.length - org_path.length
      #p $LOAD_PATH.length, org_path.length
      #pp $LOAD_PATH, org_path
      ok_eq(false, 0 < diff)

      diff = $".length - org_libs.length
      #p $".length, org_libs.length
      ok_eq(true, 0 < diff)
    end
  end
end
