# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    D_SiteLog = {
      :dt => 'Show SiteLog',
      :dd => 'You can see sitelog of this site.',
      :dc => "* How to
 [[.sitelog]]
Follow this link. [[.sitelog]]
"
    }

    D_SiteLog_ja = {
      :dt => '編集履歴',
      :dd => 'いままでの編集履歴を見ることができます。',
      :dc => "* 使い方
 [[.sitelog]]
[[.sitelog]]を辿ってください。
"
    }

    # sitelog viewer
    def plg_sitelog
      dl = [:dl]
      @site.sitelog.list.each {|k, v|
	user, cmd, pagename = v
	user = 'anonymous' if user.nil? || user.empty?
	user = MailAddress.obfuscate(user) if ! user.empty?
	dl << [:dt, "#{Time.at(k.to_i).ymdx} - #{user}"]
	dl << [:dd, "#{cmd}: ", [:a, {:href=>"#{pagename}.html"}, pagename]]
      }
      return dl
    end

    # sitelog viewer
    def act_sitelog
      return c_plain('SiteLog') {
	[:div, {:class=>'day'},
	  [:div, {:class=>'section'}, plg_sitelog]]
      }
    end

    def c_time_str(time=nil)
      time ||= @req.start_time
      return sprintf('%.6f', time.to_i + time.usec/1000000.0)
    end

    def c_make_log(cmd, pagename=@req.base)
      timestr = c_time_str
      @site.log(timestr, @req.user, cmd, pagename)
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActSiteLog < Test::Unit::TestCase
    include TestSession

    def test_time_str
      res = session
      assert_match(/\d+\.\d{6}/, @action.c_time_str)
      ok_eq('0.000000', @action.c_time_str)
    end

    def test_sitelog
      t_add_user

      # Create a page.
      res = session('POST /test/.new?t=TestPage'){|req|
	req.start_time += 1
      }
      ok_eq(',1.000000,user@e.com,create,TestPage
', @site['_SiteLog'].load)

      # Save a page.
      res = session('POST /test/TestPage.save?contents=t'){|req|
	req.start_time += 2
      }
      ok_eq(',1.000000,user@e.com,create,TestPage
,2.000000,user@e.com,save,TestPage
', @site['_SiteLog'].load)

      # Delete a page.
      res = session('POST /test/TestPage.save?contents='){|req| # null content
	req.start_time += 3
      }
      ok_eq(',1.000000,user@e.com,create,TestPage
,2.000000,user@e.com,save,TestPage
,3.000000,user@e.com,delete,TestPage
', @site['_SiteLog'].load)

      # See the SiteLog.
      page = @site.create_new
      page.store('{{sitelog}}')
      res = session('/test/1.html'){|req|
	req.start_time += 4
      }
      div = @res.body.get_path("//div[@class='section']")
      div = div.inside.remove_comment.get_single
      ok_eq([:dd, 'create: ',
	      [:a, {:href=>'TestPage.html'}, 'TestPage']], div[2])
      ok_eq([:dd, 'save: ',
	      [:a, {:href=>'TestPage.html'}, 'TestPage']], div[4])
      ok_eq([:dd, 'delete: ',
	      [:a, {:href=>'TestPage.html'}, 'TestPage']], div[6])
    end
  end
end
