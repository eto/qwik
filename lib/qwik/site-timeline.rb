# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Site
    def last_modified
      return self.map {|page|
	page.mtime
      }.max
    end

    # called from act-chronology
    def timeline
      @timeline = SiteTimeLine.new(self) unless defined? @timeline
      return @timeline
    end
  end

  class SiteTimeLine
    def initialize(site)
      @site = site
      @times = nil
      @days = nil
      @site_min = nil
      @site_max = nil
      @page_min = nil
      @page_max = nil
      @pages_history = nil
      @site_duration = nil
      @site_last_modified = nil
    end
    attr_reader :times, :days
    attr_reader :site_min, :site_max, :page_min, :page_max
    attr_reader :pages_history, :site_duration

    def calc_history
      if_sites_update? {
	@times, @days, @page_min, @page_max, @site_min, @site_max,
	@pages_history, @site_duration = calc_history_internal(@site)
      }
    end

    def if_sites_update?
      # Check last update from pages
      last_modified = @site.last_modified
      return if last_modified.nil?	# No page.
      if @site_last_modified.nil? || @site_last_modified < last_modified
	yield
      end
      @site_last_modified = last_modified
    end

    def calc_history_internal(site)
      keys = site.map {|page| page.key }
      return nil if keys.empty?

      times = Hash.new {|h, k| h[k] = []}
      days = Hash.new {|h, k| h[k] = []}
      site_min = nil	# FIXME: site_min should be cached.
      site_max = nil
      page_min = {}	# FIXME: page_min should be cached.
      page_max = {}

      site.backupdb.each {|key, v, time|
	next if times[key].nil?	# Calc only for existing pages.
	times[key] << time
	days[time.ymd_s] << [key, time]
	site_min = time if site_min.nil? || time < site_min
	site_max = time if site_max.nil? || site_max < time
	page_min[key] = time if page_min[key].nil? || time < page_min[key]
	page_max[key] = time if page_max[key].nil? || page_max[key] < time
      }

      page_min_days = Hash.new {|h, k| h[k] = []}
      page_min.each {|key, time|
	page_min_days[time.ymd_s] << [key, time]
	


      }


      # Calc history from older to newer.
      pages_history = page_min.to_a.sort {|a, b|
	a[1] <=> b[1]
      }.map {|a|
	a[0]
      }

      # Count second when the page is created to the last update.
      site_max = Time.at(1) if site_max.nil?
      site_min = Time.at(0) if site_min.nil?

      site_duration = site_max - site_min

      return times, days, page_min, page_max, site_min, site_max, pages_history, site_duration
    end

    def get_keys_by_day(ymd)
      day = @days[ymd]
      return nil if day.empty?
      day = day.sort_by {|key, time| time }
      keys = day.map {|key, time| key }.uniq
      return keys
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestSiteTimeLine < Test::Unit::TestCase
    include TestSession

    def test_all
      page = @site.create_new
      page.put_with_time('* t1', 0)	# store the first
      page.put_with_time('* t2', 1)	# store the second

      # test_last_modified
      eq(1, @site.last_modified.to_i)

      tl = @site.timeline

      # test_calc_history
      tl.calc_history
      #pp tl

      # test_times
      times = tl.times
      eq ['1'], times.keys
      eq 0, times['1'][0].to_i
      eq 1, times['1'][1].to_i

      # test_days
      days = tl.days
      day = days['19700101']
      eq [['1', Time.at(0)], ['1', Time.at(1)]], day

      # test_site_min, page_min, pages_history, site_duration
      eq Time.at(0), tl.site_min
      eq({'1'=>Time.at(0)}, tl.page_min)
      eq ['1'], tl.pages_history
      assert(0 < tl.site_duration)
    end
  end
end
