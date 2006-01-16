#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

require 'optparse'

$LOAD_PATH << '../../lib' unless $LOAD_PATH.include?('../../lib')
require 'qwik/version'
require 'qwik/qp'

module Qwik
  class Config
    LIBDIR = File.dirname(__FILE__)
    BASEDIR = File.expand_path(LIBDIR+'/../../')

    QuickMLInternal = {
      # QuickML Internal use.
      :logger		=> nil,
      :ml_mutexes	=> nil,
      :catalog		=> nil,
      :message_catalog	=> nil,
      :content_type	=> 'text/plain',
    }

    DefaultConfig = {
      # For test and debug.
      :debug		=> false,
      :test		=> false,
      :verbose_mode	=> false,

      # Server setting.
      :user		=> 'nobody',
      :group		=> 'nobody',
      :bind_address	=> '0.0.0.0',
      :web_port		=> 9190,
      :ml_port		=> 9195,

      # Public Web address.
      :public_url	=> 'http://example.com/',
      :default_sitename	=> 'www',

      # Mailing list setting.
      :ml_domain	=> 'example.com',
      :ml_postmaster	=> 'postmaster@example.com',

      # Send mail setting.
      :smtp_host	=> '127.0.0.1',
      :smtp_port	=> 25,

      # Experimental.
      :db		=> 'fsdb',
      :ssl		=> false,

      # For Graphviz plugin.
      :graphviz_dot_path	=> '/usr/bin/dot',
      :graphviz_font_size	=> '10',
      :graphviz_font_name	=> 'Sazanami Gothic',

      # Mailing list server setting.
      :sweep_interval		=> 3600,
      :allowable_error_interval	=> 8600,
      :max_threads		=> 10,		# Number of working threads.
      :timeout			=> 120,
      :use_qmail_verp		=> false,
      :confirm_ml_creation	=> false,

      # Config for each group.
      :auto_unsubscribe_count	=> 5,
      :max_mail_length		=> 100 * 1024,	# 100KB
      :max_ml_mail_length	=> 100 * 1024,	# 100KB
      :max_members		=> 100,
      :ml_alert_time		=> 86400 * 24,
      :ml_life_time		=> 86400 * 31,

      # Setting for directories and files.
      :lib_dir		=> BASEDIR+'/lib',
      :qwiklib_dir	=> BASEDIR+'/lib/qwik',
      :sites_dir	=> BASEDIR+'/data',
      :grave_dir	=> BASEDIR+'/grave',
      :cache_dir	=> BASEDIR+'/cache',
      :super_dir	=> BASEDIR+'/share/super',
      :theme_dir	=> BASEDIR+'/share/theme',
      :template_dir	=> BASEDIR+'/share/template',
      :qrcode_dir	=> BASEDIR+'/share/qrcode',
      :etc_dir		=> BASEDIR+'/etc',
      :config_file	=> BASEDIR+'/etc/config.txt',
      :pass_file	=> BASEDIR+'/etc/password.txt',
      :generation_file	=> BASEDIR+'/etc/generation.txt',
      :log_dir		=> BASEDIR+'/log',
      :web_log_file	=> BASEDIR+'/log/qwikweb.log',
      :accesslog_file	=> BASEDIR+'/log/access.log',
      :qlog_file	=> BASEDIR+'/log/qwik-access.log',
      :ml_log_file	=> BASEDIR+'/log/quickml.log',
      :web_pid_file	=> BASEDIR+'/log/qwikweb.pid',
      :ml_pid_file	=> BASEDIR+'/log/quickml.pid',
    }

    def initialize
      @config = {}
      Config.init(@config)
    end

    def [](k)
      return @config[k]
    end

    def []=(k, v)
      @config[k] = v
    end

    def update(hash)
      @config.update(hash)
    end

    # class method

    def self.init(config)
      config.update(QuickMLInternal)
      config.update(DefaultConfig)
      Config.make_accessor(Config, config, config[:debug])
    end

    def self.load_args_and_config(config, progname, args)
      args_conf = Config.parse_args(progname, args)
      config.update(args_conf)		# config file is specified by args
      file_conf = Config.load_config_file(config[:config_file])
      config.update(file_conf)
      config.update(args_conf)		# Set args again to override.
    end

    def self.load_config_file(file)
      raise "can not open #{file}" if ! FileTest.exist?(file)
      content = open(file) {|fh| fh.read }
      return parse_config(content)
    end

    def self.parse_config(str)
      config = {}
      str.each_line {|line|
	next unless /\A\:/ =~ line
	ar = line.chomp.split(':', 3)
	next if ar[1].empty?
	config[ar[1].intern] = parse_value(ar[2])
      }
      return config
    end

    def self.parse_value(v)
      v = $1 if /\A(.+?)\#.*\z/ =~ v	# remove comment
      v = v.strip
      case v
      when 'true';	return true
      when 'false';	return false
      when 'nil';	return nil
      when /\A\d+\z/;	return v.to_i
      # Only numbers, * and spaces are allowable.
      # Eval is not evil in this context.
      when /\A[\d\ \*]+\z/;	return eval(v)
      end
      v.gsub!('$BASEDIR') { BASEDIR }
      return v
    end

    def self.make_accessor(klass, config, debug=false)
      config.each_key {|k|
	if ! klass.method_defined?(k)
	  klass.class_eval "
            def #{k}
              return @config[:#{k}]
            end
	  "
	end
      }
    end

    def self.parse_args(myprog, args)
      config = {}
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
      return config
    end
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  $test = true
end

if defined?($test) && $test
  class TestConfig < Test::Unit::TestCase
    def test_class_method
      c = Qwik::Config

      # test_parse_config
      ok_eq({}, c.parse_config('::'))
      ok_eq({}, c.parse_config('::v'))
      ok_eq({:k=>''}, c.parse_config(':k:'))
      ok_eq({:k=>''}, c.parse_config(':k:	'))

      ok_eq({:k=>'v'}, c.parse_config(':k:v'))
      ok_eq({:k=>'v:v'}, c.parse_config(':k:v:v'))
      ok_eq({:k=>'v'}, c.parse_config("\#c\n:k:v"))
      ok_eq({:k=>'v'}, c.parse_config(':k:v#comment'))
      ok_eq({:k=>'v'}, c.parse_config(':k:v #comment'))

      ok_eq({:k=>true}, c.parse_config(':k:true'))
      ok_eq({:k=>false}, c.parse_config(':k:false'))
      ok_eq({:k=>nil}, c.parse_config(':k:nil'))

      ok_eq({:k=>1}, c.parse_config(':k:1'))
      ok_eq({:k=>4}, c.parse_config(':k:2*2'))
      ok_eq({:k=>4}, c.parse_config(':k:2 * 2'))
      ok_eq({:k=>4}, c.parse_config(':k:	2 * 2'))
      ok_eq({:k=>'1.1'}, c.parse_config(':k:1.1'))

      ok_eq({:k=>Qwik::Config::BASEDIR}, c.parse_config(':k:$BASEDIR'))

      # test_parse_args
      ok_eq({:debug=>true}, c.parse_args('myprog', ['-d']))
    end

    def test_all
      # test_new
      config = Qwik::Config.new
      ok_eq(false, config.debug)
      ok_eq(false, config.test)
      config[:debug] = true
      ok_eq(true, config.debug)
    end
  end
end
