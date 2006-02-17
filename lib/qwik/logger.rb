require 'resolv'

$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'
require 'qwik/config'

module Qwik
  class Logger
    def initialize(config, log_file)
      @config = config
      @log = open(log_file, 'ab+')
      @log.sync = true
    end

    def close
      @log.close
      @log = nil
    end

    IGNORE_ACTION = %w(theme num)
    def log(wreq, wres, req, res)
      return if IGNORE_ACTION.include?(req.plugin)
      format = format_log_line(req, wres)
      @log << format
      $stdout << format if @config.debug && ! @config.test
    end

    # FIXEM: Ad hoc reopen support.
    def reopen
      @log.close
      log_file = @log.path
      @log = open(log_file, 'ab+')
      @log.sync = true
    end

    private

    def format_log_line(req, wres)
      time     = req.start_time.rfc_date
      fromhost = req.fromhost
      user     = req.user || '-'
      request_line = req.request_line
      status   = wres.status
      len      = '-'
      len      = wres.body.length if wres.body.is_a? String
      str = "#{time} #{fromhost} #{user} \"#{request_line}\" #{status} #{len}\n"
      return str
    end

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
      config = Qwik::Config.new
      path = 'test-logger.txt'.path
      path.unlink if path.exist?
      ok_eq(false, path.exist?)

      # test_init
      logger = Qwik::Logger.new(config, path.to_s)
      ok_eq(true, path.exist?)

      # test_format_log_line
      Qwik::Logger.instance_eval {
	public :format_log_line
      }
      req = Qwik::Request.new(config)
      res = Qwik::Response.new(config)
      str = logger.format_log_line(req, res)
      ok_eq("1970-01-01T09:00:00  - \"\" 200 -\n", str)

      # test_log
      logger.log(req, res, req, res)
      str = path.open {|f| f.read }
      ok_eq("1970-01-01T09:00:00  - \"\" 200 -\n", str)

      # test_close
      logger.close

      path.unlink if path.exist?
      ok_eq(false, path.exist?)
    end
  end
end
