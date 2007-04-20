# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/config'
require 'qwik/util-pathname'
require 'qwik/logger'

module Qwik
  class WatchLog
    def self.main(args)
      config = Config.new
      Config.load_args_and_config(config, 'qwikweb-watchlog', args)
      self.new(config).run
    end

    def initialize(config)
      @config = config
    end

    # http://colinux:9190/qtest/
    def run
      pid_path = @config.web_pid_file.path
      if pid_path.exist?
	str = pid_path.read
	puts 'Process id: '+str
      end

      p error_log = @config.log_dir.path + Logger::WEB_ERROR_LOG
      p access_log = @config.log_dir.path + Logger::ACCESS_LOG
      p web_access_log = @config.log_dir.path + Logger::WEB_ACCESS_LOG

      t1 = start_tail_f(error_log.to_s)
      t2 = start_tail_f(web_access_log.to_s)
      loop { sleep 1 }
    end

    def start_tail_f(file)
      return Thread.new {
        open(file) {|log|
	  log.seek(0, IO::SEEK_END)
          tail_f(log) {|line| puts line }
        }
      }
    end

    def tail_f(input)
      loop {
        line = input.gets
        yield line if line
        if input.eof?
          sleep 1
          input.seek(input.tell)
        end
      }
    end
  end
end

if $0 == __FILE__
  argv = ARGV
#  argv << '-d'
#  argv << '-c'
#  argv << 'config-debug.txt'
  Qwik::WatchLog.main(argv)
end
