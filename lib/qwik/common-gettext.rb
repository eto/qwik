# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/catalog-factory'
require 'qwik/gettext'

module Qwik
  class Action
    include GetText

    def init_gettext
      init_catalog(@memory.catalog, @req.accept_language)
    end

    def init_catalog(catalog_factory, langs)
      langs.each {|lang|
	catalog = catalog_factory.get_catalog(lang)
        if catalog
          set_catalog(catalog)	# GetText::set_catalog
          return
        end
      }
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestCommonGettext < Test::Unit::TestCase
    include TestSession

    def test_init_catalog
      res = session

      accept_languages = ['en']
      @action.init_catalog(@memory.catalog, accept_languages)
      ok_eq('hello', @action._('hello'))

      accept_languages = ['ja']
      @action.init_catalog(@memory.catalog, accept_languages)
      ok_eq('‚±‚ñ‚É‚¿‚Í', @action._('hello'))
    end
  end
end
