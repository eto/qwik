# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
   #JAVASCRIPT_FILES = %w(prototype scriptaculous base niftypp debugwindow)
    JAVASCRIPT_FILES = %w(base niftypp se_hilite_jp)

    def self.generate_js
      return JAVASCRIPT_FILES.map {|f|
	generate_script("js/#{f}")
      }
    end

    def self.generate_script(f)
      return [:script, {:type=>'text/javascript', :src=>".theme/#{f}.js"}, '']
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestCommon < Test::Unit::TestCase
    include TestSession

    def test_generate_js
      c = Qwik::Action
      eq [:script, {:src=>'.theme/t.js', :type=>'text/javascript'}, ''],
	 c.generate_script('t')
#      eq [[:script, {:src=>'.theme/js/base.js', :type=>'text/javascript'}, ''],
#	   [:script, {:src=>'.theme/js/niftypp.js', :type=>'text/javascript'},
#	     ''],
#	   [:script, {:src=>'.theme/js/debugwindow.js',
#	       :type=>'text/javascript'}, '']],
#	 c.generate_js
    end
  end
end
