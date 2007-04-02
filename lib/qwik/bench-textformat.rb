# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/bench-module-session'
require 'qwik/test-module-session'
require 'qwik/server'

class BenchTextFormat
  include TestSession
  include BenchmarkModule

  def bench_all
    n = 10
    #n = 100
    #n = 1000
    t_add_user
    benchmark {
      n.times {
	session('/test/TextFormat.html')
	dummy_str = @res.setback_body(@res.body)
      }
    }
  end
end

b = BenchTextFormat.new
b.setup
b.bench_all
b.teardown
