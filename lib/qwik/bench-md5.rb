require 'md5'
require 'benchmark'

Benchmark.bm {|x|
  x.report { 
    100000.times {
      t = MD5.hexdigest('t')
    }
  }
}
