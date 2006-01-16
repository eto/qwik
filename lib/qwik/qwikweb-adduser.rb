$LOAD_PATH << '../../lib' unless $LOAD_PATH.include?('../../lib')
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
      puts 'Adding a new uesr completed.'
    end
  end
end
