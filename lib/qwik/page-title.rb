# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'

module Qwik
  class PageTitle
    KEY = '_PageTitle'

    def initialize(config, site)
      @db = nil

      page = site[KEY]
      return if page.nil?

      @db = page.wikidb
    end

    def hash
      return if @db.nil?
      return @db.hash
    end

    def rev_hash
      return if @db.nil?
      return @db.rev_hash
    end

  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  $test = true
end

if defined?($test) && $test
  class TestPageTitle < Test::Unit::TestCase
    def test_dummy
    end
  end
end
