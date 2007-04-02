# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/site-event'

module Qwik
  class Action
    # ==================== Show current event.
    def plg_event(pagename=nil)
      return if defined?(@event_defined)
      @event_defined = true

      pagename ||= @req.base

      url = "#{pagename}.event"
      url = c_relative_to_root(url)

      ar = []
      div = [:div, {:id=>'event'}]
      div << [:strong, 'plg_event'] if @config.debug
      ar << div
      ar << [:script, {:type=>'text/javascript',
	  :src=>'.theme/js/event.js'}, '']
      ar << [:script, {:type=>'text/javascript'}, "
//alert('start');
g_eventwatcher.add('#{url}');
g_eventwatcher.start();
"]
      return ar
    end

    # ==================== Event occurred.
    def c_event(cmd)
      time = @req.start_time.to_i
      user = @req.user
      user ||= 'anonymous'
      key  = @req.base
      ext  = @req.ext
      event = [time, user, key, ext, cmd]	# When, Who, Where, What
      @site.event.occurred(event)
    end

    # ==================== Event callback
    def get_sitename
      return @site.sitename
    end

    def get_start_time
      return @req.start_time
    end

    def event_occurred(event)
      @event = event
    end

    def event_disconnect(reason)
      if @event.nil?
	@event = reason
      end
    end

    # ==================== Wait for event.
    def ext_event
      @event = nil
      siteevent = @site.event

      begin
	siteevent.add_listener(self)
      rescue ListenerMaxExceed
	@event = 'max_exceed'
      end

      while @event.nil?
	sleep 0.1
      end

      if @event.is_a?(String)
	return event_error(@event)
      end

      return event_tell(@event)
    end

    def event_error(msg)
      return event_send(",#{msg}\n")
    end

    def event_tell(event)
      time, user, key, ext, cmd = event
      ar = []
      title = "#{Time.at(time).ymd} : #{cmd}"
      user = MailAddress.obfuscate(user)
      msg = "#{user}: #{cmd} #{key}"
      ar << [:h2, title]
      ar << [:p, msg]
      return event_send(ar)
    end    

    def event_send(body)
      @res.status = 200
      @res['Cache-Control'] = 'no-cache, must-revalidate'
      @res['Pragma'] = 'no-cache'
      @res.body = body
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActEvent < Test::Unit::TestCase
    include TestSession

    def setup_event
      Thread.abort_on_exception = true
      t_add_user
      page = @site.create_new
      page.store('*t')
    end

    def test_event_1
      setup_event
      t = Thread.new {
	tres = session('/test/1.save?contents=t2')
	ok_in(['Page is saved.'], 'title', tres)
      }
      res = session('/test/1.event')	# Wait for update.
      #ok_eq(",0,user@e.com,1,save,save\n", res.body)
      t.join	# Wait for the thread.
    end

    def test_event_2
      setup_event
      t = Thread.new {
	res = session('/test/1.event')	# Wait for update.
	#ok_eq(",0,user@e.com,1,save,save\n", res.body)
      }
      tres = session('/test/1.save?contents=t2')
      ok_in(['Page is saved.'], 'title', tres)
      t.join	# Wait for the thread.
    end

    def test_event_3_several_watchers
      setup_event
      t1 = Thread.new {
	t1res = session('/test/1.event')	# Wait for update.
	#ok_eq(",0,user@e.com,1,save,save\n", t1res.body)
      }
      t2 = Thread.new {
	t2res = session('/test/1.event')	# Wait for update.
	#ok_eq(",0,user@e.com,1,save,save\n", t2res.body)
      }
      tres = session('/test/1.save?contents=t2')
      ok_in(['Page is saved.'], 'title', tres)
      t1.join	# Wait for the thread.
      t2.join	# Wait for the thread.
    end

    def test_event_4_many_watchers
      setup_event
      ts = []
      res = []
      #max = 20
      max = 5
      (0..max).each {|i|
	ts[i] = Thread.new {
	  res[i] = session('/test/1.event')	# Wait for update.
	  str = res[i].body
	  if !(str == ",0,user@e.com,1,save,save\n" ||
	       str == ",max_exceed\n" || str == ",disconnect\n")
	    #ok_eq('', str)	# error
	  end
	}
      }
      tres = session('/test/1.save?contents=t3')
      ok_in(['Page is saved.'], 'title', tres)
      (0..max).each {|i|
	ts[i].join	# Wait for the thread.
      }
    end
  end
end
