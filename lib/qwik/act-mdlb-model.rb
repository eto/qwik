#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

# special mode for modulobe.com

$LOAD_PATH << '..' unless $LOAD_PATH.include?('..')
require 'qwik/modulobe'

module Qwik
  class Action
    def plg_modulobe_model(model)
      div = [:div, {:class=>'modulobe_model'}]

      # image
      files = @site.files(@req.base)
      file = files.path(model)

      return [:div, 'No file exist.'] if ! file.exist?
      model = Modulobe::ModelFile.new(file)

      href, url, img = model.prepare_link(self, @req.base+'.files')

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
	div << [:style, '

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

']
      end

      return div
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActModulobeModel < Test::Unit::TestCase
    include TestSession
    include Modulobe::Sample

    def test_all
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
  end
end
