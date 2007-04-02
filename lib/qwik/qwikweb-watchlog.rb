# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/config'
require 'qwik/util-tail'
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

      tail_f(error_log.to_s)
      tail_f(web_access_log.to_s)
      while true
	sleep 1
      end
    end

    def nu_tail_f(file)
      Thread.new {
	tail = Tail.new(file, 0, Tail::TAIL_END)
	tail.gets { |line|
	  print line
	}
      }
    end

    def tail_f(file)
      Thread.new {
	open(file) {|f|
	  f.seek(IO::SEEK_END, 0)
	  while true
	    while line = f.gets
	      print line
	    end
	    #f.seek(IO::SEEK_CUR)
	  end
	}
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
