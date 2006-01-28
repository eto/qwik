$LOAD_PATH << '..' unless $LOAD_PATH.include?('..')

require 'pp'
require 'qwik/qp'
require 'qwik/autoreload'
require 'qwik/util-webrick'
require 'qwik/webdavhandler'

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
