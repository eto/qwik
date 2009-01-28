# Copyright (C) 2009 AIST, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

require 'fileutils'

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/util-pathname'
require 'qwik/util-filename'

module Qwik
  class PageRRefs
    include Enumerable

    def initialize(site_dir, key)
      @rref_file = site_dir.path+"#{key}.rrefs"

      # fix me!
      # the mutex works only in a process
      # wiki server process is the process to update rrefs
      # ml-server is not supposed to update rrefs
      @lock = Mutex.new
    end

    def exist?
      FileTest.exists?(@rref_file)
    end

    def get
      if self.exist?
        rrefs = File.open(@rref_file).read
        return rrefs
      else
        return ""
      end
    end

    def delete(key)
      @lock.synchronize {
        rrefs = self.get
        rrefs = rrefs.map {|r| r if r.chomp != key }.to_s
        @rref_file.path.put(rrefs)
      }
    end

    def add(key)
      @lock.synchronize {
        f = File.open(@rref_file,"a")
        f.puts key
        f.close
      }
    end

    def put(keys)
      rrefs = keys.join($/) + $/
      @rref_file.path.put(rrefs)
    end
    
    def each
      return unless self.exist?
      # key might be deleted in the loop
      keys = self.get
      keys.each {|a|
	yield(a.chomp)
      }
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

  class TestPageRRefs < Test::Unit::TestCase
    include TestModulePublic

    def setup_rrefs
      dir = '.test/'.path
      dir.setup
      rrefs = Qwik::PageRRefs.new(dir.to_s, '1')

      return [dir, rrefs]
    end

    def teardown_rrefs(dir)
      dir.teardown
    end

    def test_put
      dir, rrefs = setup_rrefs

      rrefs.put(["2","3"])
      ok_eq(true, rrefs.exist?)

      cont = rrefs.get
      ok_eq("2#{$/}3#{$/}",cont)

      teardown_rrefs(dir)
    end

    def test_add
      dir, rrefs = setup_rrefs
      rrefs.put(["2","3"])

      rrefs.add("4")
      cont = rrefs.get

      ok_eq(true, rrefs.exist?)
      ok_eq("2#{$/}3#{$/}4#{$/}",cont)

      teardown_rrefs(dir)
    end

    def test_delete
      dir, rrefs = setup_rrefs
      rrefs.put(["2","3","4"])
      rrefs.delete("3")

      cont = rrefs.get
      ok_eq(true, rrefs.exist?)
      ok_eq("2#{$/}4#{$/}",cont)

      teardown_rrefs(dir)
    end

    def test_each
      dir, rrefs = setup_rrefs
      keys = ["2","3","4"]
      rrefs.put(keys)

     
      i = 0
      rrefs.each {|key|
        ok_eq(keys[i],key)
	i+=1
      }
    end

    def test_each_empty
      dir, rrefs = setup_rrefs

      cont = []
      rrefs.each {|key|
        cont << key
      }
      ok_eq([],cont)
    end
  end
end
