#
# Copyright (C) 2003-2006 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

# Under construction.

$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'
require 'qwik/site-timeline'
require 'qwik/act-time-walker'

module Qwik
  class Action
    # find newest day.
    def act_day
      timeline = @site.timeline
      timeline.calc_history
      #pp timeline

      max = timeline.site_max
      day = max.ymd_s

#      qp day

      @req.base = day
      return ext_day

#      return c_notice('max') {
#	day
#      }
    end

    # http://colinux:9190/HelloQwik/20050808.day
    # http://colinux:9190/HelloQwik/20050807.day
    # http://co/qwik/qwikweb/20051126.day
    # http://eto.com/d/20051204.day
    def ext_day
      day = @req.base
      return c_nerror('require arg') if day.nil?

      if /\A(\d\d\d\d)(\d\d)(\d\d)\z/ =~ day
	time = Time.local($1, $2, $3)
      else      
	return c_nerror('wrong format')
      end

      timeline = @site.timeline
      timeline.calc_history

      #qp timeline.days
      ymd = time.ymd_s
      keys = timeline.get_keys_by_day(ymd)
      return c_nerror('no contents') if keys.nil?

      ar = []
      keys.each {|pagename|
        page = @site[pagename]
        ar << [:h1, [:a, {:href=>"#{pagename}.html"}, page.get_title]]
        ar << surface_get_body(page)
        pageattribute = c_page_res('_PageAttribute')
      }
      return c_surface(_('A day') + ' | ' + ymd) {
        ar
      }
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActDay < Test::Unit::TestCase
    include TestSession

    def test_all
      t_add_user

      page = @site.create_new
      page.put_with_time('* t1', Time.at(0)) # Store the first.
      page.put_with_time('* t2', Time.at(1)) # Store the second.

      # test_act_day
      res = session('/test/.day')
#      ok_in(['max'], '//title')

      # test_ext_day
      # There is a page in 1970-01-01.
      res = session('/test/19700101.day')
      ok_in(["A day | 19700101"], '//title')

      # There is no page in 1970-01-02.
      res = session('/test/19700102.day')
      ok_in(['no contents'], '//title')
    end
  end
end
