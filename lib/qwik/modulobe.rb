# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

# special mode for modulobe.com

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/util-time'
require 'qwik/htree-to-wabisabi'
require 'qwik/mdlb-sample'
require 'qwik/mdlb-model'

module Qwik
  class Action
    def modulobe_model_link(file)
      base = file.basename.to_s
      return file, @req.base+'.files/'+base
    end

    def modulobe_image_link(file)
      image_file = file.to_s.sub(/\.mdlb\z/, '.gif').path
      base = file.basename('.mdlb').to_s+'.gif'
      return image_file, @req.base+'.files/'+base
    end

    def modulobe_thumb_link(file)
      base = file.basename('.mdlb').to_s+'.gif'
      thumb_file = file.dirname+'.thumb'+base
      return thumb_file, @req.base+'.files/.thumb/'+base
    end
  end
end

module Modulobe
  class ModelList
    def initialize(files)
      @files = files
      @models = {}
      @days = nil
      @timeline = nil
      @last_time = nil
    end

    def empty?
      get_all_models
      return @models.empty?
    end

    def get_all_models
      @files.each {|basename|
	next unless /\.mdlb\z/ =~ basename
	if @models[basename].nil?
	  file = @files.path(basename)
	  model = ModelFile.new(file)
	  model.get_internal_info
	  @models[basename] = model
	end
      }
    end
    #private :get_all_models

    def prepare_timeline
      @timeline = @models.values.sort_by {|model|
	model.mtime
      }
      return if @timeline.last.nil?
      @last_time = @timeline.last.mtime

      @days = Hash.new {|h, k| h[k] = []}
      @timeline.reverse.each {|model|
        if model
	@days[model.mtime.ymd] << model
        end
      }
    end

    def get_table(action, path)
      get_all_models	# @models are cached.
      prepare_timeline if @timeline.nil?

      trs = []
      @days.to_a.sort_by {|ymd, models|
	ymd
      }.reverse.each {|ymd, models|
	trs << [:tr, {:class=>'day'}, [:th, {:colspan=>'3'}, ymd]]
	models.each {|model|
	  trs << model.create_entry(action, path)
	}
      }
      table = [:table, {:class=>'model'}, *trs]
      div = [:div, {:class=>'model'}, table]
      return div
    end

    def get_style
      return [:style, '
/* ==================== model */
div.model {
  margin: 1em 0;
  padding: 10px;
  border: 0;
  background-color: #fff;
}

table.model {
  margin: 0;
  width: 100%;
  border: 0;
}

tr.day th {
  padding: 15px 0 0 0;
  border-top: 0;
  border-right: 0;
  border-bottom: 0;
  border-left: 0;
  color: #0c0;
  background-color: transparent;
}

tr.model td {
  margin: 0;
  padding: 0;
  border: 1px solid #f30;
  border: 0;
  line-height: 1.0;
}

tr.model td img {
  margin: 10px 10px 0 10px;
  border: 0;
  border-bottom: 0;
}

tr.model td a {
  border: 0;
}

tr.model td div {
  margin: 0;
  padding: 0;
}

tr.model td div.author {
  font-size: small;
}

tr.model td div.name {
  margin: 0 0 0 0;
  font-size: medium;
  font-weight: bold;
}

tr.model td div.name a {
  text-decoration: underline;
}

tr.model td pre {
  margin: 0;
  padding: 0;
  border: 0;
  line-height: 1.0;
  background-color: transparent;
}
']
    end

    def get_rss(action, base)
      get_all_models	# @models are cached.
      prepare_timeline if @timeline.nil?

      xml = []
      xml << [:'?xml', '1.0', 'utf-8']

      rss = [:rss, {:version=>'2.0', :'xmlns:creativeCommons'=>
	  'http://backend.userland.com/creativeCommonsRssModule'}]
      xml << rss

      channel = [:channel,
	[:title, 'Modulobe model gallery'],
	[:link, 'http://wiki.modulobe.com/'],
	[:description, 'The model list of Modulobe Wiki site.'],
	[:language, 'ja'],
	[:managingEditor, 'modulobe@qwik.jp'],
	[:webMaster, 'modulobe@qwik.jp']]
      rss << channel
      channel << [:lastBuildDate, @last_time.rfc1123_date]
      channel << [:ttl, '60']

      @timeline.each {|model|
	item = model.create_rss_item(action, base)
	channel << item
      }

      return xml
    end
  end

  class ModelFile
    def initialize(file)
      @file = file
      @mtime = @file.mtime
      @length = @file.size
      @image_file = @file.to_s.sub(/\.mdlb\z/, '.gif').path
      @name = @author = @comment = nil
    end
    attr_reader :file, :mtime
    attr_reader :length		# for debug
    attr_reader :image_file	# for debug
    attr_reader :name, :author, :comment

    def get_internal_info
      if @name.nil?
	content = @file.read
	@name, @author, @comment = extract_info(content)
      end
      return @name, @author, @comment
    end

    def extract_info(str)
      htree = HTree(str)
      wabisabi = htree.to_wabisabi
      info = wabisabi.get_path('//model/info')
      return [nil, nil, nil] unless info
      name    = info.get_path('/name').text.set_xml_charset.to_page_charset
      author  = info.get_path('/author').text.set_xml_charset.to_page_charset
      comment = info.get_path('/comment').text.set_xml_charset.to_page_charset
      return [name, author, comment]
    end

    def prepare_metadata
      name    = @name    || @file.basename('.mdlb').to_s
      author  = @author  || 'anonymous'
      comment = @comment || ''
      return [name, author, comment]
    end

    # wget http://wiki.modulobe.com/model.mdlbrss
    # http://colinux:9190/modulobewiki/model.html
    # wget http://colinux:9190/modulobewiki/model.mdlbrss
    def prepare_link(action, path)
#      base = @file.basename('.mdlb').to_s
#      href = path+'/'+base+'.mdlb'

      model_file, model_relative = action.modulobe_model_link(@file)
      model_absolute = action.c_relative_to_root(model_relative)
      model_full     = action.c_relative_to_absolute(model_relative)

      image_file, image_relative = action.modulobe_image_link(@file)

      if image_file.exist?
	thumb_file, thumb_relative = action.modulobe_thumb_link(@file)
	if ! thumb_file.exist?
	  action.thumb_generate(image_file.basename.to_s)
	end
	img = [:img, {:src=>thumb_relative}]
      else
	img = [:img, {:width=>'100', :height=>'75', :src=>'model.files/x.gif'}]
      end
      img = [:a, {:href=>model_relative}, img]

      return [model_relative, model_full, img]
    end

    def create_entry(action, path)
      href, url, img = prepare_link(action, path)
      name, author, comment = prepare_metadata
      tr = [:tr, {:class=>'model'},
	[:td, img],
	[:td, [:div, {:class=>'author'}, author],
	  [:div, {:class=>'name'}, [:a, {:href=>href}, name]],
	  [:pre, {:class=>'comment'}, comment]]]
      return tr
    end

    def create_model_entry(action, path)
      href, url, img = prepare_link(action, path)
      name, author, comment = prepare_metadata
      return img
    end

    # http://colinux:9190/modulobewiki/model.mdlbrss
    # http://wiki.modulobe.com/model.mdlbrss
    def create_rss_item(action, path)
      href, url, img = prepare_link(action, path)
      name, author, comment = prepare_metadata
      item = [:item]
      item << [:title, name]
      item << [:link, url]

      src = img[2][1][:src]
      imgsrc = action.c_relative_to_absolute(src)
      html = "<p><img src=\"#{imgsrc}\" alt=\"#{name}\" width=\"100\" height=\"75\"/><br/>#{comment}</p>"
      item << [:description, html]

      item << [:author, author]
      item << [:pubDate, @mtime.rfc1123_date]
      item << [:enclosure,
	{:url=>url, :length=>@length, :type=>'application/xml'}]
      item << [:'creativeCommons:license',
	'http://creativecommons.org/licenses/by-sa/2.5/deed.ja']
      return item
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestModulobeModel < Test::Unit::TestCase
    include TestSession
    include Modulobe::Sample

    def test_all
      t_add_user

      page = @site['_SiteConfig']
      page.store(':siteurl:http://wiki.example.com/')

      page = @site.create('c')
      page.store('')
      files = @site.files('c')

      files.put('test1.mdlb', MODULOBE_TEST_MODEL1, nil, 0)
      files.put('test1.gif', TEST_PNG_DATA, nil, 1)
      file = files.path('test1.mdlb')

      # test_create_model
      model = Modulobe::ModelFile.new(file)
      ok_eq('.test/data/test/c.files/test1.mdlb', model.file.to_s)
      ok_eq(Time.at(0), model.mtime)
      ok_eq(563, model.length)
      ok_eq('.test/data/test/c.files/test1.gif', model.image_file.to_s)

      # test_internal_info
      ok_eq(nil, model.name)

      # test_prepare_metadata
      name, author, comment = model.prepare_metadata
      ok_eq('test1', name)
      ok_eq('anonymous', author)
      ok_eq('', comment)

      # test_get_internal_info
      name, author, comment = model.get_internal_info
      ok_eq('t1 model', name)
      ok_eq('Alice', author)
      ok_eq('This is a comment.
', comment)

      session('/test/c.html')	# for create @action

      # test_modulobe_model_link
      file, relative = @action.modulobe_model_link(model.file)
      ok_eq('c.files/test1.mdlb', relative)
      ok_eq('/c.files/test1.mdlb',
		   @action.c_relative_to_root(relative))
      ok_eq('http://wiki.example.com/c.files/test1.mdlb',
		   @action.c_relative_to_absolute(relative))

      # test_modulobe_image_link
      file, relative = @action.modulobe_image_link(model.file)
      ok_eq('.test/data/test/c.files/test1.gif', file.to_s)
      ok_eq('c.files/test1.gif', relative)

      # test_modulobe_thumb_link
      file, relative = @action.modulobe_thumb_link(model.file)
      ok_eq('.test/data/test/c.files/.thumb/test1.gif', file.to_s)
      ok_eq('c.files/.thumb/test1.gif', relative)

      path = 'c.files'
      ok_eq([:tr, {:class=>'model'},
	      [:td,
		[:a, {:href=>'c.files/test1.mdlb'},
		  [:img, {:src=>'c.files/.thumb/test1.gif'}]]],
	      [:td,
		[:div, {:class=>'author'}, 'Alice'],
		[:div, {:class=>'name'},
		  [:a, {:href=>'c.files/test1.mdlb'}, 't1 model']],
		[:pre, {:class=>'comment'}, 'This is a comment.
']]],
	    model.create_entry(@action, path))

      ok_eq([:a, {:href=>'c.files/test1.mdlb'},
	      [:img, {:src=>'c.files/.thumb/test1.gif'}]],
	    model.create_model_entry(@action, path))

      ok_eq([:item,
	      [:title, 't1 model'],
	      [:link, 'http://wiki.example.com/c.files/test1.mdlb'],
	      [:description,
		"<p><img src=\"http://wiki.example.com/c.files/.thumb/test1.gif\" alt=\"t1 model\" width=\"100\" height=\"75\"/><br/>This is a comment.\n</p>"],
	      [:author, 'Alice'],
	      [:pubDate, 'Thu, 01 Jan 1970 09:00:00 GMT'],
	      [:enclosure,
		{:length=>563, :type=>'application/xml',
		  :url=>'http://wiki.example.com/c.files/test1.mdlb'}],
	      [:'creativeCommons:license',
		'http://creativecommons.org/licenses/by-sa/2.5/deed.ja']],
	    model.create_rss_item(@action, path))
    end
  end
end
