#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '..' unless $LOAD_PATH.include?('..')
require 'qwik/config'
require 'qwik/password'

module Qwik
  class IncrementGeneration
    def self.main(argv)
      if argv.length == 0
	puts 'usage: qwikweb-incgen [mailaddress]'
	exit
      end

      config = Config.new
      gen = PasswordGenerator.new(config)
      mail = argv.shift
      g = gen.generation_inc(mail)
      puts 'mail: '+mail
      puts 'generation: '+g.to_s
      puts 'increment generation done.'
    end
  end
end