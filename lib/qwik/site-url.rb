# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

require 'uri'

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Site
    def host_url
      host_url =  self.siteconfig['siteurl']
      if ! host_url.nil? && host_url.empty?
	host_url = @config.public_url
      end
      uri = URI(host_url)
      uri.path = ""
      return uri.to_s
    end

    def site_url
      siteurl = self.siteconfig['siteurl']
      return siteurl if ! siteurl.nil? && ! siteurl.empty?
      return "#{@config.public_url}#{self.url_path}"
    end

    def page_url(k)
      return "#{self.site_url}#{k}.html"
    end

    def url_path
      siteurl = self.siteconfig['siteurl']
      return '' if siteurl.nil?
      return '' if ! siteurl.empty? || self.top_site?
      return "#{@sitename}/"
    end

    def ml_address
      siteml = self.siteconfig['siteml']
      return siteml if ! siteml.nil? && ! siteml.empty?
      return "#{@sitename}@#{@config.ml_domain}"
    end

    def title
      sitetitle = self.siteconfig['sitename']
      if ! sitetitle.nil? && sitetitle.empty?
	return '' if @config.test
	sitetitle = self.site_url.sub(%r|\Ahttp://|, "").sub(%r|/\z|, "")
	#sitetitle = sitetitle.sub(%r|\Awww\.|, "")
      end
      return sitetitle
    end

    def get_page_title(pagename)
      page = self[pagename]
      return '' if page.nil?
      page_title = page.get_title

      sitetitle = self.title
      if ! sitetitle.empty?
	if self.siteconfig['page_title_first'] == 'true'
	  return "#{page_title} - #{sitetitle}"
	else
	  return "#{sitetitle} - #{page_title}"
	end
      end

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
      eq 'http://example.com', site.host_url
      eq 'http://example.com/test/', site.site_url
      eq 'http://example.com/test/1.html', site.page_url('1')
      eq 'test@q.example.com', site.ml_address
      t_without_testmode {
	eq 'example.com/test', site.title
	eq '1 - example.com/test', site.get_page_title('1')
      }

      siteconfig = site.create('_SiteConfig')
      siteconfig.store(":sitename:t\n")
      t_without_testmode {
	eq 't', site.title
	eq '1 - t', site.get_page_title('1')
      }
    end

    def test_get_page_title
      site = @site
      page = site.create_new
      t_without_testmode {
	eq '1 - example.com/test', site.get_page_title('1')
      }

      siteconfig = site.create('_SiteConfig')
      siteconfig.store(":page_title_first:true\n")
      t_without_testmode {
	eq '1 - example.com/test', site.get_page_title('1')
      }

      siteconfig.store(":page_title_first:false\n")
      t_without_testmode {
	eq 'example.com/test - 1', site.get_page_title('1')
      }
    end

    def test_url_top_site
      site = @memory.farm.get_top_site
      page = site.create_new
      eq true, site.top_site?
      eq 'http://example.com', site.host_url
      eq 'http://example.com/', site.site_url
      eq 'http://example.com/1.html', site.page_url('1')
      eq 'www@q.example.com', site.ml_address
      t_without_testmode {
	eq 'example.com', site.title
	eq '1 - example.com', site.get_page_title('1')
      }
    end

    def test_url_siteurl
      page = @site.create_new
      t_with_siteurl {
	eq 'http://example.org', @site.host_url
	eq 'http://example.org/q/', @site.site_url
	eq 'http://example.org/q/1.html', @site.page_url('1')
	eq 'test@q.example.com', @site.ml_address		# FIXME: Umm.
	siteconfig = @site['_SiteConfig']
	siteconfig.add(":siteml:info@example.org\n")
	eq 'info@example.org', @site.ml_address
	t_without_testmode {
	  eq 'example.org/q', @site.title
	  eq '1 - example.org/q', @site.get_page_title('1')
	}
      }
    end

    def test_https
      site = @site
      page = site.create_new
      siteconfig = site.create('_SiteConfig')
      siteconfig.store(":siteurl:https://example.net/\n")
      eq 'https://example.net', site.host_url
      eq 'https://example.net/', site.site_url
      eq 'https://example.net/1.html', site.page_url('1')
      eq 'test@q.example.com', site.ml_address		# FIXME: Umm.
      siteconfig.add(":siteml:info@example.net\n")
      eq 'info@example.net', site.ml_address
      t_without_testmode {
	eq 'https://example.net', site.title
	eq '1 - https://example.net', site.get_page_title('1')
      }
    end

    def test_url_example_org_with_path
      t_with_path {
	site = @site
	page = site.create_new
	eq 'http://www.example.org', site.host_url
	eq 'http://www.example.org/qwik/test/', site.site_url
	eq 'http://www.example.org/qwik/test/1.html', site.page_url('1')
	eq 'test@q.example.com', site.ml_address
	t_without_testmode {
	  eq 'www.example.org/qwik/test', site.title
	  eq '1 - www.example.org/qwik/test', site.get_page_title('1')
	}
      }
    end
  end
end
