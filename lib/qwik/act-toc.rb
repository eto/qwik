# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/wabisabi-template'

module Qwik
  class Action
    REPLACE_TOC = {
      :h2=>[:ol, 1],
      :h3=>[:ol, 2],
      :h4=>[:ol, 3],
      :h5=>[:ol, 4],
      :h6=>[:ol, 5],
    }

    # FIXME: Use tokenes instead of tree.
    def toc_inside
      page = @site[@req.base]
      return nil if page.nil?
      wabisabi = page.get_body_tree
      wabisabi ||= []

      res = TDiaryResolver.new(@config, @site, self)
      
      tokens = []
      wabisabi.each_tag(:h2, :h3, :h4, :h5, :h6) {|w|
	tag = w.element_name
	head = REPLACE_TOC[tag]
	name = TDiaryResolver.get_title_name(w)
	if tag == :h2
	  label = res.encode_label(name)
	  link = [[:a, {:href=>"#"+label}, w.text]]
	  w = head + [link]
	else
	  w = head + [w.text]
	end
	tokens << w
      }
      return nil if tokens.length == 0

      w = TextParser.make_tree(tokens).get_single
      w = [[:h5, _('Contents')],
	[:div, {:id=>'tocinside'}, w]]
      return w
    end

    def plg_toc # deleted
      return nil
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActTOC < Test::Unit::TestCase
    include TestSession

    def test_toc
      t_add_user
      page = @site.create_new

      page.store("{{toc}}
*t1
*t2")
      session('/test/1.html')
      ok_in([[:h5, 'Contents'],
	      [:div, {:id=>'tocinside'},
		[:ol, [:li, [:a, {:href=>"#t1"}, 't1']],
		  [:li, [:a, {:href=>"#t2"}, 't2']]]]],
	    "//div[@class='toc']")

      # test with []
      page.store("{{toc}}
*t1
**t2")
      session('/test/1.html')
      ok_in([[:h5, 'Contents'],
 [:div, {:id=>'tocinside'},
  [:ol, [:li, [:a, {:href=>"#t1"}, 't1']], [:ol, [:li, 't2']]]]],
	    "//div[@class='toc']")

      # test with []
      page.store("{{toc}}
*[hoge]hhh")
      session('/test/1.html')
      ok_in([[:h5, 'Contents'],
 [:div,
  {:id=>'tocinside'},
  [:ol, [:li, [:a, {:href=>"#815417267f76f6f460a4a61f9db75fdb"}, "[hoge]hhh"]]]]],
	    "//div[@class='toc']")


      # test with []
      page.store("{{toc}}
*t1
***[hoge]hhh")
      session('/test/1.html')
      ok_in([[:h5, 'Contents'],
 [:div,
  {:id=>'tocinside'},
  [:ol, [:li, [:a, {:href=>"#t1"}, 't1']], [:ol, [:ol, [:li, "[", 'hoge', "]", 'hhh']]]]]],
	    "//div[@class='toc']")

    end
  end
end
