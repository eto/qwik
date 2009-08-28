# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

require 'optparse'

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/config'
require 'qwik/version'
require 'qwik/util-pathname'
require 'qwik/mailaddress'
require 'pp'
require 'qwik/qp'

module Qwik
  class QwikService
    QWIKWEB_SERVER = '/usr/bin/qwikweb-server'
    QWIKWEB_PID = '/var/run/qwik/qwikweb.pid'
    QUICKML_SERVER = '/usr/bin/quickml-server'
    QUICKML_PID = '/var/run/qwik/quickml.pid'

    def self.main(args)
      self.new.run(args)
    end

    def run(args)
      @config = Config.new
      args_conf, cmd = QwikService.parse_args('qwik-service', args)
      @config.update(args_conf)		# config file is specified by args
      file_conf = Config.load_config_file(@config[:config_file])
      @config.update(file_conf)
      @config.update(args_conf)		# Set args again to override.

      cmd, cmd_args = cmd

      if self.respond_to?(cmd)
	return self.send(cmd) if cmd_args.nil?
	return self.send(cmd, cmd_args)
      end
      warn "Error: unknown cmd [#{cmd}]"
    end

    def self.parse_args(myprog, args)
      config = {}
      cmd = []
      optionparser = OptionParser.new {|opts|
	opts.banner = "Usage: #{myprog} [options]"
	opts.separator ''
	opts.separator 'Specific options:'
	opts.on('-c', '--config file', 'Specify config file.') {|a|
	  config[:config_file] = a
	}
	opts.on('-d', '--[no-]debug', 'Run in debug mode.') {|a|
	  config[:debug] = a
	}
	opts.on('--start', 'Start qwikWeb and QuickML services.') {|a|
	  cmd = [:start]
	}
	opts.on('--stop', 'Stop qwikWeb and QuickML services.') {|a|
	  cmd = [:stop]
	}
	opts.on('--restart', 'Restart qwikWeb and QuickML services.') {|a|
	  cmd = [:restart]
	}
	opts.on('--web-start', 'Start qwikWeb services.') {|a|
	  cmd = [:web_start]
	}
	opts.on('--web-stop', 'Stop qwikWeb services.') {|a|
	  cmd = [:web_stop]
	}
	opts.on('--web-restart', 'Restart qwikWeb services.') {|a|
	  cmd = [:web_restart]
	}
	opts.on('--ml-start', 'Start QuickML services.') {|a|
	  cmd = [:ml_start]
	}
	opts.on('--ml-stop', 'Stop QuickML services.') {|a|
	  cmd = [:ml_stop]
	}
	opts.on('--ml-restart', 'Restart QuickML services.') {|a|
	  cmd = [:ml_restart]
	}
	opts.on('--watchlog', 'Watch log continuously.') {|a|
	  cmd = [:watchlog]
	}
	opts.on('--makesite sitename,mailaddr', 'Make a new site.') {|a|
	  cmd = [:makesite, a]
	}
	opts.on('--adduser sitename,mailaddr', 'Add a user.') {|a|
	  cmd = [:adduser, a]
	}
	opts.on('--showpassword mailaddress', 'Show password.') {|a|
	  cmd = [:showpassword, a]
	}
	opts.on('--incgen mailaddress', 'Increment a generation.') {|a|
	  cmd = [:incgen, a]
	}
	opts.separator ''
	opts.separator 'Debug options:'
	opts.on('--showinactive', 'Show inactive sites.') {|a|
	  cmd = [:showinactive, a]
	}
	opts.separator ''
	opts.separator 'Common options:'
	opts.on_tail('-h', '--help', 'Show this message.') {
	  puts opts
	  exit
	}
	opts.on_tail('-v', '--version', 'Show version.') {
	  puts VERSION
	  exit
	}

      }

      begin
	optionparser.parse!(args)
      rescue OptionParser::ParseError => err
	puts err.message
	puts optionparser.to_s
	exit
      end
      if cmd.empty?
        puts optionparser.to_s
	exit
      end
      return config, cmd
    end

    def start
      web_start
      ml_start
    end

    def stop
      web_stop
      ml_stop
    end

    def restart
      stop
      sleep 1
      start
    end

    def web_start
      start_cmd('Starting qwikWeb services: ',
		"#{QWIKWEB_SERVER} -c #{@config[:config_file]}")
    end

    def web_stop
      pidfile = @config[:web_pid_file] || QWIKWEB_PID
      pidfile += '-d' if @config[:debug]
      stop_cmd('Stopping qwikWeb services: ', pidfile)
    end

    def web_restart
      web_stop
      sleep 1
      web_start
    end

    def ml_start
      start_cmd('Starting QuickML services: ',
		"#{QUICKML_SERVER} -c #{@config[:config_file]}")
    end

    def ml_stop
      pidfile = @config[:ml_pid_file] || QUICKML_PID
      stop_cmd('Stopping QuickML services: ', pidfile)
    end

    def ml_restart
      ml_stop
      sleep 1
      ml_start
    end

    def watchlog
      require 'qwik/qwikweb-watchlog'
      WatchLog.new(@config).run
    end

    def makesite(args)
      require 'qwik/farm'
      require 'qwik/mailaddress'

      def usage
	warn 'Usage: qwik-service --makesite sitename,yourmailaddress'
	exit
      end

      sitename, mail = args.split(/,/, 2)
      return usage if sitename.nil? || sitename.empty?
      return usage if mail.nil? || mail.empty?
      if ! MailAddress.valid?(mail)
	warn "Error: invalid mail form [#{mail}]"
	return usage 
      end

      memory = ServerMemory.new(@config)
      farm = Farm.new(@config, memory)

      site = nil
      begin
	site = farm.make_site(sitename)
      rescue Errno::EACCES => e
	error e.to_s
      rescue => e
	error "The site [#{sitename}] is already exist."
      end

      site = farm.get_site(sitename)
      site.member.add(mail)

      puts "Creating a new site [#{sitename}] and
adding an initial user [#{mail}] is completed."
    end

    def adduser(args)
      require 'qwik/farm'
      require 'qwik/mailaddress'

      def usage
	die 'Usage: qwik-service --adduser sitename,mailaddress'
      end

      sitename, mail = args.split(/,/, 2)
      return usage if sitename.nil? || sitename.empty?
      return usage if mail.nil? || mail.empty?
      if ! MailAddress.valid?(mail)
	warn "Error: invalid mail form [#{mail}]"
	return usage 
      end

      memory = ServerMemory.new(@config)
      farm = Farm.new(@config, memory)

      site = farm.get_site(sitename)
      if site.nil?
	error "The site [#{sitename}] does not exist."
      end

      if site.member.exist?(mail)
	error "A user [#{mail}] is already exist."
      end

      site.member.add(mail)
      puts "Adding a new user [#{mail}] to site [#{sitename}] is completed."
    end

    def showpassword(mail)
      require 'qwik/password'
      require 'qwik/mailaddress'

      def usage
	die 'Usage: qwik-service --showpassword mailaddress'
      end

      return usage if mail.nil? || mail.empty?
      if ! MailAddress.valid?(mail)
	warn "Error: invalid mail form [#{mail}]"
	return usage 
      end

      gen = PasswordGenerator.new(@config)
      puts "mail: #{mail}"
      puts "pass: #{gen.generate(mail)}"
    end

    def incgen(mail)
      require 'qwik/password'

      def usage
	die 'Usage: qwik-service --showpassword mailaddress'
      end

      return usage if mail.nil? || mail.empty?
      if ! MailAddress.valid?(mail)
	warn "Error: invalid mail form [#{mail}]"
	return usage 
      end

      gen = PasswordGenerator.new(@config)
      g = gen.generation_inc(mail)
      puts "mail: #{mail}"
      puts "generation: #{g}"
      puts "increment generation done."
    end

    def showinactive(*a)
      require 'qwik/farm'

      memory = ServerMemory.new(@config)
      farm = Farm.new(@config, memory)
      inactive_sites = farm.check_inactive_sites
      p inactive_sites
    end

    private

    def die(msg)
      warn msg
      exit
    end

    def error(msg)
      warn "Error: " + msg
      exit 1
    end

    def start_cmd(msg, cmd)
      print msg
      system cmd
      puts
    end

    def stop_cmd(msg, pid_file)
      print msg
      pid = pid_file.path.read.to_i
      Process.kill(:KILL, pid)
      puts

#	pid = `cat /usr/local/qwik/log/qwikweb.pid`
#	pid = `cat /var/run/qwik/qwikweb.pid`
#	process = `ps ho%c -p $pid`
#	if [ $process = "qwikweb-server" ] ; then
#		kill $pid
#		echo 
#	else
#		echo "Stopping failed."
#	fi
    end
  end
end

if $0 == __FILE__
  args = ARGV
 #args << '-d'		# force debug mode
  Qwik::QwikService.main(args)
end
