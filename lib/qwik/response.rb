# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

require 'webrick/cookie'

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/config'
require 'qwik/wabisabi-format-xml'

module Qwik
  class Response
    COOKIE_EXP = 60*60*24*30 # 30 days

    MIME_TYPES = {
      'smil'	=> 'application/smil',
      'swf'	=> 'application/x-shockwave-flash',
#      'ico'	=> 'image/bitmap',		# FIXME: Is this OK?
      'ico'	=> 'image/vnd.microsoft.icon',
      'png'	=> 'image/png',
      '3gp'	=> 'video/3gpp',
      'tgz'	=> 'application/octet-stream',
      'gz'	=> 'application/octet-stream',
      'mdlb'	=> 'application/x-modulobe',
    }

    def initialize(config)
      @config = config
      clear
    end
    attr_accessor :body, :status
    attr_reader :headers # for test
    attr_reader :cookies # for test
    attr_accessor :basicauth
    attr_accessor :sessionid

    def clear
      @body = nil
      @status = 200
      @cookies = []
      @headers = {}
      @mimetypes = {}
      @basicauth = nil
      @sessionid = nil
    end

    def set_webrick(response)
      make_mimetypes(response.config[:MimeTypes])
    end

    def make_mimetypes(mimetypes)
      @mimetypes = mimetypes
      @mimetypes.update(MIME_TYPES)
    end

    def get_mimetypes(ext)
      @mimetypes[ext.downcase]
    end

    def set_content_type(ext)
      mtype = get_mimetypes(ext)	# Get content type.
      @headers['Content-Type'] = mtype
    end

    def [](k)
      return @headers[k]
    end

    def []=(k, v)
      @headers[k] = v
    end

    def set_cookies(user, pass)
      set_cookie('user', user)
      set_cookie('pass', pass)
    end

    def set_cookie(k, v)
      @cookies << make_cookie(k, v)
    end

    def clear_cookies
      # Set cookies to 1 hour ago, to clear cookies from browser.
      clear_cookie('user')
      clear_cookie('pass')
      clear_cookie('sid')
    end

    def clear_cookie(k)
      @cookies << make_cookie(k, '', -60*60)
    end

    def make_cookie(k, v, exp=COOKIE_EXP)
      c = WEBrick::Cookie.new(k, v)
      c.path = '/'
      c.expires = Time.now + exp
      return c
    end
    private :make_cookie

    def setback_body(body)
      case body
      when Array # wabisabi
	return body.format_xml
      when File
	return body # do not convert
      when String
	return body
      when IO
	return body
      else
	return body.to_s
      end
    end

    def setback(response)
      response.body = setback_body(@body)
      response.status = @status
      @cookies.each {|c| response.cookies << c }
      @headers.each {|k, v| response[k] = v }
      #imitate_apache_header_order(response.header)
    end

    def imitate_apache_header_order(h)
      def h.each
	h = {}
	super {|k, v|
	  h[k] = v
	}

	pre_header = %w(date server)
	post_header = %w(etag last-modified location cache-control pragma keep-alive transfer-encoding content-encoding content-length connection content-type)

	ar = []
	pre_header.each {|k|
	  if h[k]
	    ar << [k, h[k]]
	    h.delete(k)
	  end
	}

	postar = []
	post_header.each {|k|
	  if h[k]
	    postar << [k, h[k]]
	    h.delete(k)
	  end
	}

	h.each {|k, v|
	  ar << [k, v]
	}

	ar += postar

	ar.each {|k, v|
	  yield(k, v)
	}
      end
    end
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  $test = true
end

if defined?($test) && $test
  class TestResponse < Test::Unit::TestCase
    def test_all
      config = Qwik::Config.new
      res = Qwik::Response.new(config)

      # test_mimetypes
      mt = {}
      res.make_mimetypes(mt)
      ok_eq('application/x-shockwave-flash', mt['swf'])
      ok_eq('application/smil', mt['smil'])
      ok_eq('image/vnd.microsoft.icon', mt['ico'])
      ok_eq('image/png', mt['png'])
      ok_eq('video/3gpp', mt['3gp'])

      # test_headers
      res['X-Test-Header'] = 't1'
      ok_eq('t1', res['X-Test-Header'])
      res.clear
      ok_eq(nil, res['X-Test-Header'])

      # test_cookie
      res.set_cookies('t@e.com', 'testpass')
      ok_eq(2, res.cookies.length)
      res.clear_cookies
      #ok_eq(4, res.cookies.length)
      res.clear
      ok_eq(0, res.cookies.length)

      # test_setback
      ok_eq('', res.setback_body([]))
      ok_eq("<t\n></t\n>", res.setback_body([:t, ""]))
      ok_eq('t', res.setback_body('t'))
      ok_eq('', res.setback_body(nil))
    end

    def test_mimetypes
      config = Qwik::Config.new
      res = Qwik::Response.new(config)

      require 'webrick/httputils'

      default_mimetypes = WEBrick::HTTPUtils::DefaultMimeTypes
      res.make_mimetypes(default_mimetypes)

      # Check mimetypes.
      ok_eq('text/html', res.get_mimetypes('html'))
      ok_eq('text/plain', res.get_mimetypes('txt'))
      ok_eq('text/css', res.get_mimetypes('css'))
      ok_eq('image/gif', res.get_mimetypes('gif'))
      ok_eq('image/png', res.get_mimetypes('png'))
      ok_eq('image/jpeg', res.get_mimetypes('jpg'))
      ok_eq('image/jpeg', res.get_mimetypes('JPG'))	# Check upcase
      ok_eq('image/jpeg', res.get_mimetypes('JPEG'))	# Check upcase
      ok_eq('application/smil', res.get_mimetypes('smil'))
      ok_eq('application/zip', res.get_mimetypes('zip'))
      ok_eq('application/x-modulobe', res.get_mimetypes('mdlb'))
    end
  end
end
