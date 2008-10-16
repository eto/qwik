# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/ml-session'
require 'qwik/test-module-ml'

if $0 == __FILE__
  $test = true
end

class TestMSConfirm < Test::Unit::TestCase
  include TestModuleML

  def test_session_with_confirm
    $quickml_config.instance_eval {
      @config[:confirm_ml_creation] = true
    }

    # Bob tries to create a new ML.
    send_normal_mail('bob@example.net')
    logs = @ml_config.logger.get_log
    ok_eq("[test]: New ML by bob@example.net", logs[0])
    if Regexp.new(Regexp.escape("[test]: Send confirmation: ")+
		  "(confirm\\+\\d+\\+test@q\\.example\\.com)"+
		  Regexp.escape(' bob@example.net')) =~ logs[1]
      confirmation_to = $1
    end

    ok_eq(true, @site.unconfirmed?, 'Before reply, unconfirmed? must be true.')

    # Bob replies the confirmation mail.
    send_confirmation_mail('bob@example.net', confirmation_to)
    ok_log(["[test]: Add: bob@example.net",
	     "[test]: QwikPost: test",
	     "[test:1]: Send:",
	     "[test]: Accept confirmation:  test@q.example.com"])

    ok_eq(false, @site.unconfirmed?, 'After reply, unconfirmed? must be false.')

    # Bob send a mail.
    send_normal_mail('bob@example.net')
    ok_log(["[test]: QwikPost: test", "[test:2]: Send:"])

    page = @site['test']
    ok_eq("* test
{{mail(bob@example.net,0)
test
}}
{{mail(bob@example.net,0)
test
}}
",
	  page.load)

    # Alice send a mail, but the mail is rejected.
    send_normal_mail('alice@example.net')
    ok_log(["[test]: Reject: alice@example.net"])

    # The ML is closed.
    unsubscribe('bob@example.net')
    ok_log(["[test]: Remove: bob@example.net",
	     "[test]: ML Closed",
	     "[test]: Unsubscribe: bob@example.net"])

    $quickml_config.instance_eval {
      @config[:confirm_ml_creation] = false
    }
  end

  def send_confirmation_mail(from, to)
    sendmail(from, to, 'confirm') { 'confirm' }
  end
end
