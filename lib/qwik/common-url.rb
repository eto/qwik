# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

require 'uri'

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    # 1.html -> /test/1.html
    def c_relative_to_root(url)
      return url if /\A\// =~ url	# It's already from root path.
      uri = URI(@config.public_url)
      return "#{uri.path}#{@site.url_path}#{url}"
    end

    # 1.html -> http://example.com/test/1.html
    def c_relative_to_absolute(url)
      if /\Ahttp:\/\// =~ url || /\Ahttps:\/\// =~ url
	return url		# It's already absolute URL.
      end

      # make absolute url
      fromrootpath = c_relative_to_root(url)
      return "#{@site.host_url.chomp('/')}#{fromrootpath}"
    end

    def is_valid_url?(str)
      return %r!\Ahttp://[\-\_\.\/\?A-Za-z]+\z! =~ str
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActUrl < Test::Unit::TestCase
    include TestSession

    def test_normal_site
      res = session
      eq '/test/1.html', @action.c_relative_to_root('1.html')
      eq 'http://example.com/test/1.html',
	@action.c_relative_to_absolute('1.html')
    end

    def test_top_site
      res = session
      @action.instance_eval {
	@site = @memory.farm.get_top_site
      }
      eq '/1.html', @action.c_relative_to_root('1.html')
      eq 'http://example.com/1.html', @action.c_relative_to_absolute('1.html')
    end

    def test_external_site
      res = session
      page = @site['_SiteConfig']
      page.store(':siteurl:http://example.org/')
      eq '/1.html', @action.c_relative_to_root('1.html')
      eq 'http://example.org/1.html', @action.c_relative_to_absolute('1.html')
    end

    def test_with_path
      t_with_path {
	res = session
	eq '/qwik/test/1.html', @action.c_relative_to_root('1.html')
	eq 'http://www.example.org/qwik/test/1.html',
	  @action.c_relative_to_absolute('1.html')
      }
    end

    def test_anomaly
      res = session
      eq '/.theme', @action.c_relative_to_root('/.theme')
      eq 'http://example.gov/',
	@action.c_relative_to_absolute('http://example.gov/')
    end

    def test_is_valid_url?
      res = session
      eq true, !!@action.is_valid_url?('http://e.com/')
      eq true, !!@action.is_valid_url?("http://e.com/?")
    end
  end
end
