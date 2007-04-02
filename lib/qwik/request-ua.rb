# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class UserAgent
    def initialize(req)
      @req = req
      @mobile = @serial = nil
      parse(@req)
    end
    attr_reader :mobile, :serial

    def parse(req)
      @mobile, @serial = UserAgent.parse(req)
    end

    def self.parse(req)
      ua = req['user-agent']
      mobile = serial = nil
      case ua
      when /\ADoCoMo/	# docomo
	mobile = 'docomo'
	serial = $1 if /\/ser(...........)/ =~ ua
      when /\AKDDI\-/, /\AUP\.Browser/	# ezweb
	mobile = 'ezweb'
	serial = req['x-up-subno']
      end
      return mobile, serial
    end
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  require 'qwik/config'
  require 'qwik/request'
  $test = true
end

if defined?($test) && $test
  class TestRequestUserAgent < Test::Unit::TestCase
    def test_class_method
      c = Qwik::UserAgent
      ok_eq(['docomo', nil],
	    c.parse({'user-agent'=>'DoCoMo/1.0/N504i/c10/TB'}))
      ok_eq(['docomo', 'NMAIA000001'],
	    c.parse({'user-agent'=>'DoCoMo/1.0/N504i/c10/TB/serNMAIA000001'}))
      ok_eq(['ezweb', nil],
	    c.parse({'user-agent'=>"KDDI-TS23 UP.Browser/6.0.7.2 (GUI) MMP/1.1"}))
      ok_eq(['ezweb', 'XXXXXXXXXXXXXXXXX.ezweb.ne.jp'],
	    c.parse({'user-agent'=>"KDDI-TS23 UP.Browser/6.0.7.2 (GUI) MMP/1.1",
		      'x-up-subno'=>'XXXXXXXXXXXXXXXXX.ezweb.ne.jp'}))
    end

    def test_user_agent
      config = Qwik::Config.new
      req = Qwik::Request.new(config)

      req.instance_eval {
	@header['user-agent'] = ['DoCoMo/1.0/N504i/c10/TB']
      }
      ua = Qwik::UserAgent.new(req)
      ok_eq('docomo', ua.mobile)
      ok_eq(nil, ua.serial)
      req.instance_eval {
	@header['user-agent'] = ['DoCoMo/1.0/N504i/c10/TB/serNMAIA000001']
      }
      ua = Qwik::UserAgent.new(req)
      ok_eq('docomo', ua.mobile)
      ok_eq('NMAIA000001', ua.serial)
    end
  end
end
