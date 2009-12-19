# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/config'
require 'qwik/farm'
require 'qwik/mail'
require 'qwik/mailaddress'
require 'qwik/util-sendmail'
require 'qwik/util-pathname'
#require 'qwik/group-config'

module Qwik
  class SendReportThread
    def initialize(memory)
      @memory = memory
    end

    def start
      loop {
	now = Time.now
	sleep(calc_sleep_time(now))
	begin
	  process
	rescue Exception => e
	  p e
	end
      }
    end

    def send(interval)
      farm = @memory.farm
      farm.list.each {|sitename|
	site = farm.get_site(sitename)
	if site.siteconfig['reportmail'] == interval
	  site.send_report
	end
      }
    end
  end

  class WeeklySendReportThread < SendReportThread
    def calc_sleep_time(w)
      t = Time.at(w.to_i + 60*60*24*7)	# next week
      nxt = Time.local(t.year, t.mon, t.day, 0, 0, 0, 0)	# next
      return (nxt - w).to_i
    end

    def process
      send('weekly')
    end
  end

  class DailySendReportThread < SendReportThread
    def calc_sleep_time(w)
      t = Time.at(w.to_i + 60*60*24)	# next day
      nxt = Time.local(t.year, t.mon, t.day, 0, 0, 0, 0)	# next
      return (nxt - w).to_i
    end

    def process
      send('daily')
    end
  end

  class HourlySendReportThread < SendReportThread
    def calc_sleep_time(w)
      t = Time.at(w.to_i + 60*60)	# next hour
      nxt = Time.local(t.year, t.mon, t.day, t.hour, 0, 0, 0)	# next
      return (nxt - w).to_i
    end

    def process
      send('hourly')
    end
  end

  class Site
    def send_report
      rep = self.make_report
      return nil if rep.nil?
      list = self.member.list(false)	# Without obfuscation.

      list.each {|user|
	mail = generate_report_mail(user, rep)
	sm = Sendmail.new(@config.smtp_host, @config.smtp_port, @config.test)
	begin
	  sm.send(mail)
	rescue => e
	  p 'error '+e
	end
      }
      self.delete('_SiteChanged')		# Destructive.
    end

#    private

    def make_report
      page = self['_SiteChanged']
      return nil if page.nil?

      report = ''
      page.wikidb.array.each {|k, v|
	user, cmd, pagename = v
	user = 'anonymous' if user.nil? || user.empty?
	user = MailAddress.obfuscate(user) if ! user.empty?
	time = Time.at(k.to_i)
	time_str = time.strftime('%H:%M')
	url = self.page_url(pagename)
	line = "#{time_str} #{user} #{cmd} #{url}\n"
	report += line
      }
      return report
    end

    def generate_report_mail(user, rep)
      domainurl = self.host_url
      siteurl = self.site_url
      f = self.siteconfig['reportfrom']
      from = self.ml_address
      from = f if f && ! f.empty?
      mail = {
	:from    => from,
	:to      => user,
	:subject => "#{siteurl} Report",
	:content => "Recent changes on #{siteurl}\n\n#{rep}",
	:precedence => "bulk",
      }

      lang = get_lang
      if lang == 'ja'
	mail[:subject] = "#{siteurl} レポート"
	mail[:content] = "#{siteurl} における、本日の編集記録です。\n\n#{rep}"
      end

      return mail
    end

    def get_lang
      lang = 'en'
      page = self['_GroupCharset']
      return lang if page.nil?
      content = page.load
      charset = self.class.parse_charset(content)
      return 'ja' if charset == 'iso-2022-jp'
      return lang
    end

    # FIXME: Same as in group-config.rb
    def self.parse_charset(content)
      return (content.to_a.first || '').chomp
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestReportThread < Test::Unit::TestCase
    include TestSession

    def test_all
      memory = @memory

      # test_weekly_thread
      @day = Qwik::WeeklySendReportThread.new(memory)
      t = Time.now
      eq(true, 0 < @day.calc_sleep_time(t))
      t = Time.local(2000, 1, 1, 0, 0, 0)	# 2000-01-01T00:00:00
      eq(86400*7, @day.calc_sleep_time(t))
      t = Time.local(2000, 1, 1, 0, 30, 0)	# 2000-01-01T00:30:00
      eq(603000, @day.calc_sleep_time(t))

      # test_daily_thread
      @day = Qwik::DailySendReportThread.new(memory)
      t = Time.now
      eq(true, 0 < @day.calc_sleep_time(t))
      t = Time.local(2000, 1, 1, 0, 0, 0)	# 2000-01-01T00:00:00
      eq(86400, @day.calc_sleep_time(t))
      t = Time.local(2000, 1, 1, 0, 30, 0)	# 2000-01-01T00:30:00
      eq(84600, @day.calc_sleep_time(t))

      # test_hourly_thread
      @day = Qwik::HourlySendReportThread.new(memory)
      t = Time.now
      eq(true, 0 < @day.calc_sleep_time(t))
      t = Time.local(2000, 1, 1, 0, 0, 0)	# 2000-01-01T00:00:00
      eq(3600, @day.calc_sleep_time(t))
      t = Time.local(2000, 1, 1, 0, 30, 0)	# 2000-01-01T00:30:00
      eq(1800, @day.calc_sleep_time(t))
    end
  end

  class TestSiteReport < Test::Unit::TestCase
    include TestSession

    def test_all
      t_add_user

      # test_get_lang
      t_make_public(Qwik::Site, :get_lang)
      eq('en', @site.get_lang)

      # test_generate_report_mail
      t_make_public(Qwik::Site, :generate_report_mail)
      mail = @site.generate_report_mail('user@e.com', 'test')
      eq 'test@q.example.com', mail[:from]
      eq 'user@e.com', mail[:to]
      eq 'http://example.com/test/ Report', mail[:subject]
      eq 'Recent changes on http://example.com/test/

test', mail[:content]

      # test_get_lang_ja
      page = @site.create('_GroupCharset')
      page.put('iso-2022-jp
')
      eq('ja', @site.get_lang)

      # test_generate_report_mail_ja
      t_make_public(Qwik::Site, :generate_report_mail)
      mail = @site.generate_report_mail('user@e.com', 'test')
      eq 'test@q.example.com', mail[:from]
      eq 'user@e.com', mail[:to]
      eq 'http://example.com/test/ レポート', mail[:subject]
      eq 'http://example.com/test/ における、本日の編集記録です。

test', mail[:content]

      # test_make_report
      t_make_public(Qwik::Site, :make_report)
      rep = @site.make_report
      eq(nil, rep)

      page = @site.create_new
      page.store('t')

      sitelog = @site.sitelog
      sitelog.add(0, 'user@e.com', 'save', '1')
      eq(',0,user@e.com,save,1
', @site['_SiteChanged'].load)
      sitelog.add(0, nil, 'save', '1')
      eq(',0,user@e.com,save,1
,0,,save,1
', @site['_SiteChanged'].load)

      # test_make_report2
      eq('09:00 user@e... save http://example.com/test/1.html
09:00 anonymous save http://example.com/test/1.html
', @site.make_report)
      eq(',0,user@e.com,save,1
,0,,save,1
', @site['_SiteChanged'].load)

      # test_send_report
      @site.send_report
      eq(['test@q.example.com', 'user@e.com'], $smtp_sendmail[2..3])
      assert_match(/test@q.example.com/, $smtp_sendmail[4])

      header =
"From: test@q.example.com
To: user@e.com
Subject: http://example.com/test/ =?ISO-2022-JP?B?GyRCJWwlXSE8JUgbKEI=?=
Content-Type: text/plain; charset=\"ISO-2022-JP\"

"
      body =
'http://example.com/test/ における、本日の編集記録です。

09:00 user@e... save http://example.com/test/1.html
09:00 anonymous save http://example.com/test/1.html

'
      eq((header+body.set_sourcecode_charset.to_mail_charset),
	 $smtp_sendmail[4])
    end
  end
end
