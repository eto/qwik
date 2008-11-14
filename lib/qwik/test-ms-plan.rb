# -*- coding: shift_jis -*-
# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/ml-session'
require 'qwik/test-module-ml'

if $0 == __FILE__
  $test = true
end

class TestMSPlan < Test::Unit::TestCase
  include TestModuleML

  def test_plan
    send_normal_mail 'bob@example.net'
    logs = @ml_config.logger.get_log
    eq '[test]: New ML by bob@example.net', logs[0]

    # Bob send a mail with a date tag.
    #res = sm('[1970-01-15] t') { 't' }
    res = sm('plan_19700115') { 't' }
    ok_log '[test]: QwikPost: plan_19700115
[test:2]: Send:'
    page = @site['plan_19700115']
    eq "* plan_19700115
{{mail(bob@example.net,0)
t
}}
", page.load

    # test_footer
    eq "* Plan
- [01-15] plan_19700115
http://example.com/test/plan_19700115.html
", @site.get_footer(Time.at(0))

    # Bob send a mail.
    res = sm('tt') { 't' }
    ok_log ['[test]: QwikPost: tt', '[test:3]: Send:']
    eq "-- 
archive-> http://example.com/test/tt.html 
ML-> test@q.example.com

* Plan
- [01-15] plan_19700115
http://example.com/test/plan_19700115.html", $ml_sm.buffer[-9..-3].join("\n")

    page = @site['tt']
    eq "* tt
{{mail(bob@example.net,0)
t
}}
", page.load
  end

  def test_plan2
    send_normal_mail('bob@example.net')
    eq '[test]: New ML by bob@example.net', @ml_config.logger.get_log[0]

    # Bob send a mail with a date tag.
    res = sm('plan_19700115') { 't' }
    ok_log("[test]: QwikPost: plan_19700115\n[test:2]: Send:")
    page = @site['plan_19700115']
    eq "* plan_19700115
{{mail(bob@example.net,0)
t
}}
", page.load

    # Bob send the same mail again.msame a same mail with a date tag.
    res = sm('plan_19700115') { 't' }
    ok_log "[test]: QwikPost: plan_19700115\n[test:3]: Send:"
    page = @site['plan_19700115']
    eq "* plan_19700115
{{mail(bob@example.net,0)
t
}}
{{mail(bob@example.net,0)
t
}}
", page.load

    # test_footer
    eq "* Plan
- [01-15] plan_19700115
http://example.com/test/plan_19700115.html
", @site.get_footer(Time.at(0))
  end

  def test_plan_japanese
    send_normal_mail('bob@example.net')
    logs = @ml_config.logger.get_log
    eq '[test]: New ML by bob@example.net', logs[0]

    # Bob send a mail with a date tag.
    res = sm('plan_19700115') { 'い' }
    ok_log "[test]: QwikPost: plan_19700115\n[test:2]: Send:"
    page = @site['plan_19700115']
    eq "* plan_19700115
{{mail(bob@example.net,0)
い
}}
", page.load

    # test_footer
    eq "* Plan
- [01-15] plan_19700115
http://example.com/test/plan_19700115.html
", @site.get_footer(Time.at(0))

    # Bob send a mail.
    res = sm('うう') { 'ええ' }
    ok_log "[test]: QwikPost: 1\n[test:3]: Send:"
    str = $ml_sm.buffer[-12..-3].join("\n")
    eq '
ええ

-- 
archive-> http://example.com/test/1.html 
ML-> test@q.example.com

* Plan
- [01-15] plan_19700115
http://example.com/test/plan_19700115.html'.set_sourcecode_charset.to_mail_charset,
      str
  end
end
