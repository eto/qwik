#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Site
    def siteconfig
      @siteconfig = SiteConfig.new(@config, self) unless defined? @siteconfig
      return @siteconfig
    end

    def is_open?
      return (siteconfig['open'] == 'true')
    end
  end

  class SiteConfig
    DefaultConfig = {
      # Site access control.
      :open		=> false,

      # Site URL setting.
      :siteurl		=> '',
      :siteml		=> '',

      # Site look and feel.
      :theme		=> 'qwikgreen',
      :sitename		=> '',
      :redirect		=> 'false',
      :titlelink	=> 'false',
      :aid		=> 'q02-22',		# Amazon associate id

      # Mailing list releation.
      :reportmail		=> 'daily',
      :reportfrom		=> '',
      :ml_life_time		=> (60 * 60 * 24 * 31).to_s,	# 1 month

=begin
      # Config for each group.
      :auto_unsubscribe_count	=> 5,
      :max_mail_length		=> 100 * 1024,	# 100KB
      :max_ml_mail_length	=> 100 * 1024,	# 100KB
      :max_members		=> 100,
      :ml_alert_time		=> 86400 * 24,
      :ml_life_time		=> 86400 * 31,
=end
    }

    def initialize(config, site)
      @config = config
      @site = site

      @site_config = {}
      @config.update(DefaultConfig)

      @default = default_config

      page = get_page

      @db = page.wikidb
    end

    def get_page
      page = @site.get_superpage('SiteConfig')
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
	'aid'		=> 'q02-22', # amazon associate id
	'ml_life_time'	=> (60 * 60 * 24 * 31).to_s,	# 1 month
	'reportmail'	=> 'hourly',
	'reportfrom'	=> '',
	'titlelink'	=> 'false',
	'redirect'	=> 'false',
	'siteurl'	=> '',
	'siteml'	=> '',
      }
    end
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
      ok_eq(false, @site.is_open?)
      page = @site.create('_SiteConfig')
      page.store(':open:true')
      ok_eq(true, @site.is_open?)
      page.store(':open:false')
      ok_eq(false, @site.is_open?)
      @site.delete('_SiteConfig')
      ok_eq(false, @site.is_open?)
    end

    def test_siteconfig
      page = @site.create('_SiteConfig')

      # test_theme
      assert_instance_of(String, @site.siteconfig['theme'])
      page.store(':theme:qwik')

      # test_sitename
#      ok_eq('example.com', @site.siteconfig['sitename'])
#      ok_eq('example.com/test', @site.title)
      page.store(':sitename:TestSite')
      ok_eq('TestSite', @site.siteconfig['sitename'])
      ok_eq('TestSite', @site.title)

      # test_title
      page = @site.create('TestPage')
      ok_eq('TestPage', page.get_title)
#     ok_eq('TestPage - TestSite', @site.title('TestPage'))
      ok_eq('TestSite', @site.title)

      page = @site.create('1')
      ok_eq('1', page.get_title)
#      ok_eq('1 - TestSite', @site.title('1'))
      page.store('* TestTitle')
#      ok_eq('TestTitle - TestSite', @site.title('1'))
    end
  end
end
