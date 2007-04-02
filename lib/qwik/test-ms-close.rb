#
# Copyright (C) 2003-2006 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/ml-session'
require 'qwik/test-module-ml'

if $0 == __FILE__
  $test = true
end

class TestMSClose < Test::Unit::TestCase
  include TestModuleML

  def test_close
    # Alice create a new ML.
    send_normal_mail('alice@example.net')
    ok_log(["[test]: New ML by alice@example.net",
	     "[test]: Add: alice@example.net",
	     "[test]: QwikPost: test",
	     "[test:1]: Send:"])

    # Alice unsubscrive from the ML.  The ML will be closed.
    unsubscribe('alice@example.net')
    ok_log(["[test]: Remove: alice@example.net",
	     "[test]: ML Closed",
	     "[test]: Unsubscribe: alice@example.net"])
  end
end
