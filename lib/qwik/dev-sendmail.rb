#!/usr/bin/env ruby
# You can send a mail by using SMTP for check the status.

$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'
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
