# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/ml-session'
require 'qwik/test-module-ml'

if $0 == __FILE__
  $test = true
end

class TestMSMember < Test::Unit::TestCase
  include TestModuleML

  def test_all
    @ml_config.instance_eval {
      @config[:max_members] = 2
    }

    # Alice create a new ML
    send_normal_mail('alice@example.net')
    ok_log(["[test]: New ML by alice@example.net",
	     "[test]: Add: alice@example.net",
	     "[test]: QwikPost: test"], 0..2)

    # Mail from is case-insensitive.
    send_normal_mail('ALICE@EXAMPLE.NET')
    ok_log(["[test]: QwikPost: test", "[test:2]: Send:"])

    # Bob send a mail, but is rejected.
    send_normal_mail 'bob@example.net'
    ok_log(["[test]: Reject: bob@example.net"])

    # Add a member Charlie.
    add_member 'charlie@example.net'
    ok_log(["[test]: Add: charlie@example.net",
	     "[test]: QwikPost: addmember", "[test:3]: Send:"])

    # Max exceeds.  :max_members
    add_member 'bob@example.net'
    ok_log(["[test]: Too Many Members: bob@example.net",
	     "[test]: QwikPost: addmember",
	     "[test:4]: Send:"])

    # Remove a member, alice.
    remove_member 'ALICE@EXAMPLE.NET', 'charlie@example.net'
    ok_log(["[test]: Remove: charlie@example.net",
	     "[test]: Unsubscribe: charlie@example.net"])

    # Bob joined to the ml.
    join_ml('bob@example.net')
    ok_log(["[test]: Add: bob@example.net",
	     "[test]: QwikPost: join", "[test:5]: Send:"])

    # Bob removed Alice.
    remove_member 'bob@example.net', 'Alice@Example.Net'
    ok_log(["[test]: Remove: Alice@example.net",
	     "[test]: Unsubscribe: Alice@example.net"])

    # Alice returned to the ml.
    send_normal_mail 'alice@example.net'
    ok_log(["[test]: Add: alice@example.net",
	     "[test]: QwikPost: test", "[test:6]: Send:"])

    # Alice removed Bob.
    remove_member 'alice@example.net', 'bob@example.net'
    ok_log(["[test]: Remove: bob@example.net",
	     "[test]: Unsubscribe: bob@example.net"])

    # Try to add nonexistent mail address.
    add_member 'nonexistent'
    ok_log(["[test]: QwikPost: addmember", "[test:7]: Send:"])

    send_normal_mail 'alice@example.net'
    ok_log(["[test]: QwikPost: test", "[test:8]: Send:"])

    send_normal_mail 'Alice@Example.Net'
    ok_log(["[test]: QwikPost: test", "[test:9]: Send:"])

    send_normal_mail 'ALICE@EXAMPLE.NET' # exceeds :auto_unsubscribe_count
    ok_log(["[test]: QwikPost: test", "[test:10]: Send:"])

    unsubscribe 'alice@example.net'		# close ML
    ok_log(["[test]: Remove: alice@example.net",
	     "[test]: ML Closed",
	     "[test]: Unsubscribe: alice@example.net"])
  end

  def add_member(cc)
    sendmail('alice@example.net', 'test@q.example.com', 'addmember', cc) {
      'add'
    }
  end

  def remove_member(from, member)
    sendmail(from, 'test@q.example.com', 'remove', member) { '' }
  end

  def join_ml(from)
    sendmail(from, 'test@q.example.com', 'join', 'alice@example.net') { 'join' }
  end
end
