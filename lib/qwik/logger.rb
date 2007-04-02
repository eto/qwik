# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

require 'resolv'

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/config'

module Qwik
  class Logger
    WEB_ACCESS_LOG = 'qwik-access.log'
    WEB_ERROR_LOG  = 'qwik-error.log'
    ACCESS_LOG = 'access.log'

    def initialize(log_file)
      @log = open(log_file, 'ab+')
      @log.sync = true
      @verbose = false
    end
    attr_writer :verbose

    def close
      @log.close
      @log = nil
    end

    IGNORE_ACTION = %w(theme num)
    def log(wreq, wres, req, res, diff)
      return if IGNORE_ACTION.include?(req.plugin)
      format = Logger.format_log_line(req, wres, diff)
      @log << format
      $stdout << format if @verbose
    end

    def take_log(format)
      #return if IGNORE_ACTION.include?(req.plugin)
      #format = Logger.format_log_line(req, wres, diff)
      @log << format
      $stdout << format if @verbose
    end

    # FIXME: Ad hoc reopen support.
    def reopen
      @log.close
      log_file = @log.path
      @log = open(log_file, 'ab+')
      @log.sync = true
    end

    def self.format_log_line(req, wres, diff)
      time     = req.start_time.rfc_date
      fromhost = req.fromhost
      user     = req.user || '-'
      request_line = req.request_line
      status   = wres.status
      len      = '-'
      len      = wres.body.length if wres.body.is_a? String
      diff = "%0.2f" % diff
      str = "#{time} #{fromhost} #{user} \"#{request_line}\" #{status} #{len} #{diff}\n"
      return str
    end

    private

    def nu_resolve(ip)
      begin
	return Resolv.getname(ip).to_s
      rescue
	return ip
      end
    end
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  require 'qwik/util-pathname'
  require 'qwik/util-time'
  require 'qwik/request'
  require 'qwik/response'
  $test = true
end

if defined?($test) && $test
  class TestLogger < Test::Unit::TestCase
    def test_logger
      c = Qwik::Logger

      # test_format_log_line
      config = Qwik::Config.new
      req = Qwik::Request.new(config)
      res = Qwik::Response.new(config)
      assert_equal "1970-01-01T09:00:00  - \"\" 200 - 0.00\n",
	c.format_log_line(req, res, 0)

      path = 'test.txt'.path
      path.unlink if path.exist?

      # test_init
      logger = Qwik::Logger.new(path.to_s)
      assert_equal true, path.exist?

      # test_log
      logger.log(req, res, req, res, 0)
      assert_equal "1970-01-01T09:00:00  - \"\" 200 - 0.00\n", path.read

      # test_close
      logger.close

      path.unlink if path.exist?
      assert_equal false, path.exist?
    end
  end
end
