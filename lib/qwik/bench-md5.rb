# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

require 'md5'
require 'benchmark'

Benchmark.bm {|x|
  x.report { 
    100000.times {
      t = MD5.hexdigest('t')
    }
  }
}
