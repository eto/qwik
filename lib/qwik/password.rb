# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/util-pathname'
require 'qwik/util-string'
require 'qwik/server-memory'
require 'openssl'
require 'thread'

module Qwik
  class ServerMemory
    # password
    def passgen
      @passgen = PasswordGenerator.new(@config) unless defined? @passgen
      return @passgen
    end

    def passdb
      @passdb = PasswordDB.new(@config) unless defined? @passdb
      return @passdb
    end
  end

  # Obsolete. Only use for migration.
  class PasswordGenerator
    DEFAULT_SITE_PASSWORD = ''
    PASSWORD_FILE = 'password.txt'
    GENERATION_FILE = 'generation.txt'

    def initialize(config)
      etc_path = config.etc_dir.path
      @site_password_file = etc_path + PASSWORD_FILE
      @site_password = DEFAULT_SITE_PASSWORD
      if @site_password_file.exist?
	@site_password = @site_password_file.read.to_s.chomp
      end
      @generation_file = etc_path + GENERATION_FILE
      @generation = PasswordGenerator.generation_get(@generation_file)
    end

    def generate(user)
      generation = 0
      generation = @generation[user] if @generation[user]
      return PasswordGenerator.generate_md5hex(@site_password,
					       user, generation).hex.to_s[-8, 8]
    end

    def generate_hex(user)
      generation = 0
      generation = @generation[user] if @generation[user]
      return PasswordGenerator.generate_md5hex(@site_password,
					       user, generation).upcase[0, 8]
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
      return gen
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

  class PasswordDB
    PASSWORD_DIR = "password_dir"

    def initialize(config)
      @config = config
      @password_dir = @config.etc_dir.path + PASSWORD_DIR
      @password_dir.check_directory
      @barrier = Hash.new { |hash, key| hash[key] = Mutex.new }
    end

    def generate(user)
      new_password = generate_random_string
      store(user, new_password)
      return new_password
    end

    def match?(user, pass)
      exist?(user) and fetch(user) == pass
    end

    def exist?(user)
      if fetch(user)
	true
      else
	false
      end
    end

    def store(user, pass)
      transaction(user) {
	temp_path = @password_dir + make_temp_name
	temp_path.write(pass)
	temp_path.rename(data_path(user))
      }
    end

    def fetch(user)
      return nil if user.nil?
      transaction(user) {
	path = data_path(user)
	if path.exist?
	  return path.read
	else
	  return nil
	end
      }
    end

    # Method for test
    def remove_all
      @password_dir.children.each do |path|
	path.rmtree
      end
    end

    def make_temp_name(prefix=".tmp")
      pid = Process.pid.to_s
      tid = Thread.current.object_id.to_s
      now = Time.now
      time = now.to_i.to_s
      usec = now.usec.to_s
      return prefix + pid + tid + time + usec
    end

    # FIXME: It depends on specific architecture.
    MAX_FILENAME_LENGTH = 255
    def data_path(user)
      encoded = encode(user)
      encoded = encoded[0, MAX_FILENAME_LENGTH] # for stablity, cut very very long name.
      prefix = encoded[0, 2]
      subdir_path = @password_dir + prefix
      subdir_path.check_directory
      return subdir_path + encoded
    end

    # Base64 encode, then substitute chars unsuitable for filesystem.
    def encode(s)
      [s].pack("m").gsub("+","!").gsub("/","-").gsub("\n","_")
    end

    def decode(s)
      s.gsub("!","+").gsub("-","/").gsub("_","\n").unpack("m*")[0]
    end

    def transaction(str)
      @barrier[str].synchronize {
	yield
      }
    end

    def generate_random_string
      return [OpenSSL::Random.random_bytes(9)].pack("m").chomp
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
      generation_file = config.etc_dir.path +
	Qwik::PasswordGenerator::GENERATION_FILE
      generation_file.write('')

      gen = Qwik::PasswordGenerator.new(config)

      # test_generate
      assert_equal '95988593', gen.generate('user@e.com')

      # test_generate_hex
      assert_equal '68246775', gen.generate_hex('user@e.com')

      # test_match?
      assert_equal true,  gen.match?('user@e.com', '95988593')
      # generation 0
      assert_equal false, gen.match?('user@e.com', '64006086')
      assert_equal true,  gen.match?('user@e.com', '68246775')

      # test_generation_inc
      gen.generation_inc('user@e.com')
      assert_equal ",user@e.com,1\n", generation_file.read
      assert_equal false, gen.match?('user@e.com', '95988593')	# Changed.
      assert_equal '85127862', gen.generate('user@e.com')	# generation 1
      assert_equal true,  gen.match?('user@e.com', '85127862')

      # test_generation_inc, again
      gen.generation_inc('user@e.com')
      assert_equal ",user@e.com,1\n,user@e.com,2\n", generation_file.read
      assert_equal '78735937', gen.generate('user@e.com')

      # test_store
      gen.generation_store
      assert_equal ",user@e.com,2\n", generation_file.read

      # test_another_user
      gen.generation_inc('another@e.com')
      assert_equal ",user@e.com,2\n,another@e.com,1\n", generation_file.read
      gen.generation_store
      assert_equal ",another@e.com,1\n,user@e.com,2\n", generation_file.read

      # teardown
      generation_file.unlink
    end

    def test_password_file
      config = Qwik::Config.new
      config.update Qwik::Config::DebugConfig
      config.update Qwik::Config::TestConfig
      password_file = config.etc_dir.path+Qwik::PasswordGenerator::PASSWORD_FILE
      password_file.write('')

      gen = Qwik::PasswordGenerator.new(config)
      assert_equal '95988593', gen.generate('user@e.com')

      password_file.write('t')
      gen = Qwik::PasswordGenerator.new(config)
      assert_equal '57318391', gen.generate('user@e.com')

      # teardown
      password_file.unlink
    end
  end

  class TestPasswordDB < Test::Unit::TestCase
    def setup
      config = Qwik::Config.new
      config.update Qwik::Config::DebugConfig
      config.update Qwik::Config::TestConfig
      @pdb = Qwik::PasswordDB.new(config)
    end

    def teardown
      @pdb.remove_all
    end

    def test_all
      input = "guest@qwik"

      expected = false
      actual = @pdb.exist?(input)
      ok_eq(expected, actual)

      output = @pdb.generate(input)

      expected = true
      actual = @pdb.exist?(input)
      ok_eq(expected, actual)

      expected = output
      actual = @pdb.fetch(input)
      ok_eq(expected, actual)

      expected = true
      actual = @pdb.match?(input, output)
      ok_eq(expected, actual)
    end

    def test_parallel
      t = []
      100.times { |i|
	t[i] = Thread.new {
	  sleep rand
	  user = "user#{i}@example.com"
	  pass = @pdb.generate(user)
	  Thread.pass
	  foo = @pdb.fetch(user)
	  ok_eq(true, @pdb.match?(user, pass), "match user and password")
	  ok_eq(foo, pass, "fetch right password.")
	}
      }
      # wait threads before teardown
      t.each { |thread| thread.join }
    end

    def test_codec
      ["foo@example.com", "user@e.com", "test@example.com", 'gu@e.com'].each do |addr|
	expected = addr
	actual = @pdb.decode(@pdb.encode(addr))
	ok_eq(expected, actual)
      end
    end

    def test_data_path
      expected = Pathname.new(".test/etc/password_dir/Zm/Zm9vQGV4YW1wbGUuY29t_")
      input = "foo@example.com"
      actual = @pdb.data_path(input)
      ok_eq(expected, actual)
    end

    def test_make_temp_name_uniqueness
      threads = []
      names = []
      100.times {
	threads << Thread.new {
	  names << @pdb.make_temp_name
	}
      }
      threads.each { |t| t.join }
      names.each do |name|
	arr = names.find_all{|s| s == name }
	assert arr.size == 1
      end
    end

    def test_not_exist
      user = "nobody@example.com"
      expected = nil
      actual = @pdb.fetch(user)
      ok_eq(expected, actual)
    end

  end
end
