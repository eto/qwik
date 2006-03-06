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
    PASSWORD_FILE = 'password.txt'
    GENERATION_FILE = 'generation.txt'

    def initialize(config)
      @site_password_file = config.etc_dir.path+PASSWORD_FILE
      #qp @site_password_file.to_s
      @site_password = DEFAULT_SITE_PASSWORD
      if @site_password_file.exist?
	@site_password = @site_password_file.read.to_s.chomp
      end
      @generation_file = config.etc_dir.path+GENERATION_FILE
      @generation = PasswordGenerator.generation_get(@generation_file)
    end

    def generate(user)
      generation = 0
      generation = @generation[user] if @generation[user]
      return PasswordGenerator.generate_md5hex(@site_password, user, generation).hex.to_s[-8, 8]
    end

    def generate_hex(user)
      generation = 0
      generation = @generation[user] if @generation[user]
      return PasswordGenerator.generate_md5hex(@site_password, user, generation).upcase[0, 8]
    end

    def match?(user, pass)
      return false if user.nil? || user.empty?
      return false if pass.nil? || pass.empty?

      pa = generate(user)
      return true if pa == pass
      pa = generate_hex(user)
      return true if pa == pass
      return true if pa == pass.upcase
      return false
    end

    def generation_inc(user)
      generation = PasswordGenerator.generation_get(@generation_file)
      gen = 0
      gen = generation[user] if generation[user]
      gen += 1		# Increment the generation of the user.
      PasswordGenerator.generation_add(@generation_file, user, gen)
      @generation = PasswordGenerator.generation_get(@generation_file)
    end

    def generation_store
      PasswordGenerator.generation_store(@generation_file, @generation)
      return nil
    end

    private

    def self.generation_get(file)
      file.write('') if ! file.exist?
      str = file.read
      generation = {}
      str.each {|line|
	next unless line[0] == ?,
	dummy, user, gen = line.chomp.split(',')
	generation[user] = gen.to_i
      }
      return generation
    end

    def self.generate_md5hex(site_password, user, generation=0)
      return "#{user}:#{site_password}:#{generation}".md5hex
    end

    def self.generation_add(file, user, gen)
      file.add(",#{user},#{gen}\n")
    end

    def self.generation_store(file, generation)
      str = generation.map {|user, gen|
	[user, gen]
      }.sort.map {|user, gen|
	",#{user},#{gen}\n"
      }.join
      file.write(str)
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
      config.update Qwik::Config::DebugConfig
      config.update Qwik::Config::TestConfig
      gen_path = config.etc_dir.path+Qwik::PasswordGenerator::GENERATION_FILE
      gen_path.write('')

      gen = Qwik::PasswordGenerator.new(config)

      # test_generate
      eq '95988593', gen.generate('user@e.com')

      # test_generate_hex
      eq '68246775', gen.generate_hex('user@e.com')

      # test_match?
      eq true,  gen.match?('user@e.com', '95988593')
      # generation 0
      eq false, gen.match?('user@e.com', '64006086')
      eq true,  gen.match?('user@e.com', '68246775')

      # test_generation_inc
      gen.generation_inc('user@e.com')
      eq ",user@e.com,1\n", gen_path.read
      eq false, gen.match?('user@e.com', '95988593')	# Changed.
      eq '85127862', gen.generate('user@e.com')		# For generation 1
      eq true,  gen.match?('user@e.com', '85127862')

      # test_generation_inc, again
      gen.generation_inc('user@e.com')
      eq ",user@e.com,1\n,user@e.com,2\n", gen_path.read
      eq '78735937', gen.generate('user@e.com')

      # test_store
      gen.generation_store
      eq ",user@e.com,2\n", gen_path.read

      # test_another_user
      gen.generation_inc('another@e.com')
      eq ",user@e.com,2\n,another@e.com,1\n", gen_path.read
      gen.generation_store
      eq ",another@e.com,1\n,user@e.com,2\n", gen_path.read

      gen_path.unlink
    end
  end
end
