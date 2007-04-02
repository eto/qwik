# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/config'
require 'qwik/ml-logger'
require 'qwik/ml-catalog-factory'
require 'qwik/util-safe'

module QuickML
  class ServerMemory
    def self.init_logger(memory, config)
      ml_log_file = (config[:log_dir].path + Logger::ML_LOG_FILE).to_s
      memory[:logger] = Logger.new(ml_log_file, config[:verbose_mode])
    end

    def self.init_mutex(memory)
      memory[:ml_mutexes] = Hash.new
    end

    def self.ml_mutex(memory, address)
      hash = memory[:ml_mutexes]
      return hash.fetch(address) {|x| hash[x] = Mutex.new }
    end

    def self.init_catalog(memory)
      memory[:catalog] = nil
      if memory[:message_catalog]
	cf = CatalogFactory.new
	cf.load_all_here('catalog-ml-??.rb')
	memory[:catalog] = cf.get_catalog('ja')
      end
    end
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  $test = true
end

if defined?($test) && $test
  class TestMLMemory < Test::Unit::TestCase
    def test_all
      c = QuickML::ServerMemory

      # test_init_logger
      memory = {}
      config = {:log_dir=>'.'}
      c.init_logger(memory, config)
      assert_instance_of(QuickML::Logger, memory[:logger])

      # test_init_mutex
      memory = {}
      c.init_mutex(memory)
      eq({:ml_mutexes=>{}}, memory)

      # test_init_catalog
      memory = {:message_catalog=>'something'}
      c.init_catalog(memory)
      assert_instance_of(Hash, memory[:catalog])
    end
  end
end
