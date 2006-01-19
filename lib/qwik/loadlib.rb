#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '..' unless $LOAD_PATH.include?('..')

module Qwik
  class LoadLibrary
    def glob(dir, glob)
      ar = list_files(dir, glob)
      add_load_path(dir)
      require_files(ar)
    end

    private

    def list_files(dir, glob)
      return Dir.glob(dir+'/'+glob).map {|f|
	f.sub(dir+'/', '')
      }
    end

    def add_load_path(dir)
      dir = '../../lib' if defined?($test) && $test
      $LOAD_PATH << dir unless $LOAD_PATH.include?(dir)
    end

    def require_files(ar)
      before = $".dup
      ar.each {|f|
	require f
      }
      after = $".dup
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

      config = Qwik::Config.new
      loadlib = Qwik::LoadLibrary.new
      dir = config.lib_dir
      org_path = $LOAD_PATH.dup
      org_libs = $".dup

      Qwik::LoadLibrary.instance_eval {
	public :list_files
      }

      # test list_files
      glob = 'qwik/act-*.rb'
      files = loadlib.list_files(dir, glob)
      ok_eq(true, 0 < files.length)
      files.each {|f|
	assert_match(/\Aqwik\/act-[-a-z0-9]+\.rb\z/, f)
      }

      loadlib.glob(dir, glob) # LOAD

      # LOAD_PATH is not changed.
      diff = $LOAD_PATH.length - org_path.length
      #qp $LOAD_PATH.length, org_path.length
      ok_eq(false, 0 < diff)

      diff = $".length - org_libs.length
      #qp $".length, org_libs.length
      ok_eq(true, 0 < diff)
    end
  end
end
