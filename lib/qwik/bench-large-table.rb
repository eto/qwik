# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/bench-module-session'
require 'qwik/test-module-session'
require 'qwik/server'

class BenchLargeTable
  include TestSession
  include BenchmarkModule

  def self.run
    self.new.main
  end

  def main
    setup
    bench_all
    teardown
  end

  def generate_large_table(table_line_num)
    str = ''
    table_line_num.times {|n|
      str << "|#{n}|1|2|3|4|5|6|7|8|9|0\n"
    }
    return str
  end

  def bench_all
    t_add_user

    table_line_num = 10
    table_line_num = 100
    table_line_num = 1000
    #table_line_num = 10000

# 1000 times.

# Regexp version.
#  2.700000   0.660000   3.360000 (  3.358553)
#  2.690000   0.650000   3.340000 (  3.326321)
#  2.740000   0.620000   3.360000 (  3.354227)

# strscan version.
#  2.730000   0.430000   3.160000 (  3.145743)
#  2.480000   0.670000   3.150000 (  3.157546)
#  2.590000   0.580000   3.170000 (  3.176562)

    page = @site.create_new
    page.store(generate_large_table(table_line_num))

    benchmark {
      res = session('/test/1.html')
      dummy_str = res.setback_body(res.body)
    }
  end
end

BenchLargeTable.run
