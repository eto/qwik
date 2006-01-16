#!/usr/bin/env ruby
#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

# You can send a mail by using SMTP for check the status.

$LOAD_PATH << '../../lib' unless $LOAD_PATH.include?('../../lib')
require 'qwik/config'
require 'qwik/util-sendmail'
require 'qwik/qwik-mail'

def main
  config = Qwik::Config.new
  config.update({
		  :smtp_host	=> '127.0.0.1',
		  :smtp_port	=> '25',
		})

  mail = Qwik::Mail.new
  mail.from = 'etocom@gmail.com'
  mail.to = 'etoeto@qwik.jp'
  mail.subject = 'test'
  mail.content = 'test desu.'

  sendmail = Qwik::Sendmail.new('127.0.0.1', '25')
  sendmail.send(mail)
end

main
