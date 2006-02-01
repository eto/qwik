#
# Copyright (C) 2003-2006 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

# special mode for modulobe.com

$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'
require 'qwik/modulobe'
require 'qwik/act-metadata'

module Qwik
  class Action
    # Called from act-metadata.rb
    def metadata_model_xml
      # Check pages that has .mdlb file.
      page_keys = Hash.new(0)
      @site.each {|page|
	files = @site.files(page.key)
	files.each {|filename|
	  if /\.mdlb\z/ =~ filename
	    page_keys[page.key] += 1
	  end
	}
      }

      # Collect model files and check last_time.
      last_time = nil
      models = []
      page_keys.keys.sort.each {|key|
	page = @site[key]
	str = page.load
	tokens = TextTokenizer.tokenize(str)
	tokens.each {|token|
	  if token[0] == :plugin && token[1] == 'modulobe_model'
	    filename = token[2]
	    files = @site.files(page.key)
	    file = files.path(filename)
	    mtime = file.mtime
	    last_time = mtime if last_time.nil? || last_time < mtime

	    content = token[3]
	    content_tokens = TextTokenizer.tokenize(content)
	    title = author = comment = nil
	    content_tokens.each {|ctoken|
	      next if ctoken[0] != :dl
	      title   = ctoken[2] if ctoken[1] == 'title'
	      author  = ctoken[2] if ctoken[1] == 'author'
	      comment = ctoken[2] if ctoken[1] == 'comment'
	    }

	    title   ||= 'no title'
	    author  ||= 'no name'
	    comment ||= 'no comment'
	    models << [mtime, page, file, title, author, comment]
	  end
	}
      }

      xml = []
      xml << [:'?xml', '1.0', 'utf-8']
      rss = [:rss, {:version=>'2.0', :'xmlns:creativeCommons'=>
	  'http://backend.userland.com/creativeCommonsRssModule'}]

      top_url = c_relative_to_full('/')
      channel = [:channel,
	[:title, 'Modulobe model gallery'],
	[:link, top_url],
	[:description, 'This is a model list of Modulobe Wiki.'],
	[:language, 'ja'],
	[:managingEditor, 'modulobe@qwik.jp'],
	[:webMaster, 'modulobe@qwik.jp'],
	[:lastBuildDate, last_time.rfc1123_date],
	[:ttl, '60']]

      models.sort.each {|mtime, page, file, title, author, comment|
	basename = file.basename
	url = c_relative_to_full(page.key+'.files/'+basename)

	# Check thumb is exist.
	thumb_file = file.dirname+'.thumb'+(file.basename('.mdlb').to_s+'.gif')
	if ! thumb_file.exist?
	  # make it.
	end

	thumb = page.key+'.files/.thumb/'+file.basename('.mdlb').to_s+'.gif'
	thumb_url = c_relative_to_full(thumb)
	html = "<p><img src=\"#{thumb_url}\" alt=\"#{title}\" width=\"100\" height=\"75\"/><p>#{comment}</p>"

	length = file.size

	item = [:item,
	  [:title, title],
	  [:link, url],
	  [:description, html],
	  [:author, author],
	  [:pubDate, mtime.rfc1123_date],
	  [:enclosure,
	    {:url=>url, :length=>length, :type=>'application/xml'}],
	  [:'creativeCommons:license',
	    'http://creativecommons.org/licenses/by/2.1/jp/']]
	channel << item
      }

      rss << channel
      xml << rss

      return xml
    end

    def pre_ext_mdlbrss
      xml = []
      xml << [:'?xml', '1.0', 'utf-8']
      rss = [:rss, {:version=>'2.0'}]

      moved_url = c_relative_to_full('/model.xml')
      channel = [:channel,
	[:title, 'moved'],
	[:link, moved_url],
	[:description, 'moved.'],
	[:lastBuildDate, Time.at(0).rfc1123_date],
	[:ttl, '60']]

      item = [:item,
	[:title, 'moved'],
	[:link, moved_url],
	[:description, 'moved'],
	[:pubDate, Time.at(0).rfc1123_date]]
      channel << item

      rss << channel

      xml << rss

      @res['Content-Type'] = 'application/xml'
      @res.body = xml
      @res.body = @res.body.format_xml.page_to_xml if ! @config.test
      return nil
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActModulobeRss < Test::Unit::TestCase
    include TestSession
    include Modulobe::Sample

    def setup_models
      t_add_user

      # Prepare a page.
      page = @site.create('a')
      page.store("* a
* t1 model
{{modulobe_model(test1.mdlb)
:title:		t1 model
:author:	Alice
:comment:	This is a comment.\n
}}
{{hcomment}}
")
      files = @site.files('a')
      files.put('test1.mdlb', MODULOBE_TEST_MODEL1, nil, 0)
      files.put('test1.gif', TEST_PNG_DATA, nil, 1)

      # Prepare another page.
      page = @site.create('b')
      page.store("* b
* t2 model
{{modulobe_model(test2.mdlb)
:title:		t2 model
:author:	Bob
:comment:	This is a comment, too.\n
}}
{{hcomment}}
")
      files = @site.files('b')
      files.put('test2.mdlb', MODULOBE_TEST_MODEL2, nil, 2)
      files.put('test2.gif', TEST_PNG_DATA, nil, 3)
    end

    def test_ext_mdlbrss
      setup_models
      res = session('/test/nosuch.mdlbrss')
      ok_xp([:title, 'moved'], '//title')
      res = session('/test/a.mdlbrss')
      ok_eq([[:'?xml', '1.0', 'utf-8'],
	      [:rss,
		{:version=>'2.0'},
		[:channel,
		  [:title, 'moved'],
		  [:link, 'http://example.com/model.xml'],
		  [:description, 'moved.'],
		  [:lastBuildDate, 'Thu, 01 Jan 1970 09:00:00 GMT'],
		  [:ttl, '60'],
		  [:item,
		    [:title, 'moved'],
		    [:link, 'http://example.com/model.xml'],
		    [:description, 'moved'],
		    [:pubDate, 'Thu, 01 Jan 1970 09:00:00 GMT']]]]],
	    res.body)
    end

    def test_metadata_model_xml
      setup_models
      res = session('/test/model.xml')
      ok_eq([[:'?xml', '1.0', 'utf-8'],
	      [:rss, {:'xmlns:creativeCommons'=>
		  'http://backend.userland.com/creativeCommonsRssModule',
		  :version=>'2.0'},
		[:channel,
		  [:title, 'Modulobe model gallery'],
		  [:link, 'http://example.com/'],
		  [:description, 'This is a model list of Modulobe Wiki.'],
		  [:language, 'ja'],
		  [:managingEditor, 'modulobe@qwik.jp'],
		  [:webMaster, 'modulobe@qwik.jp'],
		  [:lastBuildDate, 'Thu, 01 Jan 1970 09:00:02 GMT'],
		  [:ttl, '60'],
		  [:item,
		    [:title, 't1 model'],
		    [:link, 'http://example.com/test/a.files/test1.mdlb'],
		    [:description,
		      "<p><img src=\"http://example.com/test/a.files/.thumb/test1.gif\" alt=\"t1 model\" width=\"100\" height=\"75\"/><p>This is a comment.</p>"],
		    [:author, 'Alice'],
		    [:pubDate, 'Thu, 01 Jan 1970 09:00:00 GMT'],
		    [:enclosure,
		      {:url=>'http://example.com/test/a.files/test1.mdlb',
			:length=>563, :type=>'application/xml'}],
		    [:'creativeCommons:license',
		      'http://creativecommons.org/licenses/by/2.1/jp/']],
		  [:item,
		    [:title, 't2 model'],
		    [:link, 'http://example.com/test/b.files/test2.mdlb'],
		    [:description,
		      "<p><img src=\"http://example.com/test/b.files/.thumb/test2.gif\" alt=\"t2 model\" width=\"100\" height=\"75\"/><p>This is a comment, too.</p>"],
		    [:author, 'Bob'],
		    [:pubDate, 'Thu, 01 Jan 1970 09:00:02 GMT'],
		    [:enclosure,
		      {:url=>'http://example.com/test/b.files/test2.mdlb',
			:length=>1395, :type=>'application/xml'}],
		    [:'creativeCommons:license',
		      'http://creativecommons.org/licenses/by/2.1/jp/']]]]],
	    res.body)
    end
  end
end
