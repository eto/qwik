# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/ml-session'
require 'qwik/test-module-ml'

if $0 == __FILE__
  $test = true
end

class TestMSBasic < Test::Unit::TestCase
  include TestModuleML

  def test_all
    logs = @ml_config.logger.get_log

    # Bob send a mail to create a new ML.
    send_normal_mail('bob@example.net')
    ok_log(['[test]: New ML by bob@example.net',
	 '[test]: Add: bob@example.net',
	 '[test]: QwikPost: test',
	 '[test:1]: Send:'])

    # Bob send a mail.
    send_normal_mail('bob@example.net')
    ok_log(['[test]: QwikPost: test', '[test:2]: Send:'])

    # Alice send a mail, but the mail is rejected.
    send_normal_mail('alice@example.net')
    ok_log(['[test]: Reject: alice@example.net'])

    # The ML is closed.
    unsubscribe('bob@example.net')
    ok_log(['[test]: Remove: bob@example.net',
	 '[test]: ML Closed',
	 '[test]: Unsubscribe: bob@example.net'])
  end
end
