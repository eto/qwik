# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  module GetText
    def set_catalog (catalog)
      @gettext_catalog = catalog
    end

    def gettext (text)
      return text if ! defined?(@gettext_catalog) || @gettext_catalog.nil?
      return @gettext_catalog[text] || text
    end

    alias :_ :gettext
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  require 'qwik/catalog-factory'
  $test = true
end

if defined?($test) && $test
  class MockGetText
    include Qwik::GetText

    def test_all(t)
      # $KCODE = 's'

      # test_gettext
      t.assert_equal 'hello', gettext('hello')

      # test_set_catalog
      cf = Qwik::CatalogFactory.new
      cf.load_all_here('catalog-??.rb')
      catalog_ja = cf.get_catalog('ja')
      set_catalog(catalog_ja)

      # test_gettext_ja
      t.assert_equal '‚±‚ñ‚É‚¿‚Í', gettext('hello')
      t.assert_equal '‚±‚ñ‚É‚¿‚Í', _('hello')
    end
  end

  class TestMockGetText < Test::Unit::TestCase
    def test_all
      mock = MockGetText.new
      mock.test_all(self)
    end
  end
end
