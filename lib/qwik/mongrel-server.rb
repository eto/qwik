# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

# Under construction.

require 'mongrel'

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/config'
require 'qwik/server'

module Qwik
  class MongrelServer < Server
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
    end

    def start
      bind_address = config.bind_address
      port = config.web_port

      h = Mongrel::HttpServer.new(bind_address, port)
      h.register('/', MongrelHandler.new)
      start_server
      h.run.join
    end
  end

  class MongrelHandler < Mongrel::HttpHandler
    def process(request, response)
      response.socket.write("HTTP/1.1 200 OK\r
Content-Type: text/plain\r
\r
hello!
")

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

      qlog = memory[:qwik_access_log]
      qlog.log(request, response, req, res) if qlog	# Take a log.

      if res.basicauth
	proc = res.basicauth
	WEBrick::HTTPAuth::basic_auth(request, response, 'qwik', &proc)
      end
    end
  end
end
