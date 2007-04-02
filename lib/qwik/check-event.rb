# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/test-module-server'

if $0 == __FILE__
  $test = true
end

module CheckEventModule
  include TestServerSetupModule
  include TestServerModule

  def setup_event
    Thread.abort_on_exception = true

    server, config, memory, wreq, wres = setup_server
    server_thread = Thread.new { server.start }

    write_page('_SiteMember', ",user@e.com\n")
    write_page('1', "*t\np")

    return server
  end
end

if defined?($test) && $test
  class CheckEvent < Test::Unit::TestCase
    include CheckEventModule

    # http://colinux:9190/HelloQwik/ActMonitor.html
    def test_1
      return if $0 != __FILE__		# Only for unit test.

      server = setup_event

      str = get_path('1.html')
      ok_in(['t'], '//title', str)
      ok_in([:p, 'p'], "//div[@class='section']", str)

      t = Thread.new {
	sleep 0.1
	str = get_path("1.save?contents=*t2%0Ap2")	# Save to the page.
	ok_in(['Page is saved.'], '//title', str)
	ok_eq("*t2\np2", read_page('1'))
      }

      str = get_path('1.event')		# Wait for update.
      #ok_eq(",0,user@e.com,1,save,save\n", str)
      #ok_in([:p, 'p2'], "//div[@class='section']", str)

      t.join	# Wait for the thread.

      teardown_server(server)
    end

    def test_2
      return if $0 != __FILE__		# Only for unit test.

      server = setup_event

      str = get_path('1.html')
      ok_in(['t'], '//title', str)
      ok_in([:p, 'p'], "//div[@class='section']", str)

      t = Thread.new {
	str = get_path('1.event')		# Wait for update.
	ok_eq(",0,user@e.com,1,save,save\n", str)
      }

      sleep 0.1
      str = get_path("1.save?contents=*t2%0Ap2")	# Save to the page.
      ok_in(['Page is saved.'], '//title', str)
      ok_eq("*t2\np2", read_page('1'))

      t.join	# Wait for the thread.

      teardown_server(server)
    end

    def test_3
      return if $0 != __FILE__		# Only for unit test.

      server = setup_event

      str = get_path('1.html')
      ok_in(['t'], '//title', str)
      ok_in([:p, 'p'], "//div[@class='section']", str)

      t1 = Thread.new {
	str1 = get_path('1.event')	# Wait for update.
	ok_eq(",0,user@e.com,1,save,save\n", str1)
      }
      t2 = Thread.new {
	str2 = get_path('1.event')	# Wait for update.
	ok_eq(",0,user@e.com,1,save,save\n", str2)
      }

      sleep 0.1
      str = get_path("1.save?contents=*t2%0Ap2")	# Save to the page.
      ok_in(['Page is saved.'], '//title', str)
      ok_eq("*t2\np2", read_page('1'))

      t1.join	# Wait for the thread.
      t2.join	# Wait for the thread.

      teardown_server(server)
    end
  end
end
