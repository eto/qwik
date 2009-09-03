# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/config'
require 'qwik/site-report'

module Qwik
  class PeriodicThread
    def initialize(config, memory, time)
      @config, @memory = config, memory
      @logger = @memory[:logger]
      @time = time
    end

    def start
      loop {
	begin
	  process
	rescue Exception => e
	  pp e
	end
	sleep @time
      }
    end

    def process # abstract method
    end
  end

  class SweepThread < PeriodicThread
    def initialize(config, memory)
      super(config, memory, 60*60) # 1hour
    end

    def process
      sleep 30*60 # 30min
      farm = @memory.farm
      farm.sweep
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestPeriodic < Test::Unit::TestCase
    include TestSession

    def test_dummy
    end

    def nu_test_all
      @periodic = Qwik::Periodic.new(@config, @memory)
      # @periodic.time = 1 # for test, do it on every second.
      @periodic.time = 1000 # for test, do it on every second.

      t = Thread.new { @periodic.start }
      t.abort_on_exception = true

      @farm = @memory.farm
      @site = @farm.get_site('test')
      ok_eq(false, @site.inactive?)
      page = @site['_SiteConfig']
      page.store(':ml_life_time:0') # die soon.

      sleep 2 # will run sweep

      @site = @farm.get_site('test')
      ok_eq(nil, @site)

      t.kill
    end
  end
end
