# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Site
    def sitelog
      @sitelog = SiteLog.new(@config, self) unless defined? @sitelog
      @sitelog
    end

    def log(time, user, cmd, pagename)
      sitelog.add(time, user, cmd, pagename)
    end
  end

  class SiteLog
    def initialize(config, site)
      @config = config
      @site = site
    end

    def add(t, user, cmd, pagename)
      dbkey('_SiteLog'    ).add(t, user, cmd, pagename)
      dbkey('_SiteChanged').add(t, user, cmd, pagename)
    end

    def list
      dbkey('_SiteLog').hash.sort
    end

    private

    def dbkey(key)
      page = @site[key]
      page = @site.create(key) if page.nil?
      page.wikidb
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-module-session'
  $test = true
end

if defined?($test) && $test
  class TestSiteLog < Test::Unit::TestCase
    include TestSession

    def test_sitelog_unit
      sitelog = @site.sitelog
      sitelog.add(0, 'user@e.com', 'save', '1')
      ok_eq(",0,user@e.com,save,1\n", @site['_SiteLog'].load)
      sitelog.add(0, nil, 'save', '1')
      ok_eq(",0,user@e.com,save,1\n,0,,save,1\n", @site['_SiteLog'].load)

      # test_sitelog_session
      # not yet
    end
  end
end
