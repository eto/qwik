#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '../../lib' unless $LOAD_PATH.include?('../../lib')
require 'pp'
require 'qwik/qp'
require 'qwik/testunit'
require 'qwik/test-module-session'
require 'qwik/server'
# $KCODE = 's'

#require 'qwik/autoreload'
#autoreload(1, true) # auto reload
