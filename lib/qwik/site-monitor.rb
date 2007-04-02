# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

require 'monitor'

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Site
    def sitemonitor
      @sitemonitor = SiteMonitor.new(@config, self) unless defined? @sitemonitor
      return @sitemonitor
    end
  end

  class SiteMonitor
    MAX_LISTENER = 5

    def initialize(config, site)
      @config = config
      @site = site

      @buf = []
      @buf.extend(MonitorMixin)
      @empty_cond = @buf.new_cond

      @listener = []
    end

    def shout(event)
      @buf.synchronize {
	@buf.push(event)
	@empty_cond.broadcast
      }
    end

    def listen(action)
      len = @listener.length
#      if MAX_LISTENER < len
#	return
#      end

      @listener << action

      index = @buf.length
      loop {
	@buf.synchronize {
	  @empty_cond.wait_while {
	    @buf[index].nil?
	  }
	  ev = @buf[index]
	  index += 1
	  yield(ev)
	}
      }
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestMonitor < Test::Unit::TestCase
    include TestSession

    def listen_one(monitor)
      monitor.listen(nil) {|ev|
	return ev
      }
    end

    def test_monitors
      monitor = @site.sitemonitor

      t1 = Thread.new {
	ev = listen_one(monitor)
	ok_eq(1, ev)
      }

      t2 = Thread.new {
	ev = listen_one(monitor)
	ok_eq(1, ev)
      }

      sleep 0.01
      monitor.shout(1)

      t1.join
      t2.join
    end

  end
end
