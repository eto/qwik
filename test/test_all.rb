# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

Dir.chdir 'lib/qwik'
$LOAD_PATH << '../../lib' unless $LOAD_PATH.include?('../../lib')
require 'qwik/test-suite-all.rb'
