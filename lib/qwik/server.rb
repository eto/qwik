#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '../../lib' unless $LOAD_PATH.include?('../../lib')
require 'qwik/config'
require 'qwik/server-memory'
require 'qwik/server-webrick'
require 'qwik/logger'

require 'qwik/action'
require 'qwik/periodic'
require 'qwik/request'
require 'qwik/response'

require 'qwik/util-pid'

module Qwik
  class Server < WEBrick::HTTPServer
    include PidModule

    def initialize(qconfig)
      @qconfig = qconfig
      @memory  = ServerMemory.new(@qconfig)

      init_trap

      init_directory(@qconfig)

      webrick_conf = init_webrick_conf(@qconfig, @memory)

      super(webrick_conf)

      mount('/', Servlet)	# Delegate all accesses.
    end
    attr_reader :memory

    def init_trap
      trap(:TERM) { shutdown; }
      trap(:INT)  { shutdown; }
    end

    def init_directory(config)
      config.cache_dir.path.check_directory
      config.sites_dir.path.check_directory
      (config.sites_dir.path+config.default_sitename).check_directory
      config.etc_dir.path.check_directory
      config.grave_dir.path.check_directory
      config.log_dir.path.check_directory
    end

    def init_webrick_conf(config, memory)
      logfile  = config.web_log_file	# qwikweb.log
      @pidfile = config.web_pid_file
      servertype = WEBrick::Daemon
      if config.debug
	@pidfile += '-d'
	servertype = WEBrick::SimpleServer
	logfile = $stdout
	logfile = 'testlog.txt' if config.test
      end

      # qwik-access.log
      memory[:accesslog] = Qwik::AccessLog.new(config, config.qlog_file)

      logger = WEBrick::Log.new(logfile, WEBrick::Log::INFO)
      memory[:logger] = logger

      accesslog =
	[[WEBrick::BasicLog.new(config.accesslog_file, WEBrick::Log::INFO),
	  WEBrick::AccessLog::COMBINED_LOG_FORMAT]]

      server = Server.server_name
      #server = "Apache/2.0.54 (Unix) "+server	# Imitate Apache server

      webrick_config = {
	:HostnameLookups => false,
	:BindAddress	=> config.bind_address,
	:Port		=> config.web_port.to_i,
	:Logger		=> logger,
	:ServerType	=> servertype,
	:StartCallback	=> Proc.new { start_server },
	:StopCallback	=> Proc.new { stop_server },
	:AccessLog	=> accesslog,
	:ServerSoftware	=> server,
	:QwikConfig	=> config,
	:QwikMemory	=> memory,
       #:MaxClients     => 100,
       #:WEBrickThread  => false, # test
      }

      return webrick_config
    end

    # callback from :StartCallback
    def start_server
      write_pid_file(@pidfile)

      threads = []
      threads <<            SweepThread.new(@qconfig, @memory)
      threads << WeeklySendReportThread.new(@memory.farm)
      threads <<  DailySendReportThread.new(@memory.farm)
      threads << HourlySendReportThread.new(@memory.farm)
      @memory[:threads] = threads
      threads.each {|th|
	t = Thread.new {
	  th.start
	}
	t.abort_on_exception = true
      }

      if @qconfig.debug
	require 'qwik/autoreload'
	autoreload(1, true)	# auto reload every sec.
      end
    end

    # callback from :StopCallback
    def stop_server
      remove_pid_file(@pidfile)
    end

    def self.version
      return VERSION
    end

    def self.server_name
      return "qwikWeb/#{VERSION}+#{RELEASE_DATE}"
    end
  end

  class Servlet < WEBrick::HTTPServlet::AbstractServlet
    def do_GET(request, response)
      config = @server[:QwikConfig]
      memory = @server[:QwikMemory]

      req = Request.new(config)
      req.parse_webrick(request)

      res = Response.new(config)
      res.set_webrick(response)

      action = Action.new
      action.init(config, memory, req, res)
      action.run

      res.setback(response)

      qlog = memory[:accesslog]
      qlog.log(request, response, req, res) if qlog	# Take a log.

      if res.basicauth
	proc = res.basicauth
	WEBrick::HTTPAuth::basic_auth(request, response, 'qwik', &proc)
      end
    end

    alias do_POST do_GET
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  require 'qwik/testunit'
  require 'qwik/act-theme'
  require 'qwik/qp'
  $test = true
end

if defined?($test) && $test
  require 'qwik/test-module-server'

  class TestServer < Test::Unit::TestCase
    include TestServerModule

    def test_front
      return if $0 != __FILE__		# Only for unit test.
      server, config, memory, wreq, wres = setup_server
      wreq.path = '/'
      wres = session(config, memory, wreq, wres)
      ok_eq("text/html; charset=Shift_JIS", wres['content-type'])
      ok_eq(?<, wres.body[0])

      teardown_server(server)
    end

    def test_css
      return if $0 != __FILE__		# Only for unit test.
      server, config, memory, wreq, wres = setup_server
      wreq.path = '/.theme/all.css'
      wres = session(config, memory, wreq, wres)
      ok_eq('text/css', wres['content-type'])
      assert_match(%r|^/*|, wres.body)
      teardown_server(server)
    end

    def test_head
      return if $0 != __FILE__		# Only for unit test.
      server, config, memory, wreq, wres = setup_server
      wreq.path = '/'
      wreq.request_method = 'HEAD'
      wres = session(config, memory, wreq, wres)
      ok_eq("text/html; charset=Shift_JIS", wres['content-type'])
      ok_eq(?<, wres.body[0])
      teardown_server(server)
    end
  end
end
