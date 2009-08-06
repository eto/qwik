# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

require 'webrick'

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module WEBrick
  class BasicLog
    # FIXEM: Ad hoc reopen support.
    def reopen
      log_file = @log.path
      @log.close
      @log = open(log_file, "a+")
      @log.sync = true
      @opened = true
    end
  end

  class HTTPRequest
    # copied from gonzui-0.1
    # FIXME: it should be deleted if WEBrick supports the method
    def parse_accept_language
      if self['Accept-Language']
        tmp = []
        parts = self['Accept-Language'].split(/,\s*/)
        parts.each {|part|
          if m = /\A([\w-]+)(?:;q=([\d]+(?:\.[\d]+)))?\z/.match(part)
            lang = m[1]
            q = (m[2] or 1).to_f
            tmp.push([lang, q])
          end
        }
        @accept_language = 
          tmp.sort_by {|lang, q| q}.map {|lang, q| lang}.reverse
      else
        @accept_language = ['en'] # FIXME: should be customizable?
      end
    end

   #DEFINE_ACCEPT_LANGUAGE = true
    DEFINE_ACCEPT_LANGUAGE = false
    if DEFINE_ACCEPT_LANGUAGE || ! defined?(:accept_language)
      def accept_language
	if !defined?(@accept_language) || @accept_language.nil? ||
	    @accept_language.empty?
	  parse_accept_language
	end
	return @accept_language
      end
    end

    def gzip_encoding_supported?
      /\bgzip\b/.match(self['accept-encoding'])
    end
  end

  # from webrick/httputils.rb
  module HTTPUtils
    undef parse_header
    # FIXME: it should be deleted if WEBrick fix the problem
    def parse_header(raw)
      header = Hash.new([].freeze)
      field = nil
      raw.each{|line|
        case line
       #when /^([A-Za-z0-9_\-]+):\s*(.*?)\s*\z/om
       #when /^([A-Za-z0-9_\-\!\#\$\%\&\'\*\+\.\^\`\|\~]+):\s*(.*?)\s*\z/om
        when /^([A-Za-z0-9_\-~]+):\s*(.*?)\s*\z/om
          field, value = $1, $2
          field.downcase!
          header[field] = [] unless header.has_key?(field)
          header[field] << value
        when /^\s+(.*?)\s*\z/om
          value = $1
          unless field
            raise "bad header '#{line.inspect}'."
          end
          header[field][-1] << ' ' << value
        else
          raise "bad header '#{line.inspect}'."
        end
      }
      header.each{|key, values|
        values.each{|value|
          value.strip!
          value.gsub!(/\s+/, ' ')
        }
      }
      header
    end
    module_function :parse_header

    undef parse_query
    # FIXME: it should be deleted if WEBRick fix the problem
    def parse_query(str)
      query = Hash.new
      if str
        str.split(/[&;]/).each{|x|
          key, val = x.split(/=/,2)
	  next if key.nil?
          key = unescape_form(key)
          val = unescape_form(val.to_s)
          val = FormData.new(val)
          val.name = key
          if query.has_key?(key)
            query[key].append_data(val)
            next
          end
          query[key] = val
        }
      end
      query
    end
    module_function :parse_query
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  $test = true
end

if defined?($test) && $test
  class TestHTTPUtils < Test::Unit::TestCase
    def test_parse_accept_language
      request = WEBrick::HTTPRequest.new(WEBrick::Config::HTTP)
      request.instance_eval {
        @header = WEBrick::HTTPUtils::parse_header('Accept-Language: ja')
	@accept_language = WEBrick::HTTPUtils.parse_qvalues(self['accept-language'])
      }
      ok_eq(['ja'], request.accept_language)

      request.instance_eval {
        @header = WEBrick::HTTPUtils::parse_header('Accept-Language: ja,en-us;q=0.7,en;q=0.3')
	@accept_language = WEBrick::HTTPUtils.parse_qvalues(self['accept-language'])
      }
      ok_eq(['ja', 'en-us', 'en'], request.accept_language)

      request.instance_eval {
        @header = WEBrick::HTTPUtils::parse_header('Accept-Language: ja,en-us;q=0.7,en;q=0.9')
	@accept_language = WEBrick::HTTPUtils.parse_qvalues(self['accept-language'])
      }
      ok_eq(['ja', 'en', 'en-us'], request.accept_language)
    end

    def test_gzip_encofing_supported?
      request = WEBrick::HTTPRequest.new(WEBrick::Config::HTTP)
      request.instance_eval {
        @header = WEBrick::HTTPUtils::parse_header('Accept-Encoding: gzip, deflate')
      }
      ok_eq('gzip, deflate', request['accept-encoding'])
      ok_eq(true, !!request.gzip_encoding_supported?)
    end

    def test_parse_header
      ok_eq("{\"header\"=>[\"content\"]}",
	    WEBrick::HTTPUtils::parse_header('Header: content').inspect)
      ok_eq('{"~"=>["~"]}',
	    WEBrick::HTTPUtils::parse_header("~: ~\r\n").inspect)

      # real situation
      str = <<EOS
Accept: */*
Accept-Language: ja
~~~~~~~~~~: ~~~~~~~~~~
EOS
      ok_eq({"accept-language"=>["ja"], "accept"=>["*/*"], "~~~~~~~~~~"=>["~~~~~~~~~~"]}, WEBrick::HTTPUtils::parse_header(str))
    end

    def test_parse_query
      ok_eq({'a'=>'b'}, WEBrick::HTTPUtils::parse_query('&a=b'))
    end
  end
end
