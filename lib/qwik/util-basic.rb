#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '../../lib' unless $LOAD_PATH.include?('../../lib')
require 'qwik/util-escape'

class Hash
  def to_query_string
    ar = []
    self.each {|k, v|
      if k && v
	ar << "#{k.to_s.escape}=#{v.to_s.escape}"
      end
    }
    return ar.sort.join('&')
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  $test = true
end

if defined?($test) && $test
  class TestUtilBasic < Test::Unit::TestCase
    def test_all
      # test_hash_to_query_string
      eq("k=v", {:k=>'v'}.to_query_string)
      eq("k1=v1&k2=v2", {:k1=>'v1', :k2=>'v2'}.to_query_string)
    end
  end
end
