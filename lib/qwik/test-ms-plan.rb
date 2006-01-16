#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '../../lib' unless $LOAD_PATH.include?('../../lib')
require 'qwik/ml-session'
require 'qwik/test-module-ml'

if $0 == __FILE__
  $test = true
end

class TestMSPlan < Test::Unit::TestCase
  include TestModuleML

  def test_plan
    send_normal_mail('bob@example.net')
    logs = @ml_config.logger.get_log
    ok_eq('[test]: New ML by bob@example.net', logs[0])

    # Bob send a mail with a date tag.
    res = sm('[1970-01-15] t') { 't' }
    ok_log('[test]: QwikPost: t
[test:2]: Send:')
    page = @site['t']
    ok_eq("* [1970-01-15] t\n{{mail(bob@example.net,0)\nt\n}}\n", page.load)

    # test_footer
    now = Time.at(0)
    footer = @site.get_footer(now)
    ok_eq("* Plan\n- [01-15] t\nhttp://example.com/test/t.html\n", footer)

    # Bob send a mail.
    res = sm('tt') { 't' }
    ok_log(['[test]: QwikPost: tt', '[test:3]: Send:'])
    ok_eq('-- 
archive-> http://example.com/test/tt.html 
ML-> test@example.com

* Plan
- [01-15] t
http://example.com/test/t.html',
	  $ml_sm.buffer[-9..-3].join("\n"))
  end

  def test_plan2
    send_normal_mail('bob@example.net')
    ok_eq('[test]: New ML by bob@example.net', @ml_config.logger.get_log[0])

    # Bob send a mail with a date tag.
    res = sm('[1970-01-15] t') { 't' }
    ok_log("[test]: QwikPost: t\n[test:2]: Send:")
    page = @site['t']
    ok_eq("* [1970-01-15] t\n{{mail(bob@example.net,0)\nt\n}}\n", page.load)

    # Bob send the same mail again.msame a same mail with a date tag.
    res = sm('[1970-01-15] t') { 't' }
    ok_log("[test]: QwikPost: t\n[test:3]: Send:")
    page = @site['t']
    ok_eq("* [1970-01-15] t\n{{mail(bob@example.net,0)\nt\n}}\n{{mail(bob@example.net,0)\nt\n}}\n", page.load)

    # test_footer
    now = Time.at(0)
    footer = @site.get_footer(now)
    ok_eq("* Plan\n- [01-15] t\nhttp://example.com/test/t.html\n", footer)
  end

  def test_plan_japanese
    send_normal_mail('bob@example.net')
    logs = @ml_config.logger.get_log
    ok_eq('[test]: New ML by bob@example.net', logs[0])

    # Bob send a mail with a date tag.
    res = sm('[1970-01-15] ‚ ') { '‚¢' }
    ok_log("[test]: QwikPost: 1\n[test:2]: Send:")
    page = @site['1']
    ok_eq("* [1970-01-15] ‚ \n{{mail(bob@example.net,0)\n‚¢\n}}\n", page.load)

    # test_footer
    now = Time.at(0)
    footer = @site.get_footer(now)
    ok_eq("* Plan\n- [01-15] ‚ \nhttp://example.com/test/1.html\n", footer)

    # Bob send a mail.
    res = sm('‚¤‚¤') { '‚¦‚¦' }
    ok_log(['[test]: QwikPost: 2', '[test:3]: Send:'])
    str = $ml_sm.buffer[-12..-3].join("\n")
    ok_eq('
‚¦‚¦

-- 
archive-> http://example.com/test/2.html 
ML-> test@example.com

* Plan
- [01-15] ‚ 
http://example.com/test/1.html'.set_sourcecode_charset.to_mail_charset,
	  str)
  end

end
