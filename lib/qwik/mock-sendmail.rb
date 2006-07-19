# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'

module QuickML
  class MockSendmail
    def self.open(smtp_host, smtp_port)
      return self.new(smtp_host, smtp_port)
    end

    def initialize(smtp_host, smtp_port)
      @smtp_host, @smtp_port = smtp_host, smtp_port
      @buffer = []
      @in_data = false
    end
    attr_reader :buffer

    def gets
      if @buffer.empty?
	return '220 qwik.jp ESMTP Postfix'
      end

      if @in_data
	if /\.\z/ =~ @buffer.last
	  @in_data = false
	  return '250 Ok: queued as 381E41683E'	# The message is fake.
	end
      end

      cmd = @buffer.last[0..3].downcase
      case cmd
      when 'ehlo'
	return '250 example.com'
      when 'mail'
	return '250 ok'
      when 'rcpt'
	return '250 ok'
      when 'data'
	@in_data = true
	return '354 End data with <CR><LF>.<CR><LF>'
      when 'quit'
	return '221 Bye'
      end

      return ''
    end

    def print(str)
      str.sub!(/\r\n\z/, '')
      @buffer << str
    end

    def close
      # Do nothing.
    end
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  $test = true
end

if defined?($test) && $test
  class TestMockSendmail < Test::Unit::TestCase
    def test_all
      # test_initialize
      s = QuickML::MockSendmail.new('localhost', '9195')

      # test_gets
      ok_eq('220 qwik.jp ESMTP Postfix', s.gets)

      # test_print
      s.print('t')
      ok_eq(['t'], s.buffer)
    end
  end
end
