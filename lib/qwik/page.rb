# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/page-get'
require 'qwik/page-put'
require 'qwik/page-wikidb'

module Qwik
  class Page
    def initialize(config, pages, key)
      @pages = pages
      @key = key.to_s
      @db = @pages.db
      @db.create(@key)

#      init_generate
      
      # FIXME
      @files = nil
      @rrefs = nil
      @cache = {}
    end
    attr_reader :key

    attr_accessor :files
    attr_accessor :rrefs
    attr_reader :cache

    def inspect
      return "#<Page:"+@key+">"
    end

    def url
      return @key+'.html'
    end

    def <=>(other)
      return self.key <=> other.key
    end
  end
end

if $0 == __FILE__
  require 'qwik/farm'
  require 'qwik/server-memory'
  require 'qwik/test-module-session'
  $test = true
end

if defined?($test) && $test
  class TestPage < Test::Unit::TestCase
    include TestSession

    def test_all
      pages = @site.get_pages
      page = pages.create_new

      # test_url
      ok_eq('1.html', page.url)

      # test_key
      ok_eq('1', page.key)
    end
  end
end
