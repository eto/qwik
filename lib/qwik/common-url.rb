#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

require 'uri'

$LOAD_PATH << '../../lib' unless $LOAD_PATH.include?('../../lib')

module Qwik
  class Action
    # 1.html -> /test/1.html
    def c_relative_to_absolute(url)
      return url if /\A\// =~ url	# It's already absolute.
      uri = URI(@config.public_url)
      return uri.path+@site.url_path+url
    end

    # 1.html -> http://example.com/test/1.html
    def c_relative_to_full(url)
      if /\Ahttp:\/\// =~ url || /\Ahttps:\/\// =~ url
	return url	# It's already full URL.
      end

      # check siteurl
      siteurl = @site.siteconfig['siteurl']
      if ! siteurl.empty?
	siteurl = siteurl.chomp('/')
	url = c_relative_to_absolute(url)
	return siteurl+url
      end

      # make full url
      c = @config
      path = c_relative_to_absolute(url)
      host = @site.host_url
      url = host.chop+path
      return url
    end

    def is_valid_url?(str)
      return (%r!\Ahttp://[\-\_\.\/\?A-Za-z]+\z! =~ str) != nil
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
      ok_eq('/test/1.html', @action.c_relative_to_absolute('1.html'))
      ok_eq('http://example.com/test/1.html',
	    @action.c_relative_to_full('1.html'))
    end

    def test_top_site
      res = session
      @action.instance_eval {
	@site = @memory.farm.get_top_site
      }
      ok_eq('/1.html', @action.c_relative_to_absolute('1.html'))
      ok_eq('http://example.com/1.html',
	    @action.c_relative_to_full('1.html'))
    end

    def test_external_site
      res = session
      page = @site['_SiteConfig']
      page.store(':siteurl:http://example.org/')
      ok_eq('/1.html', @action.c_relative_to_absolute('1.html'))
      ok_eq('http://example.org/1.html', @action.c_relative_to_full('1.html'))
    end

    def test_anomaly
      res = session
      ok_eq('/.theme', @action.c_relative_to_absolute('/.theme'))
      ok_eq('http://example.gov/',
	    @action.c_relative_to_full('http://example.gov/'))
    end

    def test_is_valid_url?
      res = session
      ok_eq(true, @action.is_valid_url?('http://e.com/'))
      ok_eq(true, @action.is_valid_url?("http://e.com/?"))
    end
  end
end
