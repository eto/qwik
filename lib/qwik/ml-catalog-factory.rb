# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/catalog-factory'

module QuickML
  class CatalogFactory < Qwik::CatalogFactory
  end
end

if $0 == __FILE__
  require 'test/unit'
  $test = true
end

if defined?($test) && $test
  class TestMLCatalogFactory < Test::Unit::TestCase
    def test_all
      cf = QuickML::CatalogFactory.new
      cf.load_all_here('catalog-ml-??.rb')
      catalog_ja = cf.get_catalog('ja')
      assert_equal true, catalog_ja != nil
    end
  end
end
