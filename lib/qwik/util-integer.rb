#
# Copyright (C) 2002-2004 Satoru Takabayashi <satoru@namazu.org> 
# Copyright (C) 2003-2006 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'

class Integer
  # 12345.commify => '12,345'
  def commify
    numstr = self.to_s
    true while numstr.sub!(/^([-+]?\d+)(\d{3})/, '\1,\2')
    return numstr
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  $test = true
end

if defined?($test) && $test
  class TestUtilInteger < Test::Unit::TestCase
    def test_commify
      ok_eq('12,345', 12345.commify)
      ok_eq('123,456,789', 123456789.commify)
    end
  end
end
