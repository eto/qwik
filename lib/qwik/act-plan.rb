#
# Copyright (C) 2003-2006 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'
require 'qwik/site-plan'

module Qwik
  class Action
    D_plan = {
      :dt => 'Sharing plan plugin',
      :dd => 'You can show the plan of the site.',
      :dc => "* Example
 {{plan}}
{{plan}}
You can show links to the plan.
This plan plugin is in sidebar.

* How to specify plan.
Input a date tag to the title line of the page.
 * [2005-08-10] Next meeting
Input this line to the first line of the page.
Then, you'll see the plan on the sidemenu.
" }

    def plg_plan
      pages = @site.get_pages_with_date
      return nil if pages.empty?
      html = plan_make_html(pages)
      return html
    end

    def plan_make_html(pages)
      day = 60*60*24
      nowi = @req.start_time.to_i
      pages = pages.select {|pagekey, datei|
	page = @site[pagekey]
	diff = datei - nowi
	-day < diff
      }
      return nil if pages.empty?

      ul = [:ul]
      pages.sort_by {|pagekey, datei|
	datei
      }.each {|pagekey, datei|
	page = @site[pagekey]
	title = page.get_title
	date = Time.at(datei)
	now = Time.at(nowi)
	date_abbr = Action.date_abbr(now, date)
	em_title = Action.date_emphasis(now, date, title)
	ul << [:li, date_abbr, ' ', [:a, {:href=>pagekey+'.html'}, em_title]]
      }
      div = [:div, {:class=>'plan'}, [:h2, _('Plan')]]
      div << ul
      return div
    end

    # TODO: Add plan to the mail.
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActPlan < Test::Unit::TestCase
    include TestSession

    def test_plg_plan
      ok_wi([], '{{plan}}')

      page = @site.create_new
      page.store('* [1970-01-01] t')
      page = @site.create_new
      page.store('* [1970-01-15] t')
      page = @site.create_new
      page.store('* [1970-02-01] t')
      page = @site.create_new
      page.store('* [1971-01-01] t')

      ok_wi([:div, {:class=>'plan'},
	      [:h2, 'Plan'],
	      [:ul,
		[:li, '01-01', ' ', [:a, {:href=>'2.html'}, [:strong, 't']]],
		[:li, '01-15', ' ', [:a, {:href=>'3.html'}, [:em, 't']]],
		[:li, '02-01', ' ',
		  [:a, {:href=>'4.html'}, [:span, {:class=>'future'}, 't']]],
		[:li, '1971-01-01', ' ',
		  [:a, {:href=>'5.html'}, [:span, {:class=>'future'}, 't']]]]],
	    '{{plan}}')

      # $KCODE = 'n'
      ok_eq("\227\\\222\350", '—\’è')
    end
  end
end
