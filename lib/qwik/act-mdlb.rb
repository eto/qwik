# -*- coding: shift_jis -*-
# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

# special mode for modulobe.com

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/modulobe'
require 'qwik/act-metadata'
require 'qwik/act-files'

module Qwik
  class Action
    # ============================== model
    MODULOBE_MODEL_STYLE = '

/* ==================== modulobe model */
div.modulobe_model {
  margin: 1em 0;
  padding: 10px;
  border: 1px solid #999;
  background-color: #fff;
}

div.modulobe_model table {
  margin: 0;
  width: 100%;
  border: 0;
}

div.modulobe_model td {
  margin: 0;
  padding: 0;
  border: 0;
  line-height: 1.0;
}

div.modulobe_model td.img {
  margin: 0;
  border: 0;
  text-align: center;
}

div.modulobe_model td.img a {
  text-decoration: none;
  border-bottom: 0;
}

div.modulobe_model td.img img {
  border: 0;
}

div.modulobe_model td.desc {
  border: 0;
}

div.modulobe_model td.desc h3 {
  border-bottom: 0;
  margin: 0;
  padding: 0;
  left: 0;
  color: #393;
}

div.modulobe_model td.desc p {
  margin: 0;
  padding: 0;
  line-height: 1.33;
}

div.modulobe_model td.desc strong {
  color: #060;
  font-weight: normal;
}

'

    def plg_modulobe_model(model)
      div = [:div, {:class=>'modulobe_model'}]

      # image
      files = @site.files(@req.base)
      file = files.path(model)

      return [:div, 'No file exist.'] if ! file.exist?
      model = Modulobe::ModelFile.new(file)

      href, url, img = model.prepare_link(self, "#{@req.base}.files")

      # description
      content = yield
      #tokens = c_tokenize(content)
      tokens = TextTokenizer.tokenize(content)

      author = 'anonymous'
      title = 'no title'
      comment = 'no comment'
      tokens.each {|token|
	if token[0] == :dl
	  author  = token[2] if token[1] == 'author'
	  title   = token[2] if token[1] == 'title'
	  comment = token[2] if token[1] == 'comment'
	end
      }

      comment.gsub!(/\\n/, "\n")
      comment = c_res(comment)

      desc = [[:h3, [:a, {:href=>href}, title]],
	[:p, _('Author'), ': ', [:strong, author]],
	[:p, comment]]

      table = [:table, [:tr,
	  [:td, {:class=>'img'}, img],
	  [:td, {:class=>'desc'}, desc]]]

      div << table

      if ! defined?(@modulobe_model_style)
	@modulobe_model_style = true
	div << [:style, MODULOBE_MODEL_STYLE]
      end

      return div
    end

    # ============================== list
    def plg_modulobe_model_list
      pagename = @req.base
      page = @site[pagename]
      return if page.nil?

      files = @site.files(pagename)
      page.cache[:modellist] ||= Modulobe::ModelList.new(files)
      modellist = page.cache[:modellist]
      return if modellist.empty?

      div = [:div, {:class=>'files'}]
      path = c_relative_to_root(pagename+'.files')
      div << modellist.get_table(self, path)
      div << modellist.get_style
      return div
    end

    # ============================== rss
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

      top_url = c_relative_to_absolute('/')
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
	url = c_relative_to_absolute(page.key+'.files/'+basename)

	# Check thumb is exist.
	thumb_file = file.dirname+'.thumb'+(file.basename('.mdlb').to_s+'.gif')
	if ! thumb_file.exist?
	  # make it.
	end

	thumb = page.key+'.files/.thumb/'+file.basename('.mdlb').to_s+'.gif'
	thumb_url = c_relative_to_absolute(thumb)
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

      moved_url = c_relative_to_absolute('/model.xml')
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

    # ============================== upload
    def plg_modulobe_files_form(pagename=nil)
      base = @req.base
      base = pagename if pagename
      ar = []
      ar << [:style, '
div.modulobe_uploader {
  margin: 10px 0;
  padding: 10px;
  border: 1px solid #ccc;
  background-color: #fff;
}
div.modulobe_uploader table {
  margin: 0;
  padding: 0;
  border: 0;
  width: 100%;
}
div.modulobe_uploader td,
div.modulobe_uploader th {
  margin: 0;
  padding: 2px 10px;
  border: 0;
}
div.modulobe_uploader th {
  text-align: right;
}
div.modulobe_uploader td input {
  font-size: small;
}
']
      ar << [:div, {:class=>'modulobe_uploader'},
	[:form, {:method=>'POST', :action=>base+'.modulobe_files_upload',
	    :enctype=>'multipart/form-data'},
	  [:table,
	    [:tr, [:th, _('Model file'), ' : '],
	      [:td, [:input, {:type=>'file', :name=>'content', :size=>'30'}]]],
	    [:tr, [:th, _('Image file'), ' : '],
	      [:td, [:input, {:type=>'file', :name=>'image', :size=>'30'}]]],
	    [:tr, [:td, ''],
	      [:td, [:input, {:type=>'submit', :value=>_('Attach')}]]]]]]
      return ar
    end

    def ext_modulobe_files_upload
      content = @req.query['content']	# WEBrick::HTTPUtils::FormData
      image   = @req.query['image']
      return modulobe_files_put(content, image) if content
      return modulobe_files_error(_('Please specify file.'))
    end

    def modulobe_files_put(content, image)
      c_require_post

      files = @site.files(@req.base)

      fullfilename = content.filename
      if fullfilename.empty?
	return modulobe_files_error(_('Please contact the administrator.'))
      end

      # Get basename.
      filename = fullfilename.sub(/\A.*[\/\\]([^\/\\]+)\z/) { $1 }

      result_filename = files.fput(filename, content)

      list = []
      if filename == result_filename
	list << [:p, [:strong, filename], ' : ', _('The file is saved.')]
      else
	list << [:p, [:strong, filename], ' -> ', [:strong, result_filename],
	  ' : ', _('The file is saved with this filename.')]
      end

      if image
	img_fullfilename = image.filename
	if img_fullfilename && ! img_fullfilename.empty?
	  img_filename = img_fullfilename.sub(/\A.*[\/\\]([^\/\\]+)\z/) { $1 }
	  ext = Filename.extname(img_filename)
	  if ext == 'gif'
	    img_filename = File.basename(result_filename, '.mdlb')+'.gif'
	    files.put(img_filename, image)
	    list << [:p, _('The image is also saved.')]
	  end
	end
      end

      c_make_log('modulobe file attach')	# Modulobe FILE ATTACH

      files = @site.files(@req.base)
      file = files.path(result_filename)
      model = Modulobe::ModelFile.new(file)
      model.get_internal_info
      name = model.name
      author = model.author
      comment = model.comment
      comment ||= ''
      comment.gsub!(/\n/, "\\n")

      page = @site[@req.base]
      v = page.load
      page.add("
* #{name}
{{modulobe_model(#{result_filename})
:title:		#{name}
:author:	#{author}
:comment:	#{comment}
}}
{{mcomment}}

")

      list << [:hr]
      url = @req.base+'.html'
      list << [:p,_('Go next'),' : ',[:a,{:href=>url},url]]
      return c_surface(_('File attachment completed')){list}
    end

    def modulobe_files_error(msg)
      return c_surface(_('Error')){
	[[:h2, {:style=>'margin:2em;text-align:center;'},
	    msg],
	  [:p, {:style=>'margin:2em;text-align:center;'},
	    [:a, {:href=>@req.base+'.html'}, _('Go back')]]]
      }
    end

  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActModulobe < Test::Unit::TestCase
    include TestSession
    include Modulobe::Sample

    # ============================== model
    def test_model
      t_add_user

      # test_modulobe_model
      page = @site.create('c')
      page.store('{{modulobe_model(test1.mdlb)
:author:	Modulobe Project
:title:		Test1 Model
:comment:	This is a sample model by Modulobe Project.

http://www.modulobe.com/ 

}}
{{hcomment}}
')

      model = MODULOBE_TEST_MODEL
      @site.files('c').put('test1.mdlb', model, nil, 0)
      image = TEST_PNG_DATA
      @site.files('c').put('test1.gif', image, nil, 1)

      res = session('/test/c.html')
      ok_xp([:table,
	      [:tr,
		[:td, {:class=>'img'},
		  [:a, {:href=>'c.files/test1.mdlb'},
		    [:img, {:src=>'c.files/.thumb/test1.gif'}]]],
		[:td, {:class=>'desc'},
		  [[:h3, [:a, {:href=>'c.files/test1.mdlb'}, 'Test1 Model']],
		    [:p, 'Author', ': ', [:strong, 'Modulobe Project']],
		    [:p, [[:p,
			  'This is a sample model by Modulobe Project.']]]]]]],
	    "//div[@class='modulobe_model']/table")
    end

    def test_with_minus
      t_add_user

      page = @site.create('c')
      page.store('{{modulobe_model(test-2.mdlb)
:author:	Modulobe Project
:title:		Test-2 Model
:comment:	This is a sample.
}}
{{hcomment}}
')

      model = MODULOBE_TEST_MODEL
      @site.files('c').put('test-2.mdlb', model, nil, 0)
      image = TEST_PNG_DATA
      @site.files('c').put('test-2.gif', image, nil, 1)

      res = session('/test/c.html')
      ok_xp([:table,
	      [:tr,
		[:td, {:class=>'img'},
		  [:a, {:href=>'c.files/test-2.mdlb'},
		    [:img, {:src=>'c.files/.thumb/test-2.gif'}]]],
		[:td, {:class=>'desc'},
		  [[:h3, [:a, {:href=>'c.files/test-2.mdlb'}, 'Test-2 Model']],
		    [:p, 'Author', ': ', [:strong, 'Modulobe Project']],
		    [:p, [[:p,
			  'This is a sample.']]]]]]],
	    "//div[@class='modulobe_model']/table")
    end

    # ============================== list
    def test_modulobe_list
      t_add_user

      # test_modulobe_model_list
      page = @site.create('c')

      model = MODULOBE_TEST_MODEL1
      @site.files('c').put('test1.mdlb', model, nil, 0)
      image = TEST_PNG_DATA
      @site.files('c').put('test1.gif', image, nil, 1)

      page.store("{{modulobe_model_list}}")
      res = session('/test/c.html')
      list = res.body.get_path("//div[@class='files']")
      ok_xp([:tr, {:class=>'model'},
	      [:td, [:a, {:href=>'c.files/test1.mdlb'},
		  [:img, {:src=>'c.files/.thumb/test1.gif'}]]],
	      [:td, [:div, {:class=>'author'}, 'Alice'],
		[:div, {:class=>'name'},
		  [:a, {:href=>'c.files/test1.mdlb'}, 't1 model']],
		[:pre, {:class=>'comment'}, "This is a comment.\n"]]],
	    "//div[@class='files']/table/tr[2]")
    end

    # ============================== rss
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

    def nu_test_metadata_model_xml
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

    # ============================== upload
    def prepare(con, im)
      content = WEBrick::HTTPUtils::FormData.new(MODULOBE_TEST_MODEL)
      content.filename = con
      image = WEBrick::HTTPUtils::FormData.new(TEST_PNG_DATA)
      image.filename = im
      return content, image
    end

    def test_upload
      t_add_user

      # test_modulobe_files_form
      page = @site.create('c')
      page.store('{{modulobe_files_form}}')
      res = session('/test/c.html')	# See the form.
      form = @res.body.get_path("//div[@class='section']/form")
      ok_eq({:method=>'POST', :action=>'c.modulobe_files_upload',
	      :enctype=>'multipart/form-data'}, form[1])
      ok_eq([:form, {:enctype=>'multipart/form-data',
		:method=>'POST', :action=>'c.modulobe_files_upload'},
	      [:table,
		[:tr,
		  [:th, 'Model file', ' : '],
		  [:td, [:input,
		      {:size=>'30', :type=>'file', :name=>'content'}]]],
		[:tr,
		  [:th, 'Image file', ' : '],
		  [:td, [:input,
		      {:size=>'30', :type=>'file', :name=>'image'}]]],
		[:tr,
		  [:td, ''],
		  [:td, [:input, {:value=>'Attach', :type=>'submit'}]]]]],
	    form)

      # test_upload
      content, image = prepare('test1.mdlb', 'test1.gif')
      session('POST /test/c.modulobe_files_upload') {|req|	# Put a file.
	req.query.update({'content'=>content, 'image'=>image})
      }
      ok_title('File attachment completed')
      sitelog = @site.sitelog	# Check log.
      ok_eq(",0.000000,user@e.com,modulobe file attach,c\n",
	    @site['_SiteLog'].load)

      # The model is attached.
      ok_eq("{{modulobe_files_form}}

* 
{{modulobe_model(test1.mdlb)
:title:\t\t
:author:\t
:comment:\t
}}
{{mcomment}}

", page.load)

      # Get the file.
      res = session('/test/c.files/test1.mdlb')
      assert_match(/\A<\?xml version="1\.0" encoding="utf-8"\?>/, res.body)
      ok_eq('application/x-modulobe', res['Content-Type'])

      # Get the image file.
      res = session('/test/c.files/test1.gif')
      ok_eq('image/gif', res['Content-Type'])
    end

    def test_with_invalid_character
      t_add_user

      page = @site.create('c')

      content, image = prepare('test 2.mdlb', 'test 2.gif')
      res = session('POST /test/c.modulobe_files_upload') {|req| # Put a file.
	req.query.update({'content'=>content, 'image'=>image})
      }
      ok_title('File attachment completed')
      ok_xp([:p, [:strong, 'test 2.mdlb'], ' : ', 'The file is saved.'],
	    "//div[@class='body_main']/p")

      # test_modulobe_files_upload_with_invalid_character
      content, image = prepare('test+2.mdlb', 'test 2.gif')
      res = session('POST /test/c.modulobe_files_upload') {|req|
	req.query.update({'content'=>content, 'image'=>image})
      }
      ok_title('File attachment completed')
      ok_xp([:p, [:strong, 'test+2.mdlb'], ' : ', 'The file is saved.'],
	    "//div[@class='body_main']/p")

      # Get the file.
      res = session('/test/c.files/test+2.mdlb')
      assert_match(/\A<\?xml version="1\.0" encoding="utf-8"\?>/, res.body)
      ok_eq('application/x-modulobe', res['Content-Type'])

      # Get the image file.
      res = session('/test/c.files/test+2.gif')
      ok_eq('image/gif', res['Content-Type'])
    end

    def test_with_japanese_character
      t_add_user
      page = @site.create('c')

      # Put files.
      content, image = prepare('c:\い\あ.mdlb', 'c:\い\あ.gif')
      res = session('POST /test/c.modulobe_files_upload') {|req|
	req.query.update({'content'=>content, 'image'=>image})
      }
      ok_title('File attachment completed')
      ok_xp([:p, [:strong, 'あ.mdlb'], ' : ', 'The file is saved.'],
	    "//div[@class='body_main']/p")

      # Get the file.
      res = session('/test/c.files/=E3=81=82.mdlb')
      assert_match(/\A<\?xml version="1\.0" encoding="utf-8"\?>/, res.body)
      ok_eq('application/x-modulobe', res['Content-Type'])

      # Put files again.
      # content and image are same.
      res = session('POST /test/c.modulobe_files_upload') {|req|
	req.query.update({'content'=>content, 'image'=>image})
      }
      ok_title('File attachment completed')
      ok_xp([:p, [:strong, 'あ.mdlb'], ' -> ', [:strong, '1-あ.mdlb'], ' : ',
	      'The file is saved with this filename.'],
	    "//div[@class='body_main']/p")

      # Get the file.
      res = session('/test/c.files/1-=E3=81=82.mdlb')
      assert_match(/\A<\?xml version="1\.0" encoding="utf-8"\?>/, res.body)
      ok_eq('application/x-modulobe', res['Content-Type'])
    end

  end
end
