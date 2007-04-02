# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class ListenerMaxExceed < StandardError; end

  class Site
    def event
      @event = SiteEvent.new(@config, @memory, self) unless defined? @event
      @event
    end
  end

  class ServerMemory
    def listener
      @listener = EventListener.new(@config) unless defined? @listener
      @listener
    end
  end

  class EventListener
    MAX_LISTENER = 5
    TIMEOUT = 60*60

    def initialize(config)
      @config = config
      @listener = []
    end

    def add_listener(action)
      check_timeout
      if MAX_LISTENER <= @listener.length
	kickout(@listener[0], 'max_exceed')
	raise ListenerMaxExceed		# failed to add
      end
      @listener << action
    end

    def kickout(action, reason)
      @listener.delete(action)
      action.event_disconnect(reason)
    end

    def success(action)
      @listener.delete(action)
    end

    def each_listener(target_sitename)
      check_timeout
      @listener.each {|action|
	if action.get_sitename == target_sitename
	  yield(action)
	end
      }
    end

    def check_timeout
      now = Time.now
      now = Time.at(0) if $test
      check_timeout_internal(@listener, now)
    end

    def check_timeout_internal(listener, now)
      listener.each {|action|
	time = action.get_start_time
	if TIMEOUT < (now - time)
	  kickout(action, 'timeout')
	end
      }
    end
  end

  class SiteEvent
    def initialize(config, memory, site)
      @config = config
      @memory = memory
      @site = site
      # @sitename = @site.sitename
      @listener = memory.listener
    end

    def add_listener(action)
      #return @listener.add_listener(@sitename, action)
      return @listener.add_listener(action)
    end

    def occurred(event)
      sitename = @site.sitename

      kickout = []

      @listener.each_listener(sitename) {|listener|
	listener.event_occurred(event)
	kickout << listener
      }

      kickout.each {|listener|
	@listener.success(listener)
      }
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class MockAction
    def initialize
      @event = nil
    end
    attr_reader :event

    def get_start_time
      #return Time.at(0)
      return Time.now
    end

    def get_sitename
      return 'test'
    end

    def event_occurred(event)
      @event = event
    end

    def event_disconnect(reason)
      if @event.nil?
	@event = reason
      end
    end
  end

  class TestSiteEvent < Test::Unit::TestCase
    include TestSession

    def test_all
      mock = MockAction.new

      event = @site.event

      # listener
      event.add_listener(mock)
      t = Thread.new {
	while mock.event.nil?
	  sleep 0.1
	end
	ok_eq(1, mock.event)
      }

      # producer
      event.occurred(1)

      t.join
    end
  end
end
