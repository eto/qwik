# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/ml-session'
require 'qwik/test-module-ml'

if $0 == __FILE__
  $test = true
end

class TestMSLarge < Test::Unit::TestCase
  include TestModuleML

  def test_session_large_mail
    $quickml_config.instance_eval {
      @config[:max_mail_length] = 10 * 1024
    }

    logs = @ml_config.logger.get_log

    # Alice create a new ML.
    send_normal_mail 'alice@example.net'
    ok_log '[test]: New ML by alice@example.net
[test]: Add: alice@example.net
[test]: QwikPost: test
[test:1]: Send:'

    # send_large_mail
    sendmail('alice@example.net', 'test@q.example.com', 'large') {
      ('o' * 62 + "\n") * 16 * 10
    }
    ok_log 'Too Large Mail: alice@example.net'

    # send_longline_mail
    sendmail('alice@example.net', 'test@q.example.com', 'longline') {
      'o' * 2000 + "\n"
    }
    ok_log 'Too Long Line: alice@example.net'

    send_normal_mail 'alice@example.net'
    ok_log '[test]: QwikPost: test
[test:2]: Send:'

    # send_japanese_large_mail
    sendmail('alice@example.net', 'test@q.example.com',
	     '=?iso-2022-jp?B?GyRCJEckKyQkGyhC?=') {
      "Content-Type: text/plain; charset=ISO-2022-JP\n\n" +
	('o' * 62 + "\n") * 16 * 10
    }
    ok_log 'Too Large Mail: alice@example.net'

    $quickml_config.instance_eval {
      @config[:max_mail_length] = 100 * 1024
    }
  end
end
