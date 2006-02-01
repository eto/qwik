#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

# special mode for modulobe.com

$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'
require 'qwik/act-files'
require 'qwik/act-mdlb-list'

module Qwik
  class Action
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
	  ' : ', _('The file is saved as this filename.')]
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
      return c_surface(_('Attach file done')){list}
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
  class TestActModulobeUpload < Test::Unit::TestCase
    include TestSession
    include Modulobe::Sample

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
      ok_title('Attach file done')
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
      ok_title('Attach file done')
      ok_xp([:p, [:strong, 'test 2.mdlb'], ' : ', 'The file is saved.'],
	    "//div[@class='body_main']/p")

      # test_modulobe_files_upload_with_invalid_character
      content, image = prepare('test+2.mdlb', 'test 2.gif')
      res = session('POST /test/c.modulobe_files_upload') {|req|
	req.query.update({'content'=>content, 'image'=>image})
      }
      ok_title('Attach file done')
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
      content, image = prepare('c:\‚¢\‚ .mdlb', 'c:\‚¢\‚ .gif')
      res = session('POST /test/c.modulobe_files_upload') {|req|
	req.query.update({'content'=>content, 'image'=>image})
      }
      ok_title('Attach file done')
      ok_xp([:p, [:strong, '‚ .mdlb'], ' : ', 'The file is saved.'],
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
      ok_title('Attach file done')
      ok_xp([:p, [:strong, '‚ .mdlb'], ' -> ', [:strong, '1-‚ .mdlb'], ' : ',
	      'The file is saved as this filename.'],
	    "//div[@class='body_main']/p")

      # Get the file.
      res = session('/test/c.files/1-=E3=81=82.mdlb')
      assert_match(/\A<\?xml version="1\.0" encoding="utf-8"\?>/, res.body)
      ok_eq('application/x-modulobe', res['Content-Type'])
    end
  end
end
