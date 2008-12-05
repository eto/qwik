# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/test-module-server'

if $0 == __FILE__
  $test = true
end

class CheckServer < Test::Unit::TestCase
  include TestServerSetupModule
  include TestServerModule

  def test_basic
    return if $0 != __FILE__		# Only for unit test.

    Thread.abort_on_exception = true

    server, config, memory, wreq, wres = setup_server
    server_thread = Thread.new { server.start }

    # In private mode.
    write_page('1', "* t\ns\n")
    str = get_path('1.html')
    ok_in(['Members Only'], '//title', str)
    #ok_in(['Login'], '//title', str)
    #ok_in([[:p, 'Please login.'], [:p, [:a, {:href=>'.login'}, 'Login']]],
#	  "//div[@class='section']", str)

    # In public mode.
    write_page('_SiteConfig', ":open:true\n")
    str = get_path('1.html')
    ok_in(['t'], '//title', str)
    ok_in([:p, 's'], "//div[@class='section']", str)

    teardown_server(server)
  end

  def test_save
    return if $0 != __FILE__		# Only for unit test.

    server, config, memory, wreq, wres = setup_server
    server_thread = Thread.new { server.start }

    write_page('_SiteMember', ",user@e.com\n")
    write_page('1', '* t')

    str = get_path('1.html')
    ok_in(['t'], '//title', str)

    str = get_path("1.save?contents=*t2")
    ok_in(['Page is saved.'], '//title', str)

    str = get_path('1.html')
    ok_in(['t2'], '//title', str)

    teardown_server(server)
  end
end
