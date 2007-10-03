#
# Copyright (C) 2002-2004 Satoru Takabayashi <satoru@namazu.org> 
# Copyright (C) 2003-2006 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

require 'thread'

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/util-safe'
require 'qwik/util-pathname'

module QuickML
  class Logger
    ML_LOG_FILE = 'quickml.log'

    def initialize (log_filename, verbose_mode = nil)
      @mutex = Mutex.new
      log_path = log_filename.path
      log_path.parent.check_directory
      @log_file = log_path.open('a')
      @log_file.sync = true
      @verbose_mode = verbose_mode
    end

    def log (msg)
      puts_log(msg)
    end

    def vlog (msg)
      puts_log(msg) if @verbose_mode
    end

    def reopen
      @mutex.synchronize {
	log_filename = @log_file.path
      	@log_file.close
      	@log_file = File.open(log_filename, 'a')
      }
    end

    private

    def puts_log (msg)
      @mutex.synchronize {
	time = Time.now.strftime('%Y-%m-%dT%H:%M:%S')
	str = "#{time}: #{msg}"
	@log_file.puts str
	$stdout.puts str if $ml_debug
      }
    end
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  $test = true
end

if defined?($test) && $test
  class TestMLLogger < Test::Unit::TestCase
    def test_all
      file = '.test/testlog.txt'
      logger = QuickML::Logger.new(file)

      # test_log
      logger.log('t')
      str = open(file) {|f| f.read }
      assert_match(/: t\n/, str)
      file.path.unlink

      # TODO
      # test_vlog
      # test_reopen
      # test_puts_log
    end
  end
end
