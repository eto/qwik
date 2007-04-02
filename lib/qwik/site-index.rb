# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Site
    def index
      return @pages.index
    end

    def isearch(query)
      index = self.index
      return if index.nil?
      return index.search(query)
    end

    def isearch_parse_query(query)
      return query.strip.split
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestSiteIndex < Test::Unit::TestCase
    include TestSession

    def test_all
      res = session

      page = @site.create_new
      page.store('This is a test.')
      page = @site.create_new
      page.store('This is a test, too.')

#      ok_eq(['1', '2'], @site.isearch('test'))
#      ok_eq(['2'], @site.isearch('too'))
#      ok_eq([], @site.isearch('nosuch'))
    end
  end
end
