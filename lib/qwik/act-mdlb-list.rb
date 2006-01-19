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
    def plg_modulobe_model_list
      pagename = @req.base
      page = @site[pagename]
      return if page.nil?

      files = @site.files(pagename)
      page.cache[:modellist] ||= Modulobe::ModelList.new(files)
      modellist = page.cache[:modellist]
      return if modellist.empty?

      div = [:div, {:class=>'files'}]
      path = c_relative_to_absolute(pagename+'.files')
      div << modellist.get_table(self, path)
      div << modellist.get_style
      return div
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
  end
end
