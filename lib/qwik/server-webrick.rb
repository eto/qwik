# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/util-webrick'

module Qwik
  class WEBrickRequest < WEBrick::HTTPRequest
    attr_writer :request_uri, :path, :peeraddr
    attr_writer :request_method, :cookies, :header, :query
    attr_writer :user
  end

  class WEBrickResponse < WEBrick::HTTPResponse
    def set_config
      @config.update(WEBrick::Config::HTTP)
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
  class TestWEBrickRequest < Test::Unit::TestCase
    def ok_req(e, req)
      ok_eq(e, [req.sitename, req.base, req.ext])
    end

    def setup_server
      config = Qwik::Config.new
      config[:debug] = true
      config[:test]  = true	# do not show webrick log

      server_config = {}

      req = Qwik::Request.new(config)

      return config, server_config, req
    end

    def test_parse_webrick
      config, server_config, req = setup_server

      wreq = Qwik::WEBrickRequest.new(server_config)
      wreq.request_uri = URI.parse('http://example.com/')
      wreq.path = '/'
      req.parse_webrick(wreq)
      ok_req(['www', 'FrontPage', 'html'], req)

      wreq.request_uri = URI.parse('http://example.com/test/1.html')
      wreq.path = '/test/1.html'
      req.parse_webrick(wreq)
      ok_req(['test', '1', 'html'], req)
    end

    def test_parse_webrick_env
      config, server_config, req = setup_server

      wreq = Qwik::WEBrickRequest.new(server_config)
      wreq.path = '/'
      wreq.peeraddr = [nil, nil, nil, '192.168.0.1']
      req.parse_webrick(wreq)

      wreq.request_method = 'POST'
      req.parse_webrick(wreq)
      ok_eq('POST', req.request_method)

      wreq.request_method = 'HEAD'
      req.parse_webrick(wreq)
      ok_eq('HEAD', req.request_method)

      wreq.request_method = 'GET'
      req.parse_webrick(wreq)
      ok_eq('GET', req.request_method)

      wreq.header = {'x-test' => ['t']}
      req.parse_webrick(wreq)
      ok_eq('t', req['X-Test'])

      wreq.cookies = []
      wreq.cookies << WEBrick::Cookie.new('s', 't')
      wreq.cookies << WEBrick::Cookie.new('k', 'v')
      req.parse_webrick(wreq)
      ok_eq('t', req.cookies['s'])
      ok_eq('v', req.cookies['k'])

      wreq.query = {'k' => 'v'}
      req.parse_webrick(wreq)
      ok_eq('v', req.query['k'])

      wreq.query = {'c' => 'edit'}
      req.parse_webrick(wreq)
      ok_eq('edit', req.query['c'])
    end
  end
end
