# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    def plg_rss
      return rss_button('rss.xml', 'RSS')
    end

    def plg_atom
      return rss_button('atom.xml', 'ATOM')
    end

    def rss_button(href, msg)
      return [:a, {:class=>'rss-button', :href=>href},
	[:span, msg]]
    end

    def metadata_clear_cache
      path = @site.cache_path + "rss.xml"
      path.unlink if path.exist?
      path = @site.cache_path + "atom.xml"
      path.unlink if path.exist?
    end

    def pre_ext_xml
      method = "metadata_#{@req.base}_#{@req.ext}"
      return c_nerror(_('Error')) if ! self.respond_to?(method)
      
      site_cache_path = @site.cache_path
      site_cache_path.check_directory
      feed_filename = "#{@req.base}.#{@req.ext}"
      feed_path = site_cache_path + feed_filename

      if ! feed_path.exist?
        feed = self.send(method)
        feed_string = feed.format_xml.page_to_xml
        feed_path.write(feed_string)
      end

      return c_simple_send(feed_path, 'application/xml')
    end

    def metadata_rss_xml
      return @site.metadata.generate_rss20
    end

    def metadata_atom_xml
      return @site.metadata.generate_atom
    end
  end

  class Site
    def metadata
      return SiteMetaData.new(@config, self)
    end
  end

  class SiteMetaData
    def initialize(config, site)
      @config = config
      @site = site
      init_internal
    end
    attr_reader :title, :site_url, :last_build_date
    attr_reader :description
    attr_reader :last_build_date
    attr_reader :pub_date
    attr_reader :generator

    def generate_rss20
      init_internal

      xml = []
      xml << [:'?xml', '1.0', 'utf-8']
      rss = [:rss, {:version=>'2.0'}]

      channel = [:channel,
	[:title, @title],
	[:link, @site_url],
	[:description, @description],
	[:language, @language],
	[:pubdate, @pub_date],
	[:lastbuilddate, @last_build_date],
	[:generator, @generator]]

      each {|page, title, url, description, pub_date, updated|
	channel << [:item,
	  [:title, title],
	  [:link, url],
	  [:description, description],
	  [:pubdate, pub_date],
	  [:guid, url]]
      }

      rss << channel
      xml << rss

      return xml
    end

    def generate_atom
      init_internal

      xml = []
      xml << [:'?xml', '1.0', 'utf-8']

      gen_attr = {:uri=>'http://qwik.jp/'}
      gen_attr[:version] = VERSION if ! @config.test

      feed = [:feed, {:xmlns=>'http://www.w3.org/2005/atom'},
	[:title, @title],
	[:link, {:rel=>'alternate', :type=>'text/html', :href=>@site_url}],
	[:link, {:rel=>'self', :type=>'application/atom+xml',
	    :href=>"#{@site_url}atom.xml"}],
	[:generator, gen_attr, @generator],
	[:updated, @updated]]

      each {|page, title, url, description, pub_date, updated|
	feed << [:entry,
	  [:title, title],
	  [:link, {:rel=>'alternate', :type=>'text/html', :href=>url}],
	  [:updated, updated],
	  [:summary, description],
	]
      }

      xml << feed

      return xml
    end

    private

    def without_testmode
      org_test  = @config.test
      org_debug = @config.debug
      @config[:test] = false
      @config[:debug] = false
      yield
      @config[:test]  = org_test
      @config[:debug] = org_debug
    end

    def init_internal
      @public = @site.is_open?

      # Site data.
      without_testmode {
	@title = @site.title
	@site_url = @site.site_url
	@description = 'a private qwikWeb site.
Since this site is in private mode, the feed includes minimum data.'
	@language = 'ja'		# FIXME: should be configurable?
	@pub_date = @site.last_page_time.rfc1123_date
      }

      if @public
	@description = 'a public qwikWeb site.'
      end

      # Icon image.
      @image_url = 'http://qwik.jp/.theme/i/favicon.png'

      # Config data.
      @last_build_date = Time.now.rfc1123_date
    # @last_build_date = @req.start_time.rfc1123_date	# No @req here.
      @last_build_date = Time.at(0).rfc1123_date if @config.test

      @updated = Time.now.rfc_date
      @updated = Time.at(0).rfc_date if @config.test
      @updated += 'Z'

      @generator = Server.server_name
      @generator = 'qwikWeb' if @config.test
    end

    def each
      # Limit the pages to 10 pages.
      @site.date_list.reverse[0..10].each {|page|
	title = page.key
	url = @site.page_url(page.key)
	description = page.mtime.rfc1123_date
	pub_date = page.mtime.rfc1123_date
	updated = page.mtime.rfc_date+'Z'

	yield(page, title, url, description, pub_date, updated)
      }
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActMetadata < Test::Unit::TestCase
    include TestSession

    def test_rss_button
      res = session
      ok_eq([:a, {:class=>'rss-button', :href=>'href'}, [:span, 'msg']],
	    @action.rss_button('href', 'msg'))
    end

    def test_plg_rss
      ok_wi([:a, {:class=>'rss-button', :href=>'rss.xml'}, [:span, 'RSS']],
	    '{{rss}}')
      ok_wi([:p, [:a, {:href=>'test.rss'}, 'test.rss']], '[[test.rss]]')
    end

    def test_plg_atom
      ok_wi([:p, [:a, {:href=>'atom.xml'}, 'atom.xml']], '[[atom.xml]]')
      ok_wi([:p, [:a, {:href=>'atom.xml'}, 'a']], '[[a|atom.xml]]')
      ok_wi([:a, {:class=>'rss-button', :href=>'atom.xml'}, [:span, 'ATOM']],
	    '{{atom}}')
    end

    def test_all
      page = @site.create_new
      page.put_with_time('* t', 0)

      # test_get_rss20
      res = session('/test/rss.xml')
      ok_eq('application/xml', res['Content-Type'])
      result = HTree(res.body).to_wabisabi
      ok_eq(
[[:'?xml', '1.0', 'utf-8'],
 [:rss,
  {:version=>'2.0'},
  [:channel,
   [:title, 'example.com/test'],
   [:link, 'http://example.com/test/'],
   [:description,
    'a private qwikWeb site.
Since this site is in private mode, the feed includes minimum data.'],
   [:language, 'ja'],
   [:pubdate, 'Thu, 01 Jan 1970 09:00:00 GMT'],
   [:lastbuilddate, 'Thu, 01 Jan 1970 09:00:00 GMT'],
   [:generator, 'qwikWeb'],
   [:item,
    [:title, '1'],
    [:link, 'http://example.com/test/1.html'],
    [:description, 'Thu, 01 Jan 1970 09:00:00 GMT'],
    [:pubdate, 'Thu, 01 Jan 1970 09:00:00 GMT'],
    [:guid, 'http://example.com/test/1.html']]]]], result)

      # test_get_atom
      res = session('/test/atom.xml')
      ok_eq('application/xml', res['Content-Type'])
      is "<?xml version=\"1.0\" encoding=\"utf-8\"?><feed xmlns=\"http://www.w3.org/2005/atom\"\n><title\n>example.com/test</title\n><link href=\"http://example.com/test/\" rel=\"alternate\" type=\"text/html\"\n/><link href=\"http://example.com/test/atom.xml\" rel=\"self\" type=\"application/atom+xml\"\n/><generator uri=\"http://qwik.jp/\"\n>qwikWeb</generator\n><updated\n>1970-01-01T09:00:00Z</updated\n><entry\n><title\n>1</title\n><link href=\"http://example.com/test/1.html\" rel=\"alternate\" type=\"text/html\"\n/><updated\n>1970-01-01T09:00:00Z</updated\n><summary\n>Thu, 01 Jan 1970 09:00:00 GMT</summary\n></entry\n></feed\n>", res.body

      t_site_open	# Public site.

      # test_get_public_rss20
      res = session('/test/rss.xml')
      ok_eq('application/xml', res['Content-Type'])
      result = HTree(res.body).to_wabisabi
      assert_not_equal(
[[:'?xml', '1.0', 'utf-8'],
 [:rss,
  {:version=>'2.0'},
  [:channel,
   [:title, 'example.com/test'],
   [:link, 'http://example.com/test/'],
   [:description, 'a public qwikWeb site.'],
   [:language, 'ja'],
   [:pubdate, 'Thu, 01 Jan 1970 09:00:00 GMT'],
   [:lastbuilddate, 'Thu, 01 Jan 1970 09:00:00 GMT'],
   [:generator, 'qwikWeb'],
   [:item,
    [:title, 't'],
    [:link, 'http://example.com/test/1.html'],
    [:description, '* t'],
    [:pubdate, 'Thu, 01 Jan 1970 09:00:00 GMT'],
    [:guid, 'http://example.com/test/1.html']]]]], result)

      # test_get_public_atom
      res = session('/test/atom.xml')
      ok_eq('application/xml', res['Content-Type'])
      result = HTree(res.body).to_wabisabi
      assert_not_equal(
[[:'?xml', '1.0', 'utf-8'],
 [:feed,
  {:xmlns=>'http://www.w3.org/2005/atom'},
  [:title, 'example.com/test'],
  [:link,
   {:href=>'http://example.com/test/', :type=>'text/html', :rel=>'alternate'}],
  [:link,
   {:href=>'http://example.com/test/atom.xml',
    :type=>'application/atom+xml',
    :rel=>'self'}],
  [:generator, {:uri=>'http://qwik.jp/', :version=>'0.5.2'}, 'qwikWeb'],
  [:updated, '1970-01-01T09:00:00Z'],
  [:entry,
   [:title, 't'],
   [:link,
    {:href=>'http://example.com/test/1.html',
     :type=>'text/html',
     :rel=>'alternate'}],
   [:updated, '1970-01-01T09:00:00Z'],
   [:summary, '* t']]]], result)
    end

    def test_many_pages
      (1..20).each {|n|
        page = @site.create_new
        page.put_with_time("* t#{n}", n)
      }

      # The RSS contains only 10 items.
      res = session('/test/rss.xml')
      ok_eq('application/xml', res['Content-Type'])
      result = HTree(res.body).to_wabisabi
      eq 19, result[1][2].length
    end
  end
end
