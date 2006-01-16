#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '../../lib' unless $LOAD_PATH.include?('../../lib')
require 'qwik/config'
require 'qwik/loadlib'
require 'qwik/server'

module Qwik
  class QwikWebServer
    def self.main(args)
      File.umask(0)

      config = Config.new
      Config.load_args_and_config(config, $0, args)

      # Load all libraries here.
      init_load_lib(config.lib_dir)

      server = Server.new(config)
      server.start
    end

    def self.init_load_lib(dir)
      loadlib = LoadLibrary.new
      loadlib.glob(dir, 'qwik/act-*.rb')
    end
  end
end

if $0 == __FILE__
  args = ARGV
  args << '-d'	# force debug mode
  Qwik::QwikWebServer.main(args)
end
