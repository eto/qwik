#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

#require 'pp'

$LOAD_PATH << '..' unless $LOAD_PATH.include?('..')
require 'qwik/config'
require 'qwik/qp'
require 'qwik/util-tail'
require 'qwik/util-pathname'

module Qwik
  class WatchLog
    def self.main(argv)
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
	str = pid_path.get
	puts 'Process id: '+str
      end

      qp @config.web_error_log
      qp @config.access_log
      qp @config.web_access_log

      tail_f(@config.web_error_log)
      tail_f(@config.web_access_log)
      while true
	sleep 1
      end
    end

    def tail_f(file)
      Thread.new {
	tail = Tail.new(file, 0, Tail::TAIL_END)
	tail.gets { |line|
	  print line
	}
      }
    end

    def nutail_f(file)
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
  #qp argv
  argv << '-d'
  argv << '-c'
  argv << 'config-debug.txt'
  Qwik::WatchLog.main(argv)
end
