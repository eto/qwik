# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require "qwik/act-search"

module Qwik
  class Action
    def plg_search_word_cloud
      list = @site.get_search_words
      [:span] + list.map{|em| 
        w = em.word.to_s.escape
	if em.nil?
	  em = Word.new(w, 1, Time.new)
	end
        [[:span, {:class => "search_word#{em.count}"},
          [:a, {:href => ".search?q=#{w}"}, em.word]],
	 [:span, {:class => "search_word_delete"},
          [:a, {:href => ".delete?q=#{w}"},
           [:img, {:src => ".theme/css/delete.png",:border =>"0",
              :alt => "del"}]]]]
      }
    end

    # search word delete action
    def act_delete
      query = search_get_query
      if query
        @site.delete_search_word(query)
      end
      return c_notice("Deleted",@req.header["referer"]) { "deleted" }
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActSearchWords < Test::Unit::TestCase
    include TestSession

    def test_dummy
    end
  end
end


