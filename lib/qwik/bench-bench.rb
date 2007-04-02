# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/bench-module-session'

class BenchBenchmark
  def self.bench_itself
    puts Benchmark.measure { 'a'*1_000_000 }

    n = 50_000
    Benchmark.bm(7) {|x|
      x.report { for i in 1..n; a = '1'; end }
      x.report { n.times do   ; a = '1'; end }
      x.report { 1.upto(n) do ; a = '1'; end }
    }
  end

  def self.bench_benchmark
    BenchmarkModule::benchmark {
      'a'*10_000_000 
    }
  end
end

#BenchBenchmark::bench_itself
BenchBenchmark::bench_benchmark
