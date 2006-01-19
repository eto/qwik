#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '..' unless $LOAD_PATH.include?('..')
require 'qwik/catalog-factory'

module QuickML
  class CatalogFactory < Qwik::CatalogFactory
    def catalog_re
      return /\Acatalog-ml-(..)\.rb\z/
    end
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  # $KCODE = 's'
  $test = true
end

if defined?($test) && $test
  class TestMLCatalogFactory < Test::Unit::TestCase
    def test_all
      cf = QuickML::CatalogFactory.new
      cf.load_all_catalogs('.')
      catalog_ja = cf.get_catalog('ja')
      ok_eq(true, catalog_ja != nil)
    end
  end
end
