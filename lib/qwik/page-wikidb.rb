#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '..' unless $LOAD_PATH.include?('..')

class Array
  def to_hash
    hash = {}
    self.each {|k, v| hash[k] = v }
    return hash
  end
end

module Qwik
  class Page
    def wikidb
      @wikidb = WikiDB.new(self) unless defined?(@wikidb)
      return @wikidb
    end
  end

  class WikiDB
    include Enumerable

    def initialize(page)
      @page = page
      @str = nil
      check_new
    end

    def array
      check_new
      return @array.dup		# dup prevent from destructive method
    end

    def hash
      check_new
      return @hash.dup		# dup prevent from destructive method
    end

    def rev_hash
      check_new
      return @rev_hash.dup	# dup prevent from destructive method
    end

    def [](key)
      v = hash[key]
      return nil if v.nil?
      return v.dup		# dup prevent from destructive method
    end

    def exist?(key)
      return self[key] != nil
    end

    def each
      array.each {|k, v|
	k = k.dup	# unfreeze
	v = v.dup	# dup prevent from destructive method
	yield(k, v)
      }
    end

    def add(k, *ar)
      ar = ar.flatten
      @page.add(WikiDB.encode_line(k, ar)+"\n")
    end

    def remove(key)
      return false unless exist?(key)	# Return if the key is not exist.
      str = @page.load
      newstr, status = WikiDB.generate_without(str, key)
    # @page.store(newstr, str.md5hex)	# FIXME: Check collision.
      @page.store(newstr)	# FIXME: Store should check the collision.
      return status
    end

    private

    def check_new
      str = @page.load
      return if str == @str	# Do nothing.
      @str = str

      @array = WikiDB.parse(@str)
      @hash = @array.to_hash
      @rev_hash = @hash.invert
      return nil
    end

    SIGNATURE = ['|', ',', ':']

    def self.parse(str)
      array = []
      str.each {|line|
	firstchar = line[0, 1]
	next unless SIGNATURE.include?(firstchar)
	ar = line.chomp.split(firstchar)
	ar.shift		# Drop the first column.
	k = ar.shift
	v = (firstchar == ':') ? ar.join(':') : ar
	v.freeze
	array << [k, v]
      }
      return array
    end

    def self.generate_without(str, key)
      status = false
      newar = []
      str.each {|line|
	firstchar = line[0, 1]
	if SIGNATURE.include?(firstchar)
	  ar = line.chomp.split(firstchar)
	  ar.shift		# Drop the first column.
	  k = ar.shift
	  if k && k == key	# Do not add the line with the key.
	    status = true	# ok.
	    next		# Delete the line.
	  end
	end
	newar << line
      }
      return newar.join, status
    end

    def self.encode_line(k, *ar)
      ar = ar.flatten
      nar = []
      nar << ''		# Empty entry.
      nar << k		# The key.
      nar << ar if ar && ! ar.empty?
      str = nar.flatten.join(',')
      return str
    end

  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestWikiDB < Test::Unit::TestCase
    include TestSession

    def test_class_method
      c = Qwik::WikiDB

      # test_encode_line
      ok_eq(',k,v', c.encode_line('k', 'v'))
      ok_eq(',k,v1,v2', c.encode_line('k', ['v1', 'v2']))
      ok_eq(',k,v1,v2', c.encode_line('k', 'v1', 'v2'))
      ok_eq(',k,,v2', c.encode_line('k', nil, 'v2'))
    end

    def test_all
      page = @site.create_new
      wdb  = Qwik::WikiDB.new(page)

      # test_exist?
      ok_eq(false, wdb.exist?('k'))
      wdb.add('k', 'v')
      ok_eq(",k,v\n", page.load)

      ok_eq(true,  wdb.exist?('k'))
      ok_eq(['v'], wdb['k'])
      ok_eq('v', wdb['k'][0])
      ok_eq(false, wdb['k'][0].frozen?)

      # test_hash
      ok_eq({'k'=>['v']}, wdb.hash)
      wdb.add('k', 'v2')
      ok_eq(['v2'], wdb['k']) # can get second value
      
      # test_remove
      ok_eq(true,  wdb.remove('k')) # remove
      ok_eq(false, wdb.remove('k')) # fail to remove

      # test_add
      ok_eq(false, wdb.exist?('k'))
      wdb.add('k', 'v1', 'v2')
      ok_eq(true,  wdb.exist?('k'))
      ok_eq(['v1', 'v2'], wdb['k'])
      ok_eq({'k'=>['v1', 'v2']}, wdb.hash)
      ok_eq(true,  wdb.remove('k')) # remove
      ok_eq(false, wdb.remove('k')) # fail to remove

      wdb.add('a', 'b')
      wdb.add('c', 'd')
      ok_eq({'a'=>['b'], 'c'=>['d']}, wdb.hash)

      # test_each
      wdb.each {|k, v|
	ok_eq(false, k.frozen?)
	assert_instance_of(Array, v)
      }

      ok_eq([['a', ['b']], ['c', ['d']]], wdb.array)
      wdb.array.each {|name, args|
	args = args.dup
	t = args.shift
      }
      ok_eq([['a', ['b']], ['c', ['d']]], wdb.array)

      # test_nil
      page = @site.create_new
      wdb = Qwik::WikiDB.new(page)
      ok_eq(false, wdb.exist?('k'))
      wdb.add('k', nil, 'v2')
      ok_eq(",k,,v2\n",  page.load)
      ok_eq(['', 'v2'], wdb['k'])
    end
  end
end
