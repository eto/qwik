# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/config'
require 'qwik/server-memory'
require 'qwik/server-webrick'
require 'qwik/logger'

require 'qwik/action'
require 'qwik/periodic'
require 'qwik/request'
require 'qwik/response'

require 'qwik/util-pid'
require 'qwik/qp'

require 'logger'

module Qwik
  class Server < WEBrick::HTTPServer
    include PidModule

    def initialize(qconfig)
      @qconfig = qconfig
      @memory  = ServerMemory.new(@qconfig)

      # init_trap
      trap(:TERM) { shutdown; }
      trap(:INT)  { shutdown; }
      if Signal.list.key?("HUP")
        trap(:HUP)  { reopen; }
      end

      init_directory(@qconfig)

      webrick_conf, @pidfile = init_webrick_conf(@qconfig, @memory)

      init_bury_logger

      super(webrick_conf)

      mount('/', Servlet)	# Delegate all accesses.
    end
    attr_reader :memory

    def init_directory(config)
      config.cache_dir.path.check_directory
      config.sites_dir.path.check_directory
      (config.sites_dir.path+config.default_sitename).check_directory
      config.etc_dir.path.check_directory
      config.grave_dir.path.check_directory
      config.log_dir.path.check_directory
    end

    def init_webrick_conf(config, memory)
      # qwik-error.log
      web_error_log = (config.log_dir.path + Logger::WEB_ERROR_LOG).to_s
      pidfile = config.web_pid_file	# qwikweb.pid
      servertype = WEBrick::Daemon
      if config.debug
	pidfile += '-d'
	servertype = WEBrick::SimpleServer
	web_error_log = $stdout
	web_error_log = 'qwik-error.log' if config.test
      end

      # qwik-access.log
      log = config.log_dir.path + Logger::WEB_ACCESS_LOG
      logger = Qwik::Logger.new(log.to_s)
      logger.verbose = true if config.debug && ! config.test
      memory[:qwik_access_log] = logger

      web_error_logger = WEBrick::Log.new(web_error_log, WEBrick::Log::INFO)
      memory[:logger] = web_error_logger

      access_log_file = (config.log_dir.path + Logger::ACCESS_LOG).to_s
      accesslog_logger =
	[[WEBrick::BasicLog.new(access_log_file, WEBrick::Log::INFO),
	  WEBrick::AccessLog::COMBINED_LOG_FORMAT]]

      server = Server.server_name
      #server = "Apache/2.0.54 (Unix) #{server}"	# Imitate Apache server

      webrick_config = {
	:HostnameLookups => false,
	:BindAddress	=> config.bind_address,
	:Port		=> config.web_port.to_i,
	:Logger		=> web_error_logger,
	:ServerType	=> servertype,
	:StartCallback	=> Proc.new { start_server; },
	:StopCallback	=> Proc.new { stop_server; },
	:AccessLog	=> accesslog_logger,
	:ServerSoftware	=> server,
	:QwikConfig	=> config,
	:QwikMemory	=> memory,
       #:MaxClients     => 100,
       #:WEBrickThread  => false, # test
      }

      return webrick_config, pidfile
    end

    # callback from :StartCallback
    def start_server
      write_pid_file(@pidfile)

      threads = []
      threads <<            SweepThread.new(@qconfig, @memory)
      threads << WeeklySendReportThread.new(@memory)
      threads <<  DailySendReportThread.new(@memory)
      threads << HourlySendReportThread.new(@memory)
      @memory[:threads] = threads
      threads.each {|th|
	t = Thread.new {
	  th.start
	}
	t.abort_on_exception = true
      }

      #qp @qconfig.debug
      if @qconfig.debug
	require 'qwik/autoreload'
	AutoReload.start(1, true, 'Web')	# auto reload every sec.
      end
    end

    # callback from :StopCallback
    def stop_server
      remove_pid_file(@pidfile)
    end

    def reopen
      # qwik-access.log is an instance of Qwik::Logger
      logger = @memory[:qwik_access_log]
      logger.reopen

      # qwik-error.log is an instance of WEBrick::Log
      logger = @memory[:logger]
      logger.reopen

      # access.log is an instance of WEBrick::BasicLog
      webrick_accesslog = @config[:AccessLog][0][0]
      webrick_accesslog.reopen
    end

    def init_bury_logger
      log_file = (@qconfig.log_dir.path + "bury.log").to_s
      # '::Logger' means standard library class.
      log = ::Logger.new(log_file, 'monthly')
      log.level = ::Logger::INFO
      @memory[:bury_log] = log
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
      start_time = Time.now

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

      diff = Time.now - start_time
      diffsec = sprintf("%.2f", diff)

      if response.body.is_a? String
        response.body.gsub!(/__qwik_page_generate_time__/, diffsec)
      end
      
      qlog = memory[:qwik_access_log]
      logline = Logger.format_log_line(req, response, diff)
      if qlog && ! Logger::IGNORE_ACTION.include?(req.plugin)
	qlog.take_log(logline)	# Take a log.
      end

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
  $test = true
end

if defined?($test) && $test
  require 'qwik/test-module-server'

  class TestServer < Test::Unit::TestCase
    include TestServerModule

    def test_frontpage
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
      wreq.path = '/.theme/css/base.css'
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
