# Copyright (C) 2003-2009 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    def status_get_date(time)
      return "* " + time.strftime("%Y-%m-%dT%H:%M:%S") + "\n"
    end

    def status_get_memory(ps)
      str = ''
      ps.each_line {|line|
	user, pid, cpu, mem, vsz, rss, tty, stat, start, time, command =
	  line.split(nil, 11)
	next if /^sh/ =~ command
	next if /^grep/ =~ command
	next if /^ruby/ =~ command
	next if %r|^/bin/sh| =~ command
	next if time == "0:00"

	command = 'quickml-server' if /quickml-server/ =~ command
	command = 'qwikweb-server' if /qwikweb-server/ =~ command

	vsz = vsz.to_i / 1000
	rss = rss.to_i / 1000

	str << "#{vsz}MB	#{rss}MB	#{command}\n"
      }
      str
    end

    def status_get_objects
      ar = []
      num = 0
      ObjectSpace.each_object {|obj|
        num += 1

        name = obj.class.name
        if name == "String" ||
            name == "Regexp" ||
            name == "Class" ||
            name == "Hash" ||
            name == "Bignum" ||
            name == "Module" ||
            name == "Float" ||
            name == "Array"
          # do nothing
        else
          ar << name
        end
      }

      hash = Hash.new(0)
      ar.each {|classname|
        hash[classname] += 1
      }

      ar2 = []
      hash.each {|k, v|
        ar2 << [v, k]
      }

      ar3 = ar2.sort.reverse

      str = ''
      str << "object num #{num}\n"

      ar3.each {|v, k|
        str << "#{v}\t#{k}\n"
      }
      str
    end

    def status_get_objects2
      ar = []
      num = 0
      ObjectSpace.each_object {|obj|
        ar << obj.class.name
        num += 1
      }

      ar3 = ar.sort.uniq

      str = ''
      str << "object num #{num}\n"

      ar3.each {|v|
        str << "#{v}\n"
      }

      str
    end

    def act_status
      str = "status\n"

      time = Time.now
      str << status_get_date(time)
      str << "\n"

      ps = `ps auxww | grep -i ruby`
      str << status_get_memory(ps)
      str << "\n"

      str << status_get_objects
#      str << status_get_objects2
      str << "\n"

      return c_notice(_('Status')) {
	[[:h2, _('Status')],
	  [:pre, str]]
      }
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActStatus < Test::Unit::TestCase
    include TestSession

    def test_all
      res = session

      time = Time.at(0)
      str = @action.status_get_date(time)
      is "* 1970-01-01T09:00:00\n", str

      ps = <<'EOS'
qwik     14611  0.0  0.0  3468 1260 ?        Ss   17:19   0:00 /bin/sh -c /usr/bin/ruby -I/home/qwik/qwik/lib /home/qwik/qwik/bin/quickml-server -d -c /home/qwik/qwik/etc/config-debug.txt >> /home/qwik/qwik/log/quickml-out 2>&1
qwik     14612  0.0  0.0  3468 1260 ?        Ss   17:19   0:00 /bin/sh -c /usr/bin/ruby -I/home/qwik/qwik/lib /home/qwik/qwik/bin/qwikweb-server -d -c /home/qwik/qwik/etc/config-debug.txt >> /home/qwik/qwik/log/out 2>&1
qwik     14613  0.5  0.2 12964 9520 ?        S    17:19   0:01 /usr/bin/ruby -I/home/qwik/qwik/lib /home/qwik/qwik/bin/quickml-server -d -c /home/qwik/qwik/etc/config-debug.txt
qwik     14614  6.9  0.8 35792 29504 ?       S    17:19   0:15 /usr/bin/ruby -I/home/qwik/qwik/lib /home/qwik/qwik/bin/qwikweb-server -d -c /home/qwik/qwik/etc/config-debug.txt
qwik     14615  0.0  0.2 12964 9520 ?        S    17:19   0:00 /usr/bin/ruby -I/home/qwik/qwik/lib /home/qwik/qwik/bin/quickml-server -d -c /home/qwik/qwik/etc/config-debug.txt
qwik     14616  0.0  0.2 12964 9520 ?        S    17:19   0:00 /usr/bin/ruby -I/home/qwik/qwik/lib /home/qwik/qwik/bin/quickml-server -d -c /home/qwik/qwik/etc/config-debug.txt
qwik     14617  0.0  0.8 35792 29504 ?       S    17:19   0:00 /usr/bin/ruby -I/home/qwik/qwik/lib /home/qwik/qwik/bin/qwikweb-server -d -c /home/qwik/qwik/etc/config-debug.txt
qwik     14618  0.0  0.8 35792 29504 ?       S    17:19   0:00 /usr/bin/ruby -I/home/qwik/qwik/lib /home/qwik/qwik/bin/qwikweb-server -d -c /home/qwik/qwik/etc/config-debug.txt
EOS
      str = @action.status_get_memory(ps)
      is "12MB\t9MB\tquickml-server\n35MB\t29MB\tqwikweb-server\n", str
    end
  end
end
