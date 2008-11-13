# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

=begin
$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/config'
require 'qwik/password'

module Qwik
  class ShowPassword
    def self.main(argv)
      if argv.length == 0
	puts 'usage: qwikweb-showpassword [mailaddress]'
	exit
      end

      config = Config.new
      gen = PasswordGenerator.new(config)
      mail = argv.shift
      puts 'mail: '+mail
      puts 'pass: '+gen.generate(mail)
    end
  end
end
=end
