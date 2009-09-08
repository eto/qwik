# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    def pagelist_update
      running_path =  @site.cache_path + "pagelist.dat.running"
      pagelist_path =  @site.cache_path + "pagelist.dat"

      return if running_path.exist?

      Thread.new {
        running_path.write("running")

        ar = []
        list = @site.date_list
        list.reverse.each {|page|
          key = page.key
          time = page.mtime.to_i
          title = page.get_title
          ar << [key, time, title]
        }
        dat = Marshal.dump(ar)
        pagelist_path.write(dat)

        running_path.unlink if running_path.exist?
      }
    end

    def pagelist_get
      pagelist_path =  @site.cache_path + "pagelist.dat"

      unless pagelist_path.exist?
        pagelist_update
        return [] 
      end

      dat = pagelist_path.read
      ar = Marshal.load(dat)
      return ar
    end

    def act_list
      c_surface(_('Page List'), true) {
	[:div, {:class=>'day'},
	  [:div, {:class=>'section'},
	  plg_title_list]]
      }
    end

    def plg_title_list
      str = @site.title_list.map {|page|
	"- #{page.mtime.ymd} : [[#{page.key}]]"
      }.join("\n")
      return c_res(str)
    end

    def act_recent(max = -1)
      str = recent_str(max)
      c_surface(_('Recent Changes'), true) {
	[:div, {:class=>'day'},
	  [:div, {:class=>'section'}, c_res(str)]]
      }
    end

    def plg_recent_list(max = -1)
      return c_res(recent_str(max))
    end
    alias :plg_recent :plg_recent_list

    def plg_side_recent(*a)
      return [
	[:h2, _('Recent change')],
	plg_srecent(*a)
      ]
    end

    def plg_srecent(max = -1)
      max = max.to_i
      ar = []

      now = @req.start_time
      
      list = pagelist_get
      overflow = nil
      list.each_with_index {|a, i|
	if 0 <= max && max < (i += 1)
	  overflow = [:p,{:class=>'recent'},
	    [:a, {:href=>'RecentList.html'}, [:em, _('more...')]]]
	  break
	end

        key, t, title = a
        time = Time.at(t)
	difftime = now.to_i - time.to_i
	timestr = time.ymdx.to_s
	li = [:li,
	  [:a, {:href=>"#{key}.html", :title=>timestr}, title]]
	if @req.user
	  li += [' ', [:span, {:class=>'ago'},
	      int_to_time(difftime)+_(' ago')]]
	end
	ar << li
      }
      div = [:div, {:class=>'recent'}, [:ul, ar]]
      div << overflow if overflow
      return div
    end

    def nu_plg_srecent(max = -1)
      max = max.to_i
      ar = []
      now = @req.start_time
      list = @site.date_list
      overflow = nil
      list.reverse.each_with_index {|page, i|
	if 0 <= max && max < (i += 1)
	  overflow = [:p,{:class=>'recent'},
	    [:a, {:href=>'RecentList.html'}, [:em, _('more...')]]]
	  break
	end
	time = page.mtime
	difftime = now.to_i - time.to_i
	timestr = time.ymdx.to_s
	li = [:li,
	  [:a, {:href=>"#{page.key}.html", :title=>timestr}, page.get_title]]
	if @req.user
	  li += [' ', [:span, {:class=>'ago'},
	      int_to_time(difftime)+_(' ago')]]
	end
	ar << li
      }
      div = [:div, {:class=>'recent'}, [:ul, ar]]
      div << overflow if overflow
      return div
    end

    def recent_str(max = -1)
      max = max.to_i
      ar = []
      last_day = nil
      add_day = true
      @site.date_list.reverse.each_with_index {|page, i|
	break if 0 <= max && max < (i += 1)
	if add_day
	  day = page.mtime.ymd.to_s
	  if last_day.nil? || day != last_day
	    ar << "** #{day}"
	    last_day = day
	  end
	end
	ar << "- [[#{page.key}]]"
      }
      ar.join("\n")
    end

    def int_to_time(n)
      return n.to_s+_('sec.') if n < 60 # under 1 min 
      return (n/60).to_s+_('min.') if n < 60*60 # under 1 hour
      return (n/(60*60)).to_s+_('hour') if n < 60*60*24 # under 1 day
      return (n/(60*60*24)).to_s+_('day') if n < 60*60*24*30 # under 1 month
      return (n/(60*60*24*30)).to_s+_('month') if n < 60*60*24*365 # under 1 year
      return (n/(60*60*24*365)).to_s+_('year') if n < 60*60*24*365*100 # under 1 century
      return (n/(60*60*24*365*100)).to_s+_('century')
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActList < Test::Unit::TestCase
    include TestSession

    def test_title_list
      t_add_user
      res = session('/test/.list')
      ok_title('Page List')
      ok_wi(/<ul><li>/, "{{title_list}}")
      ok_wi(%r| : <a href="1.html">1</a></li>|, "{{title_list}}")
    end

    def test_recent_list
      t_add_user
      res = session('/test/.recent')
      ok_title('Recent Changes')
      ok_wi(/<h3>/, "{{recent_list}}")
      ok_wi(%r|<li><a href=\"1.html\">1</a></li>|, "{{recent}}")
      ok_wi(/<h3>/, "{{recent_list(1)}}")
    end

    def test_srecent
      t_add_user

      # test with no pages.
      ok_wi [:div, {:class=>"recent"}, [:ul, []]], "{{srecent}}"
      
      # test with a page.
      page = @site["1"]
      page.put_with_time("* t1", 1)
      @action.pagelist_update
      ok_wi [:div, {:class=>"recent"},
             [:ul,
              [[:li,
                [:a, {:href=>"1.html", :title=>"1970-01-01 09:00:01"}, "t1"],
                " ",
                [:span, {:class=>"ago"}, "-1sec. ago"]]]]], "{{srecent}}"

      # test with two pages.
      page = @site.create("2")
      page.put_with_time("* t2", 2)
      @action.pagelist_update
=begin
      ok_wi [:div, {:class=>"recent"},
             [:ul,
              [[:li,
                [:a, {:href=>"1.html", :title=>"2009-09-04 10:16:25"}, "1"],
                " ",
                [:span, {:class=>"ago"}, "-1252026985sec. ago"]],
               [:li,
                [:a, {:href=>"2.html", :title=>"1970-01-01 09:00:02"}, "t2"],
                " ",
                [:span, {:class=>"ago"}, "-2sec. ago"]]]]], "{{srecent}}"
=end
    end

    def ok_time(e, n)
      eq e, @action.int_to_time(n)
    end

    def test_time
      res = session
      ok_time '1sec.',	1
      ok_time '1min.',	60
      ok_time '1hour',	60*60
      ok_time '1day',	60*60*24
      ok_time '1month',	60*60*24*30
      ok_time '1year',	60*60*24*365
      ok_time '1century',	60*60*24*365*100
    end
  end
end
