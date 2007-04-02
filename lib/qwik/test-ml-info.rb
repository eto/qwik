#
# Copyright (C) 2002-2004 Satoru Takabayashi <satoru@namazu.org> 
# Copyright (C) 2003-2006 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

#
# This file is just for information.  Do not execute.
#

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/testunit'
require 'qwik/ml-session'

if false	# Just for information.  Do not execute.
  class TestQuickMLSession < Test::Unit::TestCase
    def test_quickml_main
      start
      send_normal_mail 'bob@example.net' # create a new ML by bob@example.net
      send_normal_mail 'alice@example.net'	# must be rejected
      send_japanese_multipart_mail 'alice@example.net'	# must be rejected
      send_multipart_mail 'alice@example.net'	# must be rejected
      unsubscribe 'bob@example.net'		# close ML

      send_normal_mail 'alice@example.net'	# create new ML
      send_normal_mail 'ALICE@EXAMPLE.NET'	# case-insensitive OK?
      send_multipart_mail 'alice@example.net'
      send_japanese_mail 'alice@example.net'	# Japanese
      send_normal_mail 'bob@example.net'		# must be rejected
      add_member 'charlie@example.net'
      add_member 'bob@example.net'		# exceeds :max_members
      remove_member 'ALICE@EXAMPLE.NET', 'charlie@example.net'
      join_ml 'bob@example.net'
      remove_member 'bob@example.net', 'Alice@Example.Net'
      send_normal_mail 'alice@example.net'	# return
      remove_member 'alice@example.net', 'bob@example.net'
      add_member 'nonexistent'
      send_normal_mail 'alice@example.net'
      send_normal_mail 'Alice@Example.Net'
      send_normal_mail 'ALICE@EXAMPLE.NET'	# exceeds :auto_unsubscribe_count
      unsubscribe 'alice@example.net'		# close ML

      send_normal_mail 'alice@example.net'	#
      unsubscribe 'alice@example.net'		# close ML (English report mail)

      send_normal_mail 'alice@example.net' # re-create new ML by alice@example.net
      send_large_mail
      send_longline_mail
      send_japanese_multipart_mail 'alice@example.net'
      send_japanese_large_mail
      sleep 180					# automatic ML deletion
      finish
    end

    def start
      #cat /dev/null > /var/spool/mail/$USER
      #sudo rm -rf mldata
      #rm -f quickml.log
      #mkdir mldata
      #sudo ruby -I ../lib ../quickml quickmlrc.test 
    end

    def setup_config
      {
	# QuickML Internal use.
      # :message_catalog = nil  # for English messages
	:message_catalog => Dir.pwd+'/../messages.ja',

	# For test and debug.
	:verbose_mode	=> true,

	# Server setting.
	:user		=> 'quickml',
	:group		=> 'quickml',
#	:ml_port	=> 10025,
	:ml_port	=> 9196,

	# Send mail setting.
	:smtp_host	=> 'localhost',

	# Mailing list setting.
	:domain		=> Socket.gethostname,
	:postmaster	=> 'info@localhost',
	:info_url	=> 'http://localhost/',

	# Mailing list server setting.
	:sweep_interval	=> 10,
	:allowable_error_interval	=> 3,
	:max_threads	=> 10,
	:timeout	=> 120,

	# Config for each group.
	:auto_unsubscribe_count		=> 3,
	:max_mail_length=> 1024 * 1024,
	:max_members	=> 2,
	:ml_alert_time	=> 160,
	:ml_life_time	=> 170,

	# Setting for directories and files.
	:sites_dir	=> Dir.pwd+'/mldata',
	:log_dir	=> '.',
	:ml_pid_file	=> Dir.pwd+'/quickml.pid',
      }
    end

    def sendmail(from, to, subject, cc='')
      message = yield
      contents = []
      contents << "To: #{to}\n"
      contents << "From: #{from}\n"
      contents << "Subject: #{subject}\n"
      contents << "Cc: #{cc}\n"
      contents << "\n" if /\n\z/ !~ message
      contents << message
      Net::SMTP.start('localhost') {|smtp|
	smtp.send_mail(contents, from, to)
      }
    end

    def send_normal_mail(from)
      sendmail(from, 'test@example.com', 'test'){'test'}
    end

    def send_japanese_multipart_mail(from)
      message = <<'EOF'
Mime-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Type: Multipart/Mixed;
 boundary="--Next_Part(Wed_Oct_16_19:21:12_2002_747)--"

----Next_Part(Wed_Oct_16_19:21:12_2002_747)--
Content-Type: Text/Plain; charset=iso-2022-jp
Content-Transfer-Encoding: 7bit

‚Ä‚·‚Æ
----Next_Part(Wed_Oct_16_19:21:12_2002_747)--
Content-Type: Text/Plain; charset=us-ascii
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename='foobar.txt'

foobar

----Next_Part(Wed_Oct_16_19:21:12_2002_747)----
EOF
      sendmail(from, 'test@example.com',
	       "=?iso-2022-jp?B?GyRCJF4kayRBJFEhPCRIGyhC?="){message}
    end

    def send_multipart_mail(from)
      message = <<'EOF'
Mime-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Type: Multipart/Mixed;
 boundary="--Next_Part(Wed_Oct_16_19:21:12_2002_747)--"

----Next_Part(Wed_Oct_16_19:21:12_2002_747)--
Content-Type: Text/Plain; charset=us-ascii
Content-Transfer-Encoding: 7bit

test
----Next_Part(Wed_Oct_16_19:21:12_2002_747)--
Content-Type: Text/Plain; charset=us-ascii
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename='foobar.txt'

foobar

----Next_Part(Wed_Oct_16_19:21:12_2002_747)----
EOF
      sendmail(from, 'test@example.com', 'multipart'){message}
    end

    def unsubscribe(from)
      sendmail(from, 'test@example.com', 'unsubscribe'){''}
    end
    
    def send_japanese_mail(from)
      message = <<'EOF'
Content-Type: text/plain; charset=ISO-2022-JP

“ú–{Œê‚Å‚·‚æ
EOF
      sendmail(from, 'test@example.com',
	       "=?iso-2022-jp?B?GyRCJEYkOSRIGyhC?="){message}
    end

    def add_member(cc)
      sendmail('alice@example.net', 'test@example.com', 'unsubscribe', cc){'add'}
    end
    
    def remove_member(by, member)
      sendmail(by, 'test@example.com', 'remove', member){''}
    end

    def join_ml(from)
      sendmail(from, 'test@example.com', 'join', 'alice@example.net'){'join'}
    end

    def send_large_mail
      message = "oooooooooo\n" * 500000
      sendmail('alice@example.net', 'test@example.com', 'large'){message}
    end

    def send_longline_mail
      message = 'o' * 2000 + "\n"
      sendmail('alice@example.net', 'test@example.com', 'longline'){message}
    end

    def send_japanese_large_mail
      message = "Content-Type: text/plain; charset=ISO-2022-JP\n\n"
      message += "oooooooooo\n" * 500000
      sendmail('alice@example.net', 'test@example.com',
	       "=?iso-2022-jp?B?GyRCJEckKyQkGyhC?="){message}
    end

    def finish
      #sleep 3
      #sudo kill `cat quickml.pid`
    end
  end
end
