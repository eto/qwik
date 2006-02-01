#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'

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

    def pre_ext_rss
      return metadata_rss091 if @req.base == @req.sitename
      return c_nerror(_('Error'))
    end

    def metadata_rss091
      @res['Content-Type'] = 'application/xml'
      @res.body = @site.metadata.generate_rss091
      @res.body = @res.body.format_xml.page_to_xml if ! @config.test
    end

    def pre_ext_rdf
      method = "metadata_#{@req.base}_#{@req.ext}"
      if self.respond_to?(method)
	@res['Content-Type'] = 'application/xml'
	@res.body = self.send(method)
	@res.body = @res.body.format_xml.page_to_xml if ! @config.test
	return
      end
      return c_nerror(_('Error'))
    end
    alias pre_ext_xml pre_ext_rdf

    def metadata_index_rdf
      return @site.metadata.generate_rss10
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
      @metadata = SiteMetaData.new(@config, self) unless defined? @metadata
      @metadata
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

    def generate_rss091
      init_internal

      xml = []
      xml << [:'?xml', '1.0', 'UTF-8']

      rss = [:rss, {:version=>'0.91'}]

      channel = [:channel,
	[:title, @title],
	[:link, @site_url],
	[:description, @description],
	[:language, 'ja']]

      channel << [:image,
	[:title, @title],
	[:url, @image_url],
	[:link, @site_url],
      ]

      each {|page, title, url, description, pub_date, updated|
	channel << [:item,
	  [:title, title],
	  [:link, url],
	  [:description, description]]
      }

      rss << channel
      xml << rss

      return xml
    end

    def generate_rss10
      init_internal

      xml = []
      xml << [:'?xml', '1.0', 'UTF-8']

      rdf = [:'rdf:RDF',
	{'xmlns:rdf'=>'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
	  'xmlns'=>'http://purl.org/rss/1.0/',
	  'xmlns:dc'=>'http://purl.org/dc/elements/1.1/'}]

      channel = [:channel, {:'rdf:about'=>@site_url},
	[:title, @title],
	[:link, @site_url],
	[:description, @description],
	[:image, {:'rdf:resource'=>@image_url}]]

      seq = [:'rdf:Seq']
      each {|page, title, url, description, pub_date, updated|
	seq << [:'rdf:li', {:'rdf:resource'=>url}]
      }
      channel << [:items, seq]

      rdf << channel

      rdf << [:image, {:'rdf:about'=>@image_url},
	[:title, @title],
	[:link, @site_url],
	[:url, @image_url]]

      each {|page, title, url, description, pub_date, updated|
	rdf << [:item, {:'rdf:about'=>url},
	  [:title, title],
	  [:link, url],
	  [:description, description],
	  [:'dc:date', pub_date]]
      }

      xml << rdf

      return xml
    end

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
	    :href=>@site_url+'atom.xml'}],
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
     #qp org_test, org_debug
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
	@language = 'ja'		# should be configurable?
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
     #qp @config.test
      @generator = 'qwikWeb' if @config.test
    end

    def page_init
      @pagedata = {}
      @site.date_list.each {|page|
	key = page.key
	next if @pagedata[key]

	title = page.key
	url = @site.page_url(page.key)
	description = page.mtime.rfc1123_date
	pub_date = page.mtime.rfc1123_date
	updated = page.mtime.rfc_date+'Z'

	if @public
	  title = page.get_title
	  str = page.load
	  description = str

#	  tokens = TextTokenizer.tokenize(str)
#	  page_html = TextParser.make_tree(tokens)
#	  SiteMetaData.delete_plugin_info(page_html)
#	  description = page_html.format_xml
	end

	@pagedata[key] = [page, title, url, description, pub_date, updated]
      }
    end

    def self.delete_plugin_info(wabisabi)
      wabisabi.make_index
      wabisabi.index_each_tag(:plugin) {|e|
	attr = e.attr
	if attr
	  e.delete_at(1)
	end
	e
      }
    end

    def each
      @site.date_list.each {|page|
	title = page.key
	url = @site.page_url(page.key)
	description = page.mtime.rfc1123_date
	pub_date = page.mtime.rfc1123_date
	updated = page.mtime.rfc_date+'Z'

	if @public
	  title = page.get_title
#	  str = page.load
#	  description = str
#	  tokens = TextTokenizer.tokenize(str)
#	  page_html = TextParser.make_tree(tokens)
#	  description = page_html.format_xml
	end

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

    def test_class_method
      c = Qwik::SiteMetaData

      w = []
      c.delete_plugin_info(w)
      ok_eq([], w)

      w = [[:plugin]]
      ok_eq([[:plugin]], w)
      c.delete_plugin_info(w)
      ok_eq([[:plugin]], w)

      w = [[:plugin, {:param=>'dummy'}]]
      ok_eq([[:plugin, {:param=>'dummy'}]], w)
      c.delete_plugin_info(w)
      ok_eq([[:plugin]], w)
    end

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

      # test_get_rss091
      res = session('/test/test.rss')
      ok_eq('application/xml', res['Content-Type'])
      ok_eq(
[[:'?xml', '1.0', 'UTF-8'],
 [:rss,
  {:version=>'0.91'},
  [:channel,
   [:title, 'example.com/test'],
   [:link, 'http://example.com/test/'],
   [:description,
    'a private qwikWeb site.
Since this site is in private mode, the feed includes minimum data.'],
   [:language, 'ja'],
   [:image,
    [:title, 'example.com/test'],
    [:url, 'http://qwik.jp/.theme/i/favicon.png'],
    [:link, 'http://example.com/test/']],
   [:item,
    [:title, '1'],
    [:link, 'http://example.com/test/1.html'],
    [:description, 'Thu, 01 Jan 1970 09:00:00 GMT']]]]], res.body)

      # test_get_rss10
      res = session('/test/index.rdf')
      ok_eq('application/xml', res['Content-Type'])
      ok_eq(
[[:'?xml', '1.0', 'UTF-8'],
 [:'rdf:RDF',
  {'xmlns:rdf'=>'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
   'xmlns:dc'=>'http://purl.org/dc/elements/1.1/',
   'xmlns'=>'http://purl.org/rss/1.0/'},
  [:channel,
   {:'rdf:about'=>'http://example.com/test/'},
   [:title, 'example.com/test'],
   [:link, 'http://example.com/test/'],
   [:description,
    'a private qwikWeb site.
Since this site is in private mode, the feed includes minimum data.'],
   [:image, {:'rdf:resource'=>'http://qwik.jp/.theme/i/favicon.png'}],
   [:items,
    [:'rdf:Seq',
     [:'rdf:li', {:'rdf:resource'=>'http://example.com/test/1.html'}]]]],
  [:image,
   {:'rdf:about'=>'http://qwik.jp/.theme/i/favicon.png'},
   [:title, 'example.com/test'],
   [:link, 'http://example.com/test/'],
   [:url, 'http://qwik.jp/.theme/i/favicon.png']],
  [:item,
   {:'rdf:about'=>'http://example.com/test/1.html'},
   [:title, '1'],
   [:link, 'http://example.com/test/1.html'],
   [:description, 'Thu, 01 Jan 1970 09:00:00 GMT'],
   [:'dc:date', 'Thu, 01 Jan 1970 09:00:00 GMT']]]], res.body)

      # test_get_rss20
      res = session('/test/rss.xml')
      ok_eq('application/xml', res['Content-Type'])
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
    [:guid, 'http://example.com/test/1.html']]]]], res.body)

      # test_get_atom
      res = session('/test/atom.xml')
      ok_eq('application/xml', res['Content-Type'])
      ok_eq(
[[:'?xml', '1.0', 'utf-8'],
 [:feed,
  {:xmlns=>'http://www.w3.org/2005/atom'},
  [:title, 'example.com/test'],
  [:link,
   {:rel=>'alternate', :href=>'http://example.com/test/', :type=>'text/html'}],
  [:link,
   {:rel=>'self',
    :href=>'http://example.com/test/atom.xml',
    :type=>'application/atom+xml'}],
  [:generator, {:uri=>'http://qwik.jp/'}, 'qwikWeb'],
  [:updated, '1970-01-01T09:00:00Z'],
  [:entry,
   [:title, '1'],
   [:link,
    {:rel=>'alternate',
     :href=>'http://example.com/test/1.html',
     :type=>'text/html'}],
   [:updated, '1970-01-01T09:00:00Z'],
   [:summary, 'Thu, 01 Jan 1970 09:00:00 GMT']]]], res.body)

      t_site_open	# Public site.

      # test_get_public_rss091
      res = session('/test/test.rss')
      ok_eq('application/xml', res['Content-Type'])
      assert_not_equal(
[[:'?xml', '1.0', 'UTF-8'],
 [:rss,
  {:version=>'0.91'},
  [:channel,
   [:title, 'example.com/test'],
   [:link, 'http://example.com/test/'],
   [:description, 'a public qwikWe site.'],
   [:language, 'ja'],
   [:image,
    [:title, 'example.com/test'],
    [:url, 'http://qwik.jp/.theme/i/favicon.png'],
    [:link, 'http://example.com/test/']],
   [:item,
    [:title, 't'],
    [:link, 'http://example.com/test/1.html'],
    [:description, '* t']]]]], res.body)

      # test_get_public_rss10
      res = session('/test/index.rdf')
      ok_eq('application/xml', res['Content-Type'])
      assert_not_equal(
[[:'?xml', '1.0', 'UTF-8'],
 [:'rdf:RDF',
  {'xmlns:rdf'=>'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
   'xmlns:dc'=>'http://purl.org/dc/elements/1.1/',
   'xmlns'=>'http://purl.org/rss/1.0/'},
  [:channel,
   {:'rdf:about'=>'http://example.com/test/'},
   [:title, 'example.com/test'],
   [:link, 'http://example.com/test/'],
   [:description, 'a public qwikWe site.'],
   [:image, {:'rdf:resource'=>'http://qwik.jp/.theme/i/favicon.png'}],
   [:items,
    [:'rdf:Seq',
     [:'rdf:li', {:'rdf:resource'=>'http://example.com/test/1.html'}]]]],
  [:image,
   {:'rdf:about'=>'http://qwik.jp/.theme/i/favicon.png'},
   [:title, 'example.com/test'],
   [:link, 'http://example.com/test/'],
   [:url, 'http://qwik.jp/.theme/i/favicon.png']],
  [:item,
   {:'rdf:about'=>'http://example.com/test/1.html'},
   [:title, 't'],
   [:link, 'http://example.com/test/1.html'],
   [:description, '* t'],
   [:'dc:date', 'Thu, 01 Jan 1970 09:00:00 GMT']]]], res.body)

      # test_get_public_rss20
      res = session('/test/rss.xml')
      ok_eq('application/xml', res['Content-Type'])
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
    [:guid, 'http://example.com/test/1.html']]]]], res.body)

      # test_get_public_atom
      res = session('/test/atom.xml')
      ok_eq('application/xml', res['Content-Type'])
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
   [:summary, '* t']]]], res.body)
    end
  end
end
