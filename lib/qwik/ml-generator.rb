#
# Copyright (C) 2002-2004 Satoru Takabayashi <satoru@namazu.org> 
# Copyright (C) 2003-2006 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module QuickML
  class Generator
  end
end

if $0 == __FILE__
  require 'qwik/mail'
  $test = true
end

if defined?($test) && $test
  class TestMLGenerator < Test::Unit::TestCase
    def test_all
    end
  end
end
