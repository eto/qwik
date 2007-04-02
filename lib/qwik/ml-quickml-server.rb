#
# Copyright (C) 2002-2004 Satoru Takabayashi <satoru@namazu.org> 
# Copyright (C) 2003-2006 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$KCODE = 's'	# FIXME: Remove $KCODE

require 'fileutils'

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/config'
require 'qwik/ml-memory'
require 'qwik/ml-server'
require 'qwik/ml-sweeper'

$ml_debug = false
# $ml_debug = true

module QuickML
  class QuickMLServer
    def self.main(args)
      server = QuickMLServer.new

      config = Qwik::Config.new
      Qwik::Config.load_args_and_config(config, $0, args)
      config.update({:debug => true, :verbose_mode => true}) if $ml_debug

      ServerMemory.init_logger(config, config)
      ServerMemory.init_mutex(config)
      ServerMemory.init_catalog(config)

      server.run(config)
    end

    def initialize
      # Do nothing.
    end

    def run (config)
      QuickMLServer.check_directory(config.sites_dir)

      if ! config.debug
        QuickMLServer.be_daemon
        QuickMLServer.be_secure(config)
      end

      server  = Server.new(config)
      sweeper = Sweeper.new(config)
      trap(:TERM) { server.shutdown; sweeper.shutdown }
      trap(:INT)  { server.shutdown; sweeper.shutdown }
      if Signal.list.key?("HUP")
        trap(:HUP)  { config.logger.reopen }
      end
      sweeper_thread = Thread.new { sweeper.start }
      sweeper_thread.abort_on_exception = true

      if config.debug
        require 'qwik/autoreload'
	AutoReload.start(1, true, 'ML')	# auto reload every sec.
      end

      server.start
    end

    private

    def self.check_directory(dir)
      error("#{dir}: No such directory") if ! File.directory?(dir) 
      error("#{dir}: is not writable")   if ! File.writable?(dir) 
    end

    def self.error (msg)
      STDERR.puts "#{$0}: #{msg}"
      exit(1)
    end

    def self.be_daemon
      exit!(0) if fork
      Process::setsid
      exit!(0) if fork
      Dir::chdir('/')
      File::umask(022)
      STDIN.reopen('/dev/null',  'r+')
      STDOUT.reopen('/dev/null', 'r+')
      STDERR.reopen('/dev/null', 'r+')
    end

    def self.be_secure(config)
      return unless Process.uid == 0
      uid = Etc::getpwnam(config.user).uid 
      gid = Etc::getgrnam(config.group).gid
      FileUtils.touch(config.ml_pid_file)
      ml_log_file = (config[:log_dir].path + Logger::ML_LOG_FILE).to_s
      FileUtils.touch(ml_log_file)
      File.chown(uid, gid, config.sites_dir)
      File.chown(uid, gid, config.ml_pid_file)
      File.chown(uid, gid, ml_log_file)
      Process.uid  = uid
      Process.gid  = gid
      Process.euid = uid
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-module-ml'
  $test = true
end

if defined?($test) && $test
  class TestMLQuickMLServer < Test::Unit::TestCase
    def test_all
      # Just create it.
      qml_server = QuickML::QuickMLServer.new
    end
  end
end
