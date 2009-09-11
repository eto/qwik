# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

require 'time'
require 'fileutils'

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/server-memory'
require 'qwik/pages'
require 'qwik/site-config'
require 'qwik/site-log'
require 'qwik/site-member'
require 'qwik/site-url'
require 'qwik/site-pages'
require 'qwik/site-group'
require 'qwik/site-files'
#require 'qwik/site-rrefs'
#require 'qwik/site-search'

module Qwik
  class Site
    include Enumerable

    CACHE_DIR = '.cache'

    def initialize(config, memory, sitename)
      @config = config
      @memory = memory

      @sitename = sitename
      @path = "#{@config.sites_dir}/#{sitename}".path
      @pages = Pages.new(@config, @path)

      @cache_path = @path + CACHE_DIR
      @cache_path.check_directory

      @cache = {}

      init_group_config		# site-group.rb

#      init_site_search
    end
    attr_reader :sitename
    attr_reader :path
    attr_reader :cache_path
    attr_reader :cache

    def inspect
      return "#<Site:#{@sitename}>"
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-module-session'
  require 'qwik/farm'
  $test = true
end

if defined?($test) && $test
  class TestSite < Test::Unit::TestCase
    include TestSession

    def test_all
      sitename = 'site_test'
      pa = @config.sites_dir.path + sitename
      pa.rmtree if pa.exist?
      pa.mkdir
      assert_equal false, (pa+sitename).exist?
      site = Qwik::Site.new(@config, @memory, sitename)
      assert_equal false, (pa+sitename).exist?
      pa.rmtree
    end
  end
end
