# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/site-monitor'

module Qwik
  class Action
    # ============================== shout to monitor
    def c_monitor(cmd)
      ev = {}
      ev[:title] = 'Event occured.'
      ev[:cmd] = cmd.to_s
      ev[:pagename] = @req.base
      @site.sitemonitor.shout(ev)
    end

    # ============================== monitor plugin
    def plg_monitor(pagename=@req.base)
      return if defined?(@monitor_defined)
      @monitor_defined = true
      script = "
g_monitor_env.add('#{pagename}');
g_monitor_env.start();
"
      div = [:div, {:id=>'monitor'}]
      div << "monitor(#{pagename})" if defined?($test) && $test
      div << [:script, {:type=>'text/javascript',
	  :src=>'.theme/js/monitor.js'}, '']
      div << [:script, {:type=>'text/javascript'}, script]
      return div
    end

    # ============================== monitor connection
    def ext_monitor
      mon = @site.sitemonitor	# Connect to site monitor.
      mon.listen(self) {|ev|	# Wait for update.
	next if ev[:pagename] != @req.base
	if ev[:cmd] == 'save'
	  return monitor_save
	end
      }
      return monitor_disconnect
    end

    def monitor_save
      c_set_status
      c_set_html
      c_set_no_cache('no-cache', 'no-cache, must-revalidate')
      page = @site[@req.base]
      str = page.get_body
      w = c_res(str)
      w = c_tdiary_resolve(w)
      w = w.format_xml.page_to_xml if ! $test
      c_set_body(w)
    end

    def monitor_disconnect
      monitor_message('disconnect')
    end

    def monitor_message(title)
      c_set_status
      c_set_html
      c_set_no_cache('no-cache', 'no-cache, must-revalidate')
      w = [:msg, title]
      w = w.format_xml.page_to_xml if ! $test
      c_set_body(w)
    end

  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  #class TestActMonitor < Test::Unit::TestCase
  class TestActMonitor
    include TestSession

    def setup_monitor
      #Thread.abort_on_exception = true
      t_add_user
      page = @site.create_new
      page.store('*t')
    end

    def test_act_monitor_1st
      setup_monitor

      t = Thread.new {
	tres = session('/test/1.save?contents=t2')
	ok_in(['Page is saved.'], 'title', tres)
      }

      res = session('/test/1.monitor')	# Wait for update.
      ok_in([:p, 't2'], "//div[@class='section']", res)

      t.join	# Wait for the thread.
    end

    def test_act_monitor
      setup_monitor

      t = Thread.new {
	res = session('/test/1.monitor')	# Wait for update.
	ok_in([:p, 't2'], "//div[@class='section']", res)
      }

      tres = session('/test/1.save?contents=t2')
      ok_in(['Page is saved.'], 'title', tres)

      t.join	# Wait for the thread.
    end

    def test_several_monitors
      setup_monitor

      # FIXME: This test sometimes fails.
      t1 = Thread.new {
	t1res = session('/test/1.monitor')	# Wait for update.
	ok_in([:p, 't3'], "//div[@class='section']", t1res)
      }

      # FIXME: Sometimes fails.
      t2 = Thread.new {
	t2res = session('/test/1.monitor')	# Wait for update.
	ok_in([:p, 't3'], "//div[@class='section']", t2res)
      }

      #sleep 0.5
      #sleep 0.1
      tres = session('/test/1.save?contents=t3')
      ok_in(['Page is saved.'], 'title', tres)

      t1.join	# Wait for the thread.
      t2.join	# Wait for the thread.
    end

    def nutest_many_monitors
      setup_monitor

      ts = []
      res = []
      max = 15

      (0..max).each {|i|
	ts[i] = Thread.new {
	  res[i] = session('/test/1.monitor')	# Wait for update.
	  ok_in([:p, 't3'], "//div[@class='section']", res[i])
	}
      }

      #sleep 0.1
      tres = session('/test/1.save?contents=t3')
      assert_text('Page is saved.', 'title', tres)

      (0..max).each {|i|
	ts[i].join	# Wait for the thread.
      }
    end
  end
end
