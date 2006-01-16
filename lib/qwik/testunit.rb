#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

#
# A patch to test/unit/ui/console/testrunner.rb
# Show the elapsed time in each test case.
#

require 'test/unit'
require 'test/unit/ui/console/testrunner'
# Load testrunner.rb at the first to patch it.

module Test
  module Unit

    module UI
      module Console
        class TestRunner
	  alias :org_test_started :test_started
          def test_started(name)
            output_single(name + ': ', VERBOSE)
	    $test_start_time = Time.now
          end

	  alias :org_test_finished :test_finished
          def test_finished(name)
            output_single('.', PROGRESS_ONLY) unless (@already_outputted)
	    elapsed_time = Time.now - $test_start_time
	    str = sprintf(' (%0.02f)', elapsed_time)
            output_single(str, VERBOSE) unless (@already_outputted)
            nl(VERBOSE)
            @already_outputted = false
          end
	end
      end
    end

    module Assertions
      alias ok_eq assert_equal
      alias eq assert_equal
    end

  end
end
