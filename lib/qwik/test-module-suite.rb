# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

require 'optparse'

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
$test = true	# Set $test before require 'qwik/test-common'
require 'qwik/test-common'

class TestSuite
  def self.main(argv)
    testsuite = self.new
    testsuite.run(argv)
  end

  def run(argv)
    @suite = 'basic'

    optionparser = OptionParser.new {|opts|
      opts.banner = 'Usage: test-suite.rb [options]'
      opts.separator ''
      opts.separator 'Specific options:'
      opts.on('-b', '--[no-]basic', 'Run basic test suite.') {|a|
	@suite = 'basic'
      }
      opts.on('-a', '--[no-]all', 'Run all test suite.') {|a|
	@suite = 'all'
      }
      opts.separator ''
      opts.separator 'Common options:'
      opts.on_tail('-h', '--help', 'Show this message') {
	puts opts
	exit
      }
    }
    optionparser.parse!(argv)

    case @suite
    when 'basic'
      test_suite_basic
    when 'ml'
      test_suite_ml
    when 'all'
      test_suite_all
    end
  end

  def test_suite_basic
    load_by_loadlib('qwik/test-module-*.rb')
    test_suite_ml
    test_suite_web
  end

  def test_suite_web
    load_by_loadlib('qwik/common-*.rb')
    load_by_loadlib('qwik/act-*.rb')
  end

  def test_suite_ml
    load_by_loadlib('qwik/test-module-ml.rb')
    load_by_loadlib('qwik/ml-*.rb')
    load_by_loadlib('qwik/group-*.rb')
    load_by_loadlib('qwik/mail-*.rb')
    load_by_loadlib('qwik/test-ml-*.rb')
    load_by_loadlib('qwik/test-submit-*.rb')
    load_by_loadlib('qwik/test-ms-*.rb')
  end

  def test_suite_all
    test_suite_basic
    test_suite_extra
  end

  def test_suite_extra
    load_by_loadlib('qwik/check-*.rb')
  end

  def test_suite_benchmark
    #load_files('bench')
    load_by_loadlib('qwik/bench-*.rb')
  end

  def load_by_loadlib(arg)
    Qwik::LoadLibrary.load_libs_here(arg)
  end
end

if $0 == __FILE__
  TestSuite.main(ARGV)
end
