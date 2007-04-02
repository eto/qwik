# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/check-event'

if $0 == __FILE__
  $test = true
end

if defined?($test) && $test
  class CheckEvent2 < Test::Unit::TestCase
    include CheckEventModule

    def test_many
      return if $0 != __FILE__		# Only for unit test.

      server = setup_event

      ts = []
      res = []
      max = 15	# OK.
      #max = 10	# Not OK.
      (0..max).each {|i|
	ts[i] = Thread.new {
	  res[i] = get_path('1.event')		# Wait for update.
	  #ok_in([:p, 'p2'], "//div[@class='section']", res[i])
	}
      }

      loop {
	str = get_path("1.save?contents=*t2%0Ap2")	# Save to the page.
	ok_in(['Page is saved.'], '//title', str)
	ok_eq("*t2\np2", read_page('1'))

	sleep 0.1

	endok = true
	(0..max).each {|i|
	  if ts[i].status != false
	    endok = false
	  end
	}
	break if endok
      }

      (0..max).each {|i|
	ts[i].join	# Wait for the thread.
      }

      teardown_server(server)
    end
  end
end
