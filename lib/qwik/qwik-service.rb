require 'optparse'

$LOAD_PATH << '..' unless $LOAD_PATH.include?('..')
require 'qwik/config'
require 'qwik/version'
require 'qwik/util-pathname'

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
	return self.send(cmd, cmd_args)
      end
      puts "Error: unknown cmd [#{cmd}]"
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
	opts.on('-d', '--[no-]debug', 'Run in debug mode') {|a|
	  config[:debug] = a
	}
	opts.on('--web-start', 'Start qwikWeb services') {|a|
	  cmd = [:web_start]
	}
	opts.on('--web-stop', 'Stop qwikWeb services') {|a|
	  cmd = [:web_stop]
	}
	opts.on('--web-restart', 'Restart qwikWeb services') {|a|
	  cmd = [:web_restart]
	}
	opts.on('--ml-start', 'Start QuickML services') {|a|
	  cmd = [:ml_start]
	}
	opts.on('--ml-stop', 'Stop QuickML services') {|a|
	  cmd = [:ml_stop]
	}
	opts.on('--ml-restart', 'Restart QuickML services') {|a|
	  cmd = [:ml_restart]
	}
	opts.on('--watchlog', 'Watch log continuously') {|a|
	  cmd = [:watchlog]
	}
	opts.on('--makesite sitename,yourmailaddress', 'Make a new site') {|a|
	  cmd = [:makesite, a]
	}
	opts.on('--adduser sitename,mailaddress', 'Add a user') {|a|
	  cmd = [:adduser, a]
	}
	opts.on('--showpassword mailaddress', 'Show password') {|a|
	  cmd = [:showpassword, a]
	}
	opts.on('--incgen mailaddress', 'Increment a generation') {|a|
	  cmd = [:incgen, a]
	}
	opts.separator ''
	opts.separator 'Common options:'
	opts.on_tail('-h', '--help', 'Show this message') {
	  puts opts
	  exit
	}
	opts.on_tail('-v', '--version', 'Show version') {
	  puts VERSION
	  exit
	}
      }
      optionparser.parse!(args)
      if cmd.empty?
	print 'To show help,
 % qwik-service --help
'
      exit
	
      end
      return config, cmd
    end

    def web_start
      start_cmd('Starting qwikWeb services: ', QWIKWEB_SERVER)
    end

    def web_stop
      stop_cmd('Stopping qwikWeb services: ', QWIKWEB_PID)
    end

    def web_restart
      web_stop
      sleep 1
      web_start
    end

    def ml_start
      start_cmd('Starting QuickML services: ', QUICKML_SERVER)
    end

    def ml_stop
      stop_cmd('Stopping QuickML services: ', QUICKML_PID)
    end

    def ml_restart
      ml_stop
      sleep 1
      ml_start
    end

    def watchlog
      require 'qwik/qwikweb-watchlog'
      Qwik::WatchLog.main(ARGV)
    end

    def makesite(args)
      require 'qwik/farm'
      require 'qwik/mailaddress'

      sitename, mail = args.split(/,/)
      return makesite_usage if sitename.nil? || sitename.empty?
      return makesite_usage if mail.nil? || mail.empty?
      if ! MailAddress.valid?(mail)
	puts "Error: invalid mail form [#{mail}]"
	return makesite_usage 
      end

      memory = ServerMemory.new(@config)
      farm = Farm.new(@config, memory)

      site = nil
      begin
	site = farm.make_site(sitename)
      rescue => e
	puts "Error: The site [#{sitename}] is already exist."
	exit 1
      end

      site = farm.get_site(sitename)
      site.member.add(mail)

      puts "Creating a new site [#{sitename}] and adding an initial user [#{mail}] is completed."
    end

    def makesite_usage
      puts 'usage: qwik-service --makesite sitename,yourmailaddress'
      exit
    end

    def adduser(args)
      require 'qwik/farm'
      require 'qwik/mailaddress'

      sitename, mail = args.split(/,/)
      return adduser_usage if sitename.nil? || sitename.empty?
      return adduser_usage if mail.nil? || mail.empty?
      if ! MailAddress.valid?(mail)
	puts "Error: invalid mail form [#{mail}]"
	return adduser_usage 
      end

      memory = ServerMemory.new(@config)
      farm = Farm.new(@config, memory)

      site = farm.get_site(sitename)
      if site.nil?
	puts "Error: The site [#{sitename}] does not exist."
	exit 1
      end

      if site.member.exist?(mail)
	puts "Error: A user [#{mail}] is already exist."
	exit 1
      end

      site.member.add(mail)
      puts "Adding a new uesr [#{mail}] to site [#{sitename}] is completed."
    end

    def adduser_usage
      puts 'usage: qwik-service --adduser sitename,mailaddress'
      exit
    end

    def showpassword(mail)
      require 'qwik/password'
      require 'qwik/mailaddress'

      return showpassword_usage if mail.nil? || mail.empty?
      if ! MailAddress.valid?(mail)
	puts "Error: invalid mail form [#{mail}]"
	return showpassword_usage 
      end

      gen = PasswordGenerator.new(@config)
      puts "mail: #{mail}"
      puts "pass: #{gen.generate(mail)}"
    end

    def showpassword_usage
      puts 'usage: qwik-service --showpassword mailaddress'
      exit
    end

    def incgen(mail)
      require 'qwik/password'

      return incgen_usage if mail.nil? || mail.empty?
      if ! MailAddress.valid?(mail)
	puts "Error: invalid mail form [#{mail}]"
	return incgen_usage 
      end

      gen = PasswordGenerator.new(@config)
      g = gen.generation_inc(mail)
      puts "mail: #{mail}"
      puts "generation: #{g}"
      puts "increment generation done."
    end

    def incgen_usage
      puts 'usage: qwik-service --showpassword mailaddress'
      exit
    end

    private

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
  #args << '-d'	# force debug mode
  Qwik::QwikService.main(args)
end
