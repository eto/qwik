#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '..' unless $LOAD_PATH.include?('..')
require 'qwik/site-plan'
#require 'qwik/act-date'

module Qwik
  class Site
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
	date_abbr = Action.date_abbr(now, date)

	page = self[pagekey]
	title = page.get_title

	url = self.page_url(pagekey)

	str << "- ["+date_abbr+"] "+title+"\n"
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
  class TestSiteFooter < Test::Unit::TestCase
    include TestSession

    def test_all
      res = session

      now = Time.at(0)
      footer = @site.get_footer(now)
      ok_eq('', footer)

      page = @site.create_new
      page.store("* [1970-01-01] t")
      page = @site.create_new
      page.store("* [1970-01-15] t")
      page = @site.create_new
      page.store("* [1970-02-01] t")
      page = @site.create_new
      page.store("* [1971-01-01] t")

      now = Time.at(0)
      footer = @site.get_footer(now)
      ok_eq("* Plan
- [01-01] t
http://example.com/test/1.html
- [01-15] t
http://example.com/test/2.html
", footer)

      now = Time.at(60*60*24*10)	# 10 days later.
      footer = @site.get_footer(now)
      #puts footer
      ok_eq("* Plan
- [01-15] t
http://example.com/test/2.html
- [02-01] t
http://example.com/test/3.html
", footer)

    end
  end
end
