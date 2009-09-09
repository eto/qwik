# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Site
    def siteconfig
      # @siteconfig = SiteConfig.new(@config, self) unless defined? @siteconfig
      #return @siteconfig
      return SiteConfig.new(@config, self)
    end

    def is_open?
      return (siteconfig['open'] == 'true')
    end

    def is_blessed?
      file = @path + ",blessed"
      return file.exist?
    end
  end

  class SiteConfig
    def initialize(config, site)
      @config = config
      @site = site

      @default = default_config

      page = get_page

      @db = page.wikidb
    end

    def get_page
      #page = @site.get_superpage('SiteConfig')
      page = @site['_SiteConfig']
      return page if page
      return @site.create('_SiteConfig')
    end

    def [](k)
      v = @db[k]
      return @default[k] if v.nil?
      return v
    end

    private

    # FIXME: Read default site config from super/_SiteConfig.txt
    def default_config
      {
	'open'		=> 'false',
	'theme'		=> 'qwikgreen',
	'sitename'	=> '',
	'aid'		=> 'q02-22',	# amazon associate id
	'ml_life_time'	=> (60 * 60 * 24 * 31).to_s,	# 1 month
	'reportmail'	=> 'hourly',
	'reportfrom'	=> '',
	'titlelink'	=> 'false',
	'redirect'	=> 'false',
	'siteurl'	=> '',
	'siteml'	=> '',
	'max_file_size'	=> (10 * 1024 * 1024).to_s,	# 10MB
	'page_title_first'=> 'true',
      }
    end

=begin
    # Read default site config from super/_SiteConfig.txt
    def read_default_config
      dir = @config.super_dir.path
      str = (dir + '_SiteConfig.txt').read
      array = WikiDB.parse(str)
      hash = array.to_hash
      return hash
    end
=end
  end
end

if $0 == __FILE__
  require 'qwik/test-module-session'
  require 'qwik/site'
  require 'qwik/farm'
  $test = true
end

if defined?($test) && $test
  class TestSiteConfig < Test::Unit::TestCase
    include TestSession

    def test_is_open?
      eq false, @site.is_open?
      page = @site.create '_SiteConfig'
      page.store ':open:true'
      eq true, @site.is_open?
      page.store ':open:false'
      eq false, @site.is_open?
      @site.delete '_SiteConfig'
      eq false, @site.is_open?
    end

    def test_siteconfig
      page = @site.create '_SiteConfig'

      # test_theme
      assert_instance_of String, @site.siteconfig['theme']
      page.store(':theme:qwik')

      # test_sitename
#     eq 'example.com', @site.siteconfig['sitename']
#     eq 'example.com/test', @site.title
      page.store ':sitename:TestSite'
      eq 'TestSite', @site.siteconfig['sitename']
      eq 'TestSite', @site.title

      # test_title
      page = @site.create 'TestPage'
      eq 'TestPage', page.get_title
#     eq 'TestPage - TestSite', @site.title('TestPage')
      eq 'TestSite', @site.title

      page = @site.create '1'
      eq '1', page.get_title
#      eq '1 - TestSite', @site.title('1')
      page.store('* TestTitle')
#      eq 'TestTitle - TestSite', @site.title('1')

      # test_bless
      is false, @site.is_blessed?
      file = @site.path + ",blessed"
      file.write("")
      is true, @site.is_blessed?
    end

    def test_siteconfig_class
      siteconfig = @site.siteconfig

      assert_equal "#<Page:_SiteConfig>", siteconfig.get_page.inspect

      assert_equal 'false', siteconfig['open']

      assert_equal '10485760', siteconfig['max_file_size']
    end
  end
end
