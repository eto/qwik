# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

require 'pp'
require 'qwik/autoreload'
require 'qwik/util-webrick'

begin
  require 'qwik/webdavhandler'
  $have_webdavhandler = true
rescue LoadError
  $have_webdavhandler = false
end

if $have_webdavhandler

class MyWebDAVHandler < WEBrick::HTTPServlet::WebDAVHandler
  def do_OPTIONS(req, res)
    super
  end

  def do_PROPFIND(req, res)
    super(req, res)
  end
end

def start_server
  $running = true
  AutoReload.start(1, true)	# auto reload every sec.

  log = WEBrick::Log.new
  log.level = WEBrick::Log::DEBUG if $DEBUG

  server = WEBrick::HTTPServer.new({:Port => 10080, :Logger => log})
  server.mount("/", MyWebDAVHandler, Dir.pwd)
  trap(:INT) { server.shutdown }
  server.start
end

if $0 == __FILE__
  if ARGV[0] == '--server'
    $server = true
  else
    require 'qwik/testunit'
    $test = true
  end
end

if defined?($test) && $test
  class TestWebDAV < Test::Unit::TestCase
    def test_all
    end
  end
end

if defined?($server) && $server
  if ! $running
    start_server
  end
end

end
