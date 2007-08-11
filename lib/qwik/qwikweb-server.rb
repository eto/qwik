# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/config'
require 'qwik/loadlib'
require 'qwik/server'

module Qwik
  class QwikWebServer
    def self.main(args)
      return if defined?($qwikweb_server_running) && $qwikweb_server_running

      File.umask(0)

      config = Config.new
      Config.load_args_and_config(config, $0, args)

      # Load all actions here.
      LoadLibrary.load_libs_here('qwik/act-*.rb')
      LoadLibrary.load_libs_here('qwik/plugin/act-*.rb')

      if config[:server_type] == 'webrick'
	server = Server.new(config)
      elsif config[:server_type] == 'mongrel'
	require 'qwik/mongrel-server'
	server = MongrelServer.new(config)
      else
	puts 'Error'
	exit
      end

      $qwikweb_server_running = true
      server.start
    end
  end
end

if $0 == __FILE__
  args = ARGV
  args << '-d'	# force debug mode
  Qwik::QwikWebServer.main(args)
end
