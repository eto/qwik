# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/check-act-monitor'

if $0 == __FILE__
  require 'qwik/server'
  $test = true
end

if defined?($test) && $test
  class CheckActMonitor2 < Test::Unit::TestCase
    include TestMonitorModule

    def test_many_monitors
      return if $0 != __FILE__		# Only for unit test.

      server = setup_monitor

      ts = []
      res = []
      max = 15	# OK.
      #max = 10	# Not OK.
      (0..max).each {|i|
	ts[i] = Thread.new {
	  res[i] = get_path('1.monitor')		# Wait for update.
	  p res[i]
	  #ok_in([:p, 'p2'], "//div[@class='section']", res[i])
	}
      }

      sleep 0.1
      str = get_path('1.save?contents=*t2%0Ap2')	# Save to the page.
      ok_in(['Page is saved.'], '//title', str)
      ok_eq("*t2\np2", read_page('1'))

      (0..max).each {|i|
	ts[i].join	# Wait for the thread.
      }

      teardown_server(server)
    end
  end
end
