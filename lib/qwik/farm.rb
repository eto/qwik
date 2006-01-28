#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '..' unless $LOAD_PATH.include?('..')
require 'qwik/site'
require 'qwik/util-pathname'

# $update_group_files = true
$update_group_files = false

module Qwik
  # Bundle many sites to one object.
  class Farm
    def initialize(config, memory)
      @config = config
      @memory = memory
      @logger = @memory[:logger]
      @data_path = @config.sites_dir.path
      @grave_path = @config.grave_dir.path
      @sites = {}
      if $update_group_files
	$update_group_files = false
	update_group_files
      end
    end

    def update_group_files
      each {|sitename|
	site = get_site(sitename)
	site.member.update_group_files
      }
    end

    def get_site(sitename)
      sitepath = @data_path+sitename

      # FIXME: Should we check the directory everytime?
      if ! sitepath.directory?	# At the first, check the directory.
	@sites.delete(sitename) if @sites[sitename]	# Delete from the hash.
	return nil	# No such site.
      end

      # Now, I am sure that we have the directory for the site.
      # Create a new site object and return it.
      return @sites[sitename] ||= Site.new(@config, @memory, sitename)
    end

    def get_top_site
      return get_site(@config.default_sitename)
    end

    def exist?(sitename)
      return self.get_site(sitename) != nil
    end

    def each
      check_all_sites
      @sites.keys.sort.each {|sitename|
	yield(sitename)
      }
    end

    def close_all
      self.each {|sitename|
	site = self.get_site(sitename)
	site.close if site
      }
    end

    def make_site(sitename)
      sitepath = @data_path+sitename
      raise 'site already exist' if sitepath.exist?	# Check the path first.
      sitepath.mkdir
      return nil
    end

    def sweep
      @logger.log(WEBrick::Log::INFO, 'start sweep') unless $test
      inactive_sites = check_inactive_sites
      buried = []
      inactive_sites.each {|sitename|
	@logger.log(WEBrick::Log::INFO, 'sweep '+sitename) unless $test
	buried << bury(sitename)
      }
      return buried
    end

    private

    def check_all_sites
      # At the first, check obsolete sites.
      @sites.keys.sort.each {|sitename|
	dummy = get_site(sitename)
      }

      # Then, check the direcotry entries.
      @data_path.each_entry {|entry|
	next if ! (@data_path+entry).directory?	# is not a directory?
	sitename = entry.to_s
	next if sitename[0] == ?.	# begin with dot?
	next if sitename == 'CVS'
	dummy = get_site(sitename)
      }
      return nil
    end

    def check_inactive_sites
      inactive_sites = []
      self.each {|sitename|
	# Do not bury default site.
	next if sitename == @config.default_sitename
	site = get_site(sitename)
	inactive_sites << sitename if site && site.inactive?
      }
      return inactive_sites
    end

    def bury(sitename)
      site = get_site(sitename)
      sitepath = site.path
      dirtime = sitepath.mtime.to_i
      @grave_path.check_directory
      while true
	gravesitepath = @grave_path+(dirtime.to_s+'_'+sitename)
	if ! gravesitepath.exist?
	  sitepath.rename(gravesitepath)
	  break
	end
	dirtime += 1
      end
      return gravesitepath
    end

  end
end

if $0 == __FILE__
  require 'qwik/test-module-session'
  $test = true
end

if defined?($test) && $test
  class TestFarm < Test::Unit::TestCase
    include TestSession

    def test_make_site
      farm = @memory.farm
      farm.close_all
      @dir.teardown
      @dir.rmtree if @dir.directory?
      @dir.rmdir  if @dir.directory?

      # test_exist?
      ok_eq(false, farm.exist?('test'))
      ok_eq(nil, farm.get_site('test'))

      # test_make_site
      farm.make_site('test')
      ok_eq(true, farm.exist?('test'))
      site = farm.get_site('test')
      ok_eq('test', site.sitename)

      # test_raise
      assert_raise(RuntimeError) {
	# Creating a site with same name cause error.
	farm.make_site('test')
      }
    end

    def test_all
      farm = @memory.farm

      # test_top_site
      site = farm.get_top_site
      ok_eq(@config.default_sitename, site.sitename)

      # test_each
      farm.each {|s|
	assert_instance_of(String, s)
      }
    end

    def test_sweep
      farm = @memory.farm

      site = farm.get_site('test')
      page = site['_SiteConfig']
      page.put_with_time(':ml_life_time:0', 0)	# Die soon.

      # test_inactive?
      ok_eq(true, site.inactive?)

      # test_sweep
      buried = farm.sweep
      site = farm.get_site('test')
      ok_eq(nil, site)

      # Clean up the grave dir.
      buried.each {|gravesitepath|
	gravesitepath.teardown
	gravesitepath.rmtree
      }
    end
  end
end