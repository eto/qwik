#
# Copyright (C) 2002-2004 Satoru Takabayashi <satoru@namazu.org> 
# Copyright (C) 2003-2006 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

require 'socket'
require 'etc'
require 'thread'
require 'thwait'
require 'timeout'
require 'time'
require 'net/smtp'	# FIXME: Which code uses smtp?

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/ml-session'
require 'qwik/util-safe'
require 'qwik/util-pid'

module QuickML
  class Server
    include PidModule

    def initialize (config)
      @config = config
      $ml_debug = true if @config.debug
      @status = :stop
      @logger = @config.logger
      @server = TCPServer.new(@config.bind_address, @config.ml_port)
    end

    def start
      raise 'server already started' if @status != :stop
      write_pid_file(@config.ml_pid_file)
      @logger.log sprintf('Server started at %s:%d [%d]',
                          'localhost', @config.ml_port, Process.pid)
      accept
      @logger.log "Server exited [#{Process.pid}]"
      remove_pid_file(@config.ml_pid_file)
    end

    def shutdown
      begin
	@server.shutdown
      rescue Errno::ENOTCONN
        p 'Already disconnected.'
      end
      @status = :shutdown
    end

    private

    def accept
      running_sessions = []
      @status = :running
      while @status == :running
	begin 
	  t = Thread.new(@server.accept) {|s|
	    process_session(s)
	  }
	  t.abort_on_exception = true
	  running_sessions.push(t)
	rescue Errno::ECONNABORTED # caused by @server.shutdown
	rescue Errno::EINVAL
	end
	running_sessions.delete_if {|t| t.status == false }
	if running_sessions.length >= @config.max_threads
	  ThreadsWait.new(running_sessions).next_wait
	end
      end
      running_sessions.each {|t| t.join }
    end

    def process_session (socket)
      begin
	c = @config
	session = Session.new(c, c.logger, c.catalog, socket)
	session.start
      rescue Exception => e
	@logger.log "Unknown Session Error: #{e.class}: #{e.message}"
	@logger.log e.backtrace
      end
    end

  end
end

if $0 == __FILE__
  require 'qwik/test-module-ml'
  require 'qwik/config'
  $test = true
end

if defined?($test) && $test
  class TestMLServer < Test::Unit::TestCase
    def test_all
      #return
      config = Qwik::Config.new
      config[:ml_port] = 9195
      server = QuickML::Server.new(config)
    end
  end
end
