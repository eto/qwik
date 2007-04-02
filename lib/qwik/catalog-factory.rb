# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/util-pathname'

module Qwik
  class CatalogFactory
    LIBDIR = File.dirname(__FILE__)

    def initialize
      @catalogs = {}
    end

    def get_catalog(lang)
      return @catalogs[lang]
    end

    def load_all_here(glob)
      # lang is two letters length.
      @catalogs = load_all(LIBDIR, glob)
    end

    private

    def load_all(dir, glob)
      files = get_files(dir, glob) 
      catalogs = load_all_files(files)
      return catalogs
    end

    def get_files(dir, glob)
      files = []
      path = dir.path
      path = dir.path.realpath if defined?($test) && $test
      return list if ! path.exist?
      Pathname.glob("#{path}/#{glob}") {|file|
	files << file.to_s
      }
      return files
    end

    def load_all_files(files)
      catalogs = {}
      files.each {|file|
	if /(..)\.rb\z/ =~ file
	  lang = $1
	  require file
	  catalogs[lang] = self.class.send("catalog_#{lang}")
	end
      }
      catalogs['en'] = Hash.new {|h, k| k }
      return catalogs
    end
  end
end

if $0 == __FILE__
  require 'test/unit'
  require 'qwik/qp'
  $test = true
end

if defined?($test) && $test
  require 'qwik/test-module-public'

  class TestCatalogFactory < Test::Unit::TestCase
    include TestModulePublic

    def test_all
      cf = Qwik::CatalogFactory.new

      # test_get_files
      t_make_public(Qwik::CatalogFactory, :get_files)
      files = cf.get_files('.', 'catalog-??.rb')
      assert 0 < files.length

      # test_load_all_files
      t_make_public(Qwik::CatalogFactory, :load_all_files)
      catalogs = cf.load_all_files(['catalog-ja.rb'])
      assert 0 < catalogs.length

      # test_load_all_here
      cf.load_all_here('catalog-??.rb')

      catalog_ja = cf.get_catalog('ja')
      assert_equal true, catalog_ja != nil
    end
  end
end
