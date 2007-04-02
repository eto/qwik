# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/ml-session'
require 'qwik/test-module-ml'

if $0 == __FILE__
  $test = true
end

class TestMSPost < Test::Unit::TestCase
  include TestModuleML

  def test_post_1
    logs = @ml_config.logger.get_log

    send_normal_mail 'bob@example.net'		# Bob creates a new ML.
    logs = @ml_config.logger.get_log

    eq nil, @site['1']
    send_normal_mail 'bob@example.net'
    ok_log ['[test]: QwikPost: test', '[test:2]: Send:']
    eq 'test', @site['test'].get_title
    eq "* test\n{{mail(bob@example.net,0)\ntest\n}}\n{{mail(bob@example.net,0)\ntest\n}}\n", @site['test'].load

    send_normal_mail 'bob@example.net'
    eq "* test\n{{mail(bob@example.net,0)\ntest\n}}\n{{mail(bob@example.net,0)\ntest\n}}\n{{mail(bob@example.net,0)\ntest\n}}\n", @site['test'].load
  end

  def test_submit_3
    send_normal_mail 'bob@example.net'

    sendmail('bob@example.net', 'test@q.example.com', 'Another mail.') {
"MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Type: text/plain; charset=\"ISO-2022-JP\"

This is also a test.
" }
    eq 'Another mail.', @site['1'].get_title
    eq "* Another mail.\n{{mail(bob@example.net,0)
This is also a test.\n}}\n", @site['1'].load
  end

  def test_submit_4
    send_normal_mail 'bob@example.net'		# Bob creates a new ML.
    sendmail('bob@example.net', 'test@q.example.com', 'a') { 'b' }
    eq 'a', @site['a'].get_title
    eq "* a\n{{mail(bob@example.net,0)\nb\n}}\n", @site['a'].load
  end
end
