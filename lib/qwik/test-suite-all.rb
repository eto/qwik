$LOAD_PATH << '../../lib' unless $LOAD_PATH.include?('../../lib')
require 'qwik/test-module-suite'

TestSuite.new.test_suite_all
