#
# Copyright (C) 2003-2006 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'
require 'qwik/util-pathname'

module Qwik
  class CatalogFactory
    def initialize
      @catalogs = {}
    end

    def get_catalog(lang)
      return @catalogs[lang]
    end

    def catalog_re
      return /\Acatalog-(..)\.rb\z/
    end

    def load_all_catalogs(dir)
      # lang is two letters long.
      @catalogs = load_all_catalogs_internal(dir, catalog_re)
    end

    private

    def load_all_catalogs_internal(dir, re)
      catalogs = Hash.new
      path = dir.path
      path = dir.path.realpath if defined?($test) && $test
      path.each_entry {|file|
	if re =~ file.to_s
	  lang = $1
	  fullpath = path + file
	  require fullpath
	  catalogs[lang] = self.class.send('catalog_'+lang)
	end
      }
      catalogs['en'] = Hash.new {|h, k| k }
      return catalogs
    end
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  $test = true
end

if defined?($test) && $test
  class TestCatalogFactory < Test::Unit::TestCase
    def test_all
      cf = Qwik::CatalogFactory.new
      cf.load_all_catalogs('.')
      catalog_ja = cf.get_catalog('ja')
      ok_eq(true, catalog_ja != nil)
    end
  end
end
