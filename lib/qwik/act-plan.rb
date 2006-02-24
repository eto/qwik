$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'
require 'qwik/site-plan'

module Qwik
  class Action
    D_plugin_plan = {
      :dt => 'Show plan plugin',
      :dd => 'You can show the plan of this group.',
      :dc => "* Example
 {{plan}}
{{plan}}
You can see plans of this group.
If there are no plan for this group, you see nothing.
* How to input your plan.
You can specify your new plan from the tag to the title line of each page.
For example,
 * [2005-08-10] Next meeting
input this line to the first line of the page.
(Fix the date to recent days.)
Then, you'll see the plan on the sidemenu.
"
    }

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
