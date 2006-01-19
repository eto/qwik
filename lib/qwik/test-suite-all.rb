$LOAD_PATH << '..' unless $LOAD_PATH.include?('..')
require 'qwik/test-module-suite'

TestSuite.new.test_suite_all
