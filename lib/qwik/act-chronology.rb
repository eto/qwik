$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'
require 'qwik/site-timeline'

module Qwik
  class Action
    D_chronology = {
      :dt => 'Chronology of site',
      :dd => "You can see when the pages are created and updated.",
      :dc => "* How to
 [[.time_walker]]
Please follow this link to see the chronology of this site. [[.time_walker]]
"
    }

    def act_time_walker
      c_require_pagename
     #c_require_member

      timeline = @site.timeline
      timeline.calc_history
      divs = time_walker_make_divs(timeline)
      return time_walker_show(divs)
    end

    TIME_WALKER_WIDTH  = 950
    TIME_WALKER_HEIGHT = 550

    def time_walker_make_divs(timeline)
#      height = 

      times = timeline.times
      pages_history = timeline.pages_history
      page_min = timeline.page_min
      site_min = timeline.site_min
      site_duration = timeline.site_duration

      return [:p, "No files here."] if times.nil?
      page_num = times.length	# Total page number
      return [:p, "No files here."] if page_num == 0

      h_span = TIME_WALKER_HEIGHT/page_num
      x_offset = 60
      y_offset = 50

      divs = []
      num = 0
      pages_history.each {|key|
	ar = times[key]

	pm_time = page_min[key]

	x = 10
	y = y_offset + TIME_WALKER_HEIGHT * num / page_num

	page = @site[key]
	next if page.nil?
	title = page.get_title
	url = page.url

	divs << [:div, {:title=>title+" | "+pm_time.ymd,
	    :class=>'time_title',
	    :style=>"position:absolute;left:#{x}px;top:#{y}px;height:#{h_span}px;"},
	  [:a, {:href=>url}, title]]

	num += 1
	ar.each {|time|
	  past_time = time - site_min
	  x = x_offset + (TIME_WALKER_WIDTH-x_offset) * past_time / site_duration
	  divs << [:div, {:title=>title+" | "+time.ymd,
	      :class=>'time_update',
	      :style=>"left:#{x}px;top:#{y}px;width:10px;height:#{h_span}px;"},
	    [:a, {:href=>url}, '_']]
	}
      }

      return divs
    end

    def time_walker_show(divs)
      ar = []

      ar << [:style, "@import '.theme/css/wema.css';"]

      ar << [:style, "
.time_update {
  margin: 0;
  padding: 0;
  position: absolute;
  background-color: #6dd;
  border: 1px outset #9ff;
}
.time_update a {
  margin: 0;
  padding: 0;
}
"]

      section = []
      section << [:div, {:id=>"time_walker"}, '']
      section << divs
      section << [:div, {:id=>'lines'}, '']
      ar << [:div, {:class=>'day'},
	[:div, {:class=>'section'},
	  section]]

      ar << [:script,
	{:type=>'text/javascript', :src=>'.theme/js/wema.js'}, '']
      ar << [:script,
	{:type=>'text/javascript',:src=>'.theme/js/history.js'}, '']

      #title = _('Time walker') + ' | ' + @site.sitename
      title = _('Chronology') + ' | ' + @site.sitename
      return c_plain(title) { ar }
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActChronology < Test::Unit::TestCase
    include TestSession

    def test_all
      t_add_user

      page = @site.create_new
      page.store('* t1') # store the first
      page.store('* t2') # store the second

      res = session('/test/.time_walker')
      #ok_in(['Time walker | test'], '//title')
      ok_in(['Chronology | test'], '//title')
    end
  end
end
