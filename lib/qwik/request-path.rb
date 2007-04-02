# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class UnknownPathException < Exception; end

  class Request
    attr_reader :sitename
    attr_accessor :base
    attr_reader :ext
    attr_accessor :plugin
    attr_reader :ext_args
    attr_accessor :path_args
    attr_reader :path_query
    attr_reader :unparsed_uri

    def parse_path(path)
      if @unparsed_uri.nil?
	@unparsed_uri = path	# for test
      end

      @sitename, @base, @ext, @plugin, @path_args, @path_query, @ext_args =
	Request.parse_path(path, @config.default_sitename)

      return [@sitename, @base, @ext]	# only for test
    end

    def self.parse_path(path, default_sitename)
      raise "first character must be '/'" unless path[0] == ?/

      path = remove_quote(path)

      path = normalize_path(path)	# for security

      # OBSOLETE: Patch for redirect plugin (old format).
      if /\A\/((?:http|https|ftp|file):\/.+)\z/ =~ path
	return [default_sitename, '', '', 'redirect', [$1], {}, []]
      end

      pas = path.split('/')
      pas.shift		# Drop the first null element.

      # Ad hoc: Error handling.
      if pas.length == 1
	if ! pas.first.include?('.') && /\/\z/ !~ path
	  return [default_sitename, pas.first, '', nil, [], {}, []]
	end
      end

      sitename = base = ext = plugin = nil
      path_args = []
      path_query = {}
      ext_args = []

      pas.each_with_index {|pa, i|
	if plugin || ext
	  # path_args is catch all.
	  path_args << pa
	  next
	end

	# Maybe sitename.
	if i == 0
	  if Request.sitename?(pa)
	    sitename = pa
	  end
	  next if sitename	# Skip.
	end

	ff = pa.split('.')

	# No end with dot.
	if ff[1].nil? || ff[1].empty?
	  if ff[0] == 'theme' || ff[0] == 'attach'
	    ff = ['', ff[0]]
	  else
	    base = ''
	    ext = ''
	    return [sitename, base, ext, plugin, path_args, path_query, ext_args]
	  end
	end

	# Start with dot -> Action plugin.
	if ff[0].empty?
	  raise 'no two action' unless plugin.nil?	# No two plugins.
	  plugin = ff[1]
	  next
	end

	# Accept only two.
	if 2 < ff.length
	  base = ff.shift
	  ext = ff.pop
	  ext_args = ff
	  next
	end

	raise 'base should be one.' if base	# base should be one.
	base = ff[0]
	ext = ff[1]
      }

      # sitename is not specified.
      sitename = default_sitename if sitename.nil?

      if base.nil?
	base, ext = ['FrontPage', 'html']
      end

      path_args.each {|pa|
	ff = pa.split('=')
	if ff.length == 2
	  path_query[ff.first] = ff.last
	end
      }

      base.set_url_charset

      return [sitename, base, ext, plugin, path_args, path_query, ext_args]
    end

    private

    def init_path
      @sitename = nil
      @base = nil
      @ext = nil
      @plugin = nil
      @ext_args = []
      @path_args = []
      @path_query = {}
      @unparsed_uri = nil
    end

    # For Excite Translate Bug.
    def self.remove_quote(path)
      if /\A(.+)\"(.+)\"\z/ =~ path
	return $1+$2
      end
      return path
    end

    # copied from webrick/httputils.rb
    def self.normalize_path(path)
      raise "abnormal path `#{path}'" if path[0] != ?/
      ret = path.dup

      ret.gsub!(%r{/+}o, '/')                    # //      => /
      while ret.sub!(%r:/\.(/|\z):o, '/'); end   # /.      => /
      begin                                      # /foo/.. => /foo
        match = ret.sub!(%r{/([^/]+)/\.\.(/|\z)}o){
          if $1 == '..'
            raise "abnormal path `#{path}'"
          else
            '/'
          end
        }
      end while match

      raise "abnormal path `#{path}'" if %r{/\.\.(/|\z)} =~ ret
      return ret
    end

    def self.sitename?(pa)
      ff = pa.split('.')
      return false if ff.first.empty? # action
      len = ff.length
      return true if len == 1
      # contain dot, and last is com or jp is external site
      return true if 1 < len && %w(com jp).include?(ff.last)
      return false
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
  require 'qwik/test-module-public'

  class TestRequestPath < Test::Unit::TestCase
    include TestModulePublic

    def test_class_method
      c = Qwik::Request
      ok_eq('a',   c.remove_quote('a'))
      ok_eq("\"a\"", c.remove_quote("\"a\""))
      ok_eq('ab',  c.remove_quote("a\"b\""))
      ok_eq("'a'", c.remove_quote("'a'"))
    end

    def test_all
      config = Qwik::Config.new
      req = Qwik::Request.new(config)

      # test_parse_path
#      t_make_public(Qwik::Request, :parse_path)
      ok_eq(['www', 'FrontPage', 'html'], req.parse_path('/'))
      ok_eq(['www', 'FrontPage', 'html'],
	    req.parse_path('/FrontPage.html'))
      ok_eq(['test', 't', 'html'], req.parse_path('/test/t.html'))
      ok_eq(['test', 'FrontPage', 'html'], req.parse_path('/test/'))
      ok_eq(['www', 'test', ''], req.parse_path('/test'))
      ok_eq(['test', 'FrontPage', 'html'],
	    req.parse_path('/test/FrontPage.html'))
      ok_eq(['example.com', 'FrontPage', 'html'],
	    req.parse_path('/example.com/'))
      ok_eq(['www.example.com', 'FrontPage', 'html'],
	    req.parse_path('/www.example.com/'))

      # test_theme_plugin
      req.parse_path('/.theme/all.css')
      ok_eq(['theme', ['all.css']], [req.plugin, req.path_args])
      ok_eq(['www', 'FrontPage', 'html'],
	    req.parse_path('/.theme/all.css'))

      req.parse_path('/.theme/qwikgreen/qwikgreen.css')
      ok_eq(['theme', ['qwikgreen', 'qwikgreen.css']],
	    [req.plugin, req.path_args])

      req.parse_path('/.login')
      ok_eq(['login', []], [req.plugin, req.path_args])

      req.parse_path('/.login/user@e.com/44484125/')
      ok_eq(['login', ['user@e.com', '44484125']],
	    [req.plugin, req.path_args])

      ok_eq(['www', 'FrontPage', 'html'],
	    req.parse_path('/FrontPage.html/sid=000/'))
      ok_eq(['sid=000'], req.path_args)
      ok_eq({'sid'=>'000'}, req.path_query)

      # test_parse_plugin
      assert_raise(RuntimeError){ req.parse_path('test/') }
      ok_eq(['test', 'FrontPage', 'html'],
	    req.parse_path('/test/.attach/t.txt'))
      ok_eq(['attach', ['t.txt']], [req.plugin, req.path_args])
      ok_eq(['www', 'FrontPage', 'html'],
	    req.parse_path('/.attach/s.jpg'))
      ok_eq(['attach', ['s.jpg']], [req.plugin, req.path_args])

      ok_eq(['www', 'FrontPage', 'html'], req.parse_path('/.new'))
      ok_eq(['new', []], [req.plugin, req.path_args])

      ok_eq(['test', 'test', 'zip'], req.parse_path('/test/test.zip'))
      ok_eq('zip', req.ext)

      ok_eq(['www', 'test', 'zip'], req.parse_path('/test.zip'))
      ok_eq('zip', req.ext)

      ok_eq(['e.com', 'FrontPage', 'html'],
	    req.parse_path('/e.com/.attach/t.png'))
      ok_eq(['attach', ['t.png']],
	    [req.plugin, req.path_args])

      ok_eq(['www', 'www', 'zip'], req.parse_path('/www.zip'))
      ok_eq(['www', 'www', 'rss'], req.parse_path('/www.rss'))

      ok_eq(['www', 'favicon', 'ico'], req.parse_path('/favicon.ico'))

      # test_attach
      ok_eq(['www', 'FrontPage', 'html'],
	    req.parse_path('/.attach/s.jpg'))
      ok_eq(['attach', ['s.jpg']], [req.plugin, req.path_args])

      ok_eq(['www', 'FrontPage', 'html'],
	    req.parse_path('/.attach/thumb/s.jpg'))
      ok_eq(['attach', ['thumb', 's.jpg']],
	    [req.plugin, req.path_args])

      # test_parse_sitename
      c = Qwik::Request
      ok_eq(true,  c.sitename?('test'))
      ok_eq(true,  c.sitename?('e.com'))
      ok_eq(true,  c.sitename?('www.e.com'))
      ok_eq(false, c.sitename?('www.new'))
      ok_eq(false, c.sitename?('www.zip'))
      ok_eq(false, c.sitename?('www.rss'))
      ok_eq(false, c.sitename?('hoge.1.backup'))

      # test_ext_args
      ok_eq(['www', 'hoge', 'backup'],
	    req.parse_path('/hoge.backup'))
      ok_eq([], req.ext_args)

      ok_eq(['www', 'hoge', 'backup'],
	    req.parse_path('/hoge.1.backup'))
      ok_eq(['1'], req.ext_args)

      ok_eq(['test', 'hoge', 'backup'],
	    req.parse_path('/test/hoge.1.backup'))
      ok_eq(['1'], req.ext_args)

    end
  end
end
