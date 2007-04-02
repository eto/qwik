# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/config'
require 'qwik/request-path'
require 'qwik/request-ua'
require 'qwik/request-webrick'

module Qwik
  class Request
    DEFAULT_ACCEPT_LANGUAGE = ['en']

    def initialize(config)
      @config = config

      @start_time = Time.now
      @start_time = Time.at(0) if defined?($test) && $test

      init_path

      # init_host
      @fromhost = nil

      @request_method = nil
      @cookies = {}
      @header = {}
      @query = {}
      @user = @pass = nil
      @auth = nil
      @useragent = UserAgent.new(self)
      @sessionid = nil
      @accept_language = DEFAULT_ACCEPT_LANGUAGE
      @request_line = nil
    end

    attr_accessor :start_time	# For test.
    attr_reader :request_method
    attr_reader :cookies
    attr_reader :header		# For test.
    attr_reader :query
    attr_accessor :user
    attr_reader :pass
    attr_accessor :auth
    attr_reader :useragent
    attr_accessor :sessionid
    attr_accessor :accept_language
    attr_reader :request_line
    attr_reader :fromhost

    def is_post?
      return @request_method == 'POST'
    end

    def [](key)
      return nil if @header.nil?
      value = @header[key.downcase]
      return nil if value.nil? || value.empty?
      return value.join(', ')
    end
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  $test = true
end

if defined?($test) && $test
  class TestRequest < Test::Unit::TestCase
    def test_all
      config = Qwik::Config.new
      req = Qwik::Request.new(config)

      # test_start_time
      ok_eq(0, req.start_time.to_i)

      # test_[]
      req.instance_eval {
	@header['k'] = ['v']
      }
      eq('v', req['k'])

      req.instance_eval {
	@header['k'] = ['v1', 'v2']
      }
      eq('v1, v2', req['k'])
    end
  end
end
