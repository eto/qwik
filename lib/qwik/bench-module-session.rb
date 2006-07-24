# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

require 'benchmark'

module BenchmarkModule
  def benchmark
    result = nil
    Benchmark.bm {|x|
      x.report { 
	result = yield 
      }
    }
    return result
  end

  module_function :benchmark
end
