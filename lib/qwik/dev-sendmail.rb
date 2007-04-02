# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

# You can send a mail using SMTP for checking the status.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/config'
require 'qwik/util-sendmail'
require 'qwik/qwik-mail'

def main
  config = Qwik::Config.new
  config.update(:smtp_host => '127.0.0.1', :smtp_port => '25')
  mail = {
    :from    => 'etocom@gmail.com',
    :to      => 'etoeto@qwik.jp',
    :subject => 'test',
    :content => 'test desu.',
  }
  sendmail = Qwik::Sendmail.new('127.0.0.1', '25')
  sendmail.send(mail)
end

main
