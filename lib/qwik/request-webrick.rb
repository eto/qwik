# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/request'
require 'qwik/util-charset'

module Qwik
  class Request
    # request is a WEBrick::HTTPRequest
    def parse_webrick(request)
      host = ''
      host = request.request_uri.host if request.request_uri

      @unparsed_uri = request.unparsed_uri

      begin
	parse_path(request.path)
      rescue
      end

      @header = request.header.dup if request.header

      @useragent = UserAgent.new(self)

      if request.accept_language && ! request.accept_language.empty?
	@accept_language = request.accept_language
      elsif @useragent.mobile
	@accept_language = ['ja']
      end

      @request_method = request.request_method
      request.cookies.each {|c| @cookies[c.name] = c.value }
      @query = request.query.dup
      @query.each {|k, v|
	v.set_url_charset
      }

      @user = @pass = nil

      @fromhost = Request.get_fromhost(request, self['x-forwarded-for'])
      @request_line = Request.get_request_line(request)
    end

    def self.get_fromhost(request, forwarded_from)
      if forwarded_from
	forwarded_from.gsub!(/, /, ',')
	return forwarded_from
      end
      peer = request.peeraddr
      return peer[2] if peer
      return '127.0.0.1'
    end

    def self.get_request_line(request)
      return '' if request.request_line.nil?
      request_line = request.request_line.sub(/\x0d?\x0a\z/o, '')
      request_line = request_line.sub(/ HTTP\/1\..\z/o, '')
      return request_line
    end
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  $test = true
end

if defined?($test) && $test
  class TestRequestWEBrick < Test::Unit::TestCase
    def test_all
      config = Qwik::Config.new
      req = Qwik::Request.new(config)

      c = Qwik::Request

      # not yet
    end
  end
end
