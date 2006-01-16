Dir.chdir 'lib/qwik'
$LOAD_PATH << '../../lib' unless $LOAD_PATH.include?('../../lib')
require 'qwik/test-suite-all.rb'
