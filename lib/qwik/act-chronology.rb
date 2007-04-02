# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/site-timeline'

module Qwik
  class Action
    D_ExtChronology = {
      :dt => 'Chronology of site',
      :dd => "You can see when the pages are created and updated.",
      :dc => "* How to
Please go [[.chronology]] page to see the chronology of this site.
"
    }

    D_ExtChronology_ja = {
      :dt => '年表機能 ',
      :dd => "サイトのページがいつ作成され、編集されてきたのかを一覧できます。",
      :dc => '* 使い方
[[.chronology]]ページで、このサイトの年表が表示さます。
'
    }

    def act_chronology
      c_require_pagename
     #c_require_member

      timeline = @site.timeline
      timeline.calc_history
      divs = chronology_make_divs(timeline)
      return chronology_show(divs)
    end
    alias act_time_walker act_chronology	# Obsolete

    CHRONOLOGY_WIDTH  = 950
    CHRONOLOGY_HEIGHT = 550

    def chronology_make_divs(timeline)
#      height = 

      times = timeline.times
      pages_history = timeline.pages_history
      page_min = timeline.page_min
      site_min = timeline.site_min
      site_duration = timeline.site_duration

      return [:p, "No files here."] if times.nil?
      page_num = times.length	# Total page number
      return [:p, "No files here."] if page_num == 0

      h_span = CHRONOLOGY_HEIGHT / page_num
      x_offset = 60
      y_offset = 50

      divs = []
      num = 0
      pages_history.each {|key|
	ar = times[key]

	pm_time = page_min[key]

	x = 10
	y = y_offset + CHRONOLOGY_HEIGHT * num / page_num

	page = @site[key]
	next if page.nil?
	title = page.get_title
	url = page.url

	divs << [:div, {:title=>"#{title} | #{pm_time.ymd}",
	    :class=>'time_title',
	    :style=>"position:absolute;left:#{x}px;top:#{y}px;height:#{h_span}px;"},
	  [:a, {:href=>url}, title]]

	num += 1
	ar.each {|time|
	  past_time = time - site_min
	  x = x_offset + (CHRONOLOGY_WIDTH-x_offset) * past_time / site_duration
	  divs << [:div, {:title=>"#{title} | #{time.ymd}",
	      :class=>'time_update',
	      :style=>"left:#{x}px;top:#{y}px;width:10px;height:#{h_span}px;"},
	    [:a, {:href=>url}, '_']]
	}
      }

      return divs
    end

    def chronology_show(divs)
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
      section << [:div, {:id=>"chronology"}, '']
      section << divs
      section << [:div, {:id=>'lines'}, '']
      ar << [:div, {:class=>'day'},
	[:div, {:class=>'section'},
	  section]]

      ar << [:script,
	{:type=>'text/javascript', :src=>'.theme/js/wema.js'}, '']
      ar << [:script,
	{:type=>'text/javascript',:src=>'.theme/js/history.js'}, '']

      title = _('Chronology') + " | #{@site.sitename}"
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
      page.store '* t1'		# Store this page first
      page.store '* t2'		# Store this page second

      res = session '/test/.chronology'
      ok_in ['Chronology | test'], '//title'
    end
  end
end
