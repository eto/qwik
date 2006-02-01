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
    def plg_show_tags
      page = @site[@req.base]
      return if page.nil?
      tags = page.get_tags
      return nil if tags.nil?
      div = [:div, {:class=>'tags'}]
      tags.each {|tag|
	div << [:a, {:href=>tag+".tag"}, tag]
      }
      return div
    end

    def self.tag_get_pages(site)
      pages = Hash.new {|h, k| h[k] = []}
      site.each {|page|
	tags = page.get_tags
	next if tags.nil?
	tags.each {|tag|
	  pages[tag] << page.key
	}
      }
      return pages
    end

    def ext_tag
      target_tag = @req.base

      all_pages = Action.tag_get_pages(@site)
      pages = all_pages[target_tag]
      return c_nerror('no such tag') if pages.empty?

      div = [:div, {:class=>'tag_pages'}]
      pages.each {|key|
	page = @site[key]
	body = surface_get_body(page)
	div += body
      }
      return c_surface('tag'+' : '+target_tag){
	div
      }
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActTag < Test::Unit::TestCase
    include TestSession

    def test_all
      t_add_user

      # test_plg_show_tags
      page = @site.create_new
      page.store("* [t1][t2] t
{{show_tags}}")
      res = session('/test/1.html')
      ok_xp([:title, 't'], '//title')
      ok_xp([:div, {:class=>'tags'},
	      [:a, {:href=>'t1.tag'}, 't1'],
	      [:a, {:href=>'t2.tag'}, 't2']], "//div[@class='tags']")

      # Make pages with tag 't1'.
      page1 = @site['1']
      page1.store("* [t1] page1
body1")
      page2 = @site.create('2')
      page2.store("* [t1] page2
body2")

      # test_tag_get_pages
      pages = Qwik::Action.tag_get_pages(@site)
      ok_eq({'t1'=>['1', '2']}, pages)

      # test_act_tag
      res = session('/test/nosuch.tag')
      ok_xp([:title, 'no such tag'], '//title')

      res = session('/test/t1.tag')
      ok_xp([:title, 'tag : t1'], '//title')
      ok_xp([:div, {:class=>'tag_pages'},
	      [:div, {:class=>'day'}, '',
		[:div, {:class=>'body'},
		  [:div, {:class=>'section'}, [[:p, 'body1']]]]],
	      [:div, {:class=>'day'}, '',
		[:div, {:class=>'body'},
		  [:div, {:class=>'section'}, [[:p, 'body2']]]]]],
	    "//div[@class='tag_pages']")
    end
  end
end
