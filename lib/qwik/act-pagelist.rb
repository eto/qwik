$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
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
