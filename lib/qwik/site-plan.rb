# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/util-time'

module Qwik
  class Site
    # ============================== plan
    PLAN_RE = /\Aplan_(\d\d\d\d\d\d\d\d)\z/

    def get_pages_with_date
      pages = []
      self.each {|page|
	if PLAN_RE =~ page.key
          datestr = $1
	  date = Time.parse(datestr).to_i
	  pages << [page.key, date.to_i]
	  next
	end

=begin
	tags = page.get_tags
	if tags
	  tags.each {|tag|
	    date = Time.date_parse(tag)
	    if date
	      pages << [page.key, date.to_i]
	    end
	  }
	end
=end
      }
      return pages
    end

    # ============================== footer
    def get_footer(now)
      pages = get_pages_with_date
      footer = ''
      footer << generate_plan(pages, now)
      return footer
    end

    private

    def generate_plan(pages, now)
      return '' if pages.empty?

      # Select near futer.  From yesterday to 1 month in the future.
      pages = plan_select_future(pages, now)
      pages = plan_select_near_future(pages, now)
      return '' if pages.empty?

      # Sort by date.
      pages = pages.sort_by {|pagekey, datei|
	datei
      }

      str = "* Plan\n"
      pages.each {|pagekey, datei|
	date = Time.at(datei)
	date_abbr = Time.date_abbr(now, date)

	page = self[pagekey]
	title = page.get_title

	url = self.page_url(pagekey)

	str << "- [#{date_abbr}] #{title}\n"
	str << url+"\n"
      }

      return str
    end

    def plan_select_future(pages, now)
      day = 60*60*24		# 1 day
      nowi = now.to_i
      return pages.select {|pagekey, datei|
	diff = datei - nowi
	-day < diff
      }
    end

    def plan_select_near_future(pages, now)
      month = 60*60*24*30	# 1 month
      nowi = now.to_i
      return pages.select {|pagekey, datei|
	diff = datei - nowi
	diff < month
      }
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestSitePlan < Test::Unit::TestCase
    include TestSession

    def create_plan_pages(site)
      page = site.create 'plan_19700101'
      page.store("* t")
      page = site.create 'plan_19700115'
      page.store("* t")
      page = site.create 'plan_19700201'
      page.store("* t")
      page = site.create 'plan_19710101'
      page.store("* t")
    end

    def test_site_plan
      create_plan_pages(@site)
      pages = @site.get_pages_with_date
      eq [["plan_19700101", -32400],
	["plan_19700115", 1177200],
	["plan_19700201", 2646000],
	["plan_19710101", 31503600]],
	pages
    end

    def test_site_footer
      res = session

      eq '', @site.get_footer(Time.at(0))

      create_plan_pages(@site)
      eq "* Plan\n- [01-01] t\nhttp://example.com/test/plan_19700101.html\n- [01-15] t\nhttp://example.com/test/plan_19700115.html\n", @site.get_footer(Time.at(0))

      eq "* Plan\n- [01-15] t\nhttp://example.com/test/plan_19700115.html\n- [02-01] t\nhttp://example.com/test/plan_19700201.html\n", @site.get_footer(Time.at(60*60*24*10))	# 10 days later.
    end
  end
end
