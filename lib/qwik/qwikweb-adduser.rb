# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

=begin
$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/config'
require 'qwik/farm'

module Qwik
  class AddUser
    def self.main(argv)
      if argv.length != 2
	puts "Usage: qwikweb-adduser [sitename] [mail address]"
	exit
      end

      config = Config.new
      memory = ServerMemory.new(config)
      farm = Farm.new(config, memory)
      sitename = argv.shift
      mail = argv.shift
      begin
	site = farm.get_site(sitename)
	site.member.add(mail)
      rescue
	puts 'Error: The site does not exist.'
	exit 1
      end
      puts 'Adding a new user completed.'
    end
  end
end
=end
