#
# Copyright (C) 2003-2006 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'
require 'qwik/util-pathname'
require 'qwik/util-string'
require 'qwik/server-memory'

module Qwik
  class ServerMemory
    # password
    def passgen
      @passgen = PasswordGenerator.new(@config) unless defined? @passgen
      return @passgen
    end
  end

  class PasswordGenerator
    DEFAULT_SITE_PASSWORD = ''

    def initialize(config)
      init_site_password(config)
      init_generation(config)
    end

    def generate(user)
      generation = 0
      generation = @generation[user] if @generation[user]
      return generate_md5hex(user, generation).hex.to_s[-8, 8]
    end

    def generate_hex(user)
      generation = 0
      generation = @generation[user] if @generation[user]
      return generate_md5hex(user, generation).upcase[0, 8]
    end

    def match?(user, pass)
      return false if user.nil? || user.empty?
      return false if pass.nil? || pass.empty?

      pa = generate(user)
      return true if pa == pass
      pa = generate_hex(user)
      return true if pa == pass
      return true if pa == pass.upcase
      false
    end

    def generation_inc(user)
      generation_get
      generation = 0
      generation = @generation[user] if @generation[user]
      generation += 1 # Increment the generation.
      generation_add(user, generation)
      generation_get
    end

    private

    def init_site_password(config)
      @site_password_file = config.pass_file.path
      @site_password = if @site_password_file.exist?
			 get_site_password(@site_password_file)
		       else
			 DEFAULT_SITE_PASSWORD
		       end
    end

    def get_site_password(file)
      return file.read.to_s.chomp
    end

    def init_generation(config)
      @generation_file = config.generation_file.path
      generation_get
    end

    def generation_get
      if ! @generation_file.exist?
	@generation_file.write('')
      end
      str = @generation_file.read
      @generation = {}
      str.each {|line|
	next unless line[0] == ?,
	dummy, user, gen = line.chomp.split(',')
	@generation[user] = gen.to_i
      }
    end

    def generate_md5hex(user, generation=0)
      return "#{user}:#{@site_password}:#{generation}".md5hex
    end

    def generation_store
      @generation_file.open('ab') {|f|
	@generation.each {|user, generation|
	  f.puts(','+user+','+generation.to_s)
	}
      }
    end

    def generation_add(user, generation)
      @generation_file.open('ab') {|f|
	f.puts(','+user+','+generation.to_s)
      }
    end
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  require 'qwik/config'
  $test = true
end

if defined?($test) && $test
  class TestPasswordGenerator < Test::Unit::TestCase
    def test_all
      config = Qwik::Config.new
      config[:pass_file] = 'password.txt'
      config[:generation_file] = 'generation.txt'
      gen_path = config.generation_file.path
      gen_path.write('')

      gen = Qwik::PasswordGenerator.new(config)

      # test_generate
      ok_eq('95988593', gen.generate('user@e.com'))

      # test_generate_hex
      ok_eq('68246775', gen.generate_hex('user@e.com'))

      # test_match?
      ok_eq(true,  gen.match?('user@e.com', '95988593'))
      # generation 0
      ok_eq(false, gen.match?('user@e.com', '64006086'))
      ok_eq(true,  gen.match?('user@e.com', '68246775'))

      # Increment generation
      gen_path.write(",user@e.com,1\n")
      Qwik::PasswordGenerator.instance_eval {
	public :generation_get
      }
      gen.generation_get

      # test_match_with_generation
      ok_eq(false,  gen.match?('user@e.com', '95988593'))
      # generation 1
      ok_eq('85127862', gen.generate('user@e.com'))
      ok_eq(true, gen.match?('user@e.com', '85127862'))

      # test_generation_inc
      gen.generation_inc('user@e.com')
      ok_eq(",user@e.com,1\n,user@e.com,2\n", gen_path.read)
      ok_eq('78735937', gen.generate('user@e.com'))

      gen_path.unlink
    end
  end
end
