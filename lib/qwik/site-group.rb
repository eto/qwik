# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/group-db'
require 'qwik/group-config'

module Qwik
  class Site
    ML_LIFE_TIME_ALLOWANCE = 60*60*24*31*2 # 2 months

    def forward?
      return @group_config.forward?
    end

    def permanent?
      return @group_config.permanent?
    end

    def inactive?(now = Time.now)
      return false if @group_config.forward? || @group_config.permanent?

      log = @memory[:bury_log]

      last_article_time = @pages.last_article_time
      if last_article_time.nil?		# No file here.
	unless $test
	  log.info("site #{@sitename}: last_article_time is nil") if log
	end
	return true
      end

      ml_life_time = self.siteconfig['ml_life_time'].to_i
      ml_life_time += ML_LIFE_TIME_ALLOWANCE

      result = last_article_time.to_i + ml_life_time.to_i <= now.to_i
      if result
	ymdhms = last_article_time.strftime("%Y-%m-%d %H:%M:%S") 
	unless $test
	  log.info("site #{@sitename}: last_article_time is #{ymdhms}") if log
	end
      end
      return result
    end

    def unconfirmed?
      member.list.empty? &&
	@pages.exist?('_GroupWaitingMembers') &&
        @pages.exist?('_GroupWaitingMessage')
    end

    private

    def init_group_config
      # in group-db.rb
      db = QuickML::GroupDB.new(@config.sites_dir.to_s, @sitename)
      db.set_site(self)
      # in group-config.rb
      @group_config = QuickML::GroupConfig.new(db)
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-module-session'
  require 'qwik/farm'
  $test = true
end

if defined?($test) && $test
  class TestSiteML < Test::Unit::TestCase
    include TestSession

    def check_a_site(site)
      # At the first, there is no file here.
      ok_eq(true, site.inactive?(Time.at(0)))

      # Create a new page with time 0.
      page = site.create_new
      page.put_with_time('a', 0)
      ok_eq(false, site.inactive?(Time.at(0)))

      # Change the life time to 0.
      page = site['_SiteConfig']
      page.put_with_time(':ml_life_time:0', 0)	# Die soon.
      ok_eq(true, site.inactive?(Time.at(0 + Qwik::Site::ML_LIFE_TIME_ALLOWANCE)))

      # Set GroupConfig to forward mode.
      page = site.create('_GroupConfig')
      page.put_with_time(':forward:true', 0)	# forward mode.
      ok_eq(false, site.inactive?(Time.at(0)))
    end

    def test_all
      # test_inactive
      check_a_site(@site)

      # test_inactive_top_site
      check_a_site(@memory.farm.get_top_site)
    end
  end
end
