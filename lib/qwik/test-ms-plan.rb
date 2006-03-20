$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'
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
    eq "* plan_19700115\n{{mail(bob@example.net,0)\nt\n}}\n", page.load

    # test_footer
    eq "* Plan\n- [01-15] plan_19700115\nhttp://example.com/test/plan_19700115.html\n", @site.get_footer(Time.at(0))

    # Bob send a mail.
    res = sm('tt') { 't' }
    ok_log ['[test]: QwikPost: tt', '[test:3]: Send:']
    eq "-- \narchive-> http://example.com/test/tt.html \nML-> test@q.example.com\n\n* Plan\n- [01-15] plan_19700115\nhttp://example.com/test/plan_19700115.html", $ml_sm.buffer[-9..-3].join("\n")
  end

  def test_plan2
    send_normal_mail('bob@example.net')
    eq '[test]: New ML by bob@example.net', @ml_config.logger.get_log[0]

    # Bob send a mail with a date tag.
    res = sm('plan_19700115') { 't' }
    ok_log("[test]: QwikPost: plan_19700115\n[test:2]: Send:")
    page = @site['plan_19700115']
    eq "* plan_19700115\n{{mail(bob@example.net,0)\nt\n}}\n", page.load

    # Bob send the same mail again.msame a same mail with a date tag.
    res = sm('plan_19700115') { 't' }
    ok_log "[test]: QwikPost: plan_19700115\n[test:3]: Send:"
    page = @site['plan_19700115']
    eq "* plan_19700115\n{{mail(bob@example.net,0)\nt\n}}\n{{mail(bob@example.net,0)\nt\n}}\n", page.load

    # test_footer
    eq "* Plan\n- [01-15] plan_19700115\nhttp://example.com/test/plan_19700115.html\n", @site.get_footer(Time.at(0))
  end

  def test_plan_japanese
    send_normal_mail('bob@example.net')
    logs = @ml_config.logger.get_log
    eq '[test]: New ML by bob@example.net', logs[0]

    # Bob send a mail with a date tag.
    res = sm('plan_19700115') { '‚¢' }
    ok_log "[test]: QwikPost: plan_19700115\n[test:2]: Send:"
    page = @site['plan_19700115']
    eq "* plan_19700115\n{{mail(bob@example.net,0)\n‚¢\n}}\n", page.load

    # test_footer
    eq "* Plan\n- [01-15] plan_19700115\nhttp://example.com/test/plan_19700115.html\n", @site.get_footer(Time.at(0))

    # Bob send a mail.
    res = sm('‚¤‚¤') { '‚¦‚¦' }
    ok_log "[test]: QwikPost: 1\n[test:3]: Send:"
    str = $ml_sm.buffer[-12..-3].join("\n")
    eq '
‚¦‚¦

-- 
archive-> http://example.com/test/1.html 
ML-> test@q.example.com

* Plan
- [01-15] plan_19700115
http://example.com/test/plan_19700115.html'.set_sourcecode_charset.to_mail_charset,
      str
  end
end
