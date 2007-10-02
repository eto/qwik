# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

=begin
$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/config'
require 'qwik/farm'

module Qwik
  class MakeSite
    def self.main(argv)
      return usage if argv.length != 2

      config = Config.new
      memory = ServerMemory.new(config)
      farm = Farm.new(config, memory)

      sitename = argv.shift
      mail = argv.shift
      return usage if sitename.nil? || sitename.empty?
      return usage if mail.nil? || mail.empty?

      begin
	site = farm.make_site(sitename)
	site = farm.get_site(sitename)
	site.member.add(mail)
      rescue => e
	puts 'Error: The site is already exist.'
	exit 1
      end
      puts 'Creating a new site completed.'
    end

    def self.usage
      puts 'usage: qwikweb-makesite [sitename] [your mail address]'
      exit
    end
  end
end
=end
