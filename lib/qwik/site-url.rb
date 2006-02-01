#
# Copyright (C) 2003-2006 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Site
    def host_url
      siteurl = self.siteconfig['siteurl']
      return siteurl if ! siteurl.empty?
      return @config.public_url
    end

    def site_url
      siteurl = self.siteconfig['siteurl']
      return siteurl if ! siteurl.empty?
      return @config.public_url+self.url_path
    end

    def page_url(k)
      return "#{self.site_url}#{k}.html"
    end

    def url_path
      siteurl = self.siteconfig['siteurl']
      return '' if ! siteurl.empty? || self.top_site?
      return "#{@sitename}/"
    end

    def ml_address
      siteml = self.siteconfig['siteml']
      return siteml if ! siteml.empty?
      return "#{@sitename}@#{@config.ml_domain}"
    end

    def title
      sitetitle = self.siteconfig['sitename']
      if sitetitle.empty?
	return '' if @config.test
	sitetitle = self.site_url.sub(%r|\Ahttp://|, "").sub(%r|/\z|, "")
      end
      return sitetitle
    end

    def get_page_title(pagename)
      page = self[pagename]
      return '' if page.nil?
      page_title = page.get_title

      sitetitle = self.title
      return "#{sitetitle} - #{page_title}" if ! sitetitle.empty?

      return page_title
    end

    def top_site?
      return (@sitename == @config.default_sitename)
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-module-session'
  require 'qwik/farm'
  $test = true
end

if defined?($test) && $test
  class TestSiteUrl < Test::Unit::TestCase
    include TestSession

    def test_url_test
      site = @site
      page = site.create_new
      ok_eq('http://example.com/', site.host_url)
      ok_eq('http://example.com/test/', site.site_url)
      ok_eq('http://example.com/test/1.html', site.page_url('1'))
      ok_eq('test@example.com', site.ml_address)
      t_without_testmode {
	ok_eq('example.com/test', site.title)
	ok_eq('example.com/test - 1', site.get_page_title('1'))
      }

      siteconfig = site.create('_SiteConfig')
      siteconfig.store(":sitename:t\n")
      t_without_testmode {
	ok_eq('t', site.title)
	ok_eq('t - 1', site.get_page_title('1'))
      }
    end

    def test_url_top_site
      site = @memory.farm.get_top_site
      page = site.create_new
      ok_eq(true, site.top_site?)
      ok_eq('http://example.com/', site.host_url)
      ok_eq('http://example.com/', site.site_url)
      ok_eq('http://example.com/1.html', site.page_url('1'))
      ok_eq('www@example.com', site.ml_address)
      t_without_testmode {
	ok_eq('example.com', site.title)
	ok_eq('example.com - 1', site.get_page_title('1'))
      }
    end

    def test_url_example_org
      site = @site
      page = site.create_new
      siteconfig = site.create('_SiteConfig')
      siteconfig.store(":siteurl:http://example.org/\n")
      ok_eq('http://example.org/', site.host_url)
      ok_eq('http://example.org/', site.site_url)
      ok_eq('http://example.org/1.html', site.page_url('1'))
      ok_eq('test@example.com', site.ml_address)	# FIXME: Umm.
      siteconfig.add(":siteml:info@example.org\n")
      ok_eq('info@example.org', site.ml_address)
      t_without_testmode {
	ok_eq('example.org', site.title)
	ok_eq('example.org - 1', site.get_page_title('1'))
      }
    end

    def test_https
      site = @site
      page = site.create_new
      siteconfig = site.create('_SiteConfig')
      siteconfig.store(":siteurl:https://example.net/\n")
      ok_eq('https://example.net/', site.host_url)
      ok_eq('https://example.net/', site.site_url)
      ok_eq('https://example.net/1.html', site.page_url('1'))
      ok_eq('test@example.com', site.ml_address)	# FIXME: Umm.
      siteconfig.add(":siteml:info@example.net\n")
      ok_eq('info@example.net', site.ml_address)
      t_without_testmode {
	ok_eq('https://example.net', site.title)
	ok_eq('https://example.net - 1', site.get_page_title('1'))
      }
    end
  end
end
