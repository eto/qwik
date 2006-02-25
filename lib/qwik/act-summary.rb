#
# Copyright (C) 2005 Masashi Miyamura
# Copyright (C) 2003-2006 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    D_plugin_summary = {
      :dt => 'Show summary of a target page',
      :dd => 'You can include summary of target page.',
      :dc => "
In this plugin, the summary of a page means
the first section of the page.
* Example
You can see summary of FrontPage here.
 {{summary(FrontPage)}}
{{summary(FrontPage)}}
"
    }

    def plg_summary(pagename, no_title = false)
      return nil if defined?(@summary_running) && @summary_running

      @summary_running = true

      org_base = @req.base
      @req.base = pagename

      page = @site[pagename]
      summary = page.get_summary

      title = [:div, [:h2, [:a, {:href=>"#{page.key}.html"}, page.get_title]]]

      if summary.nil? or summary.empty?        
        unless no_title
          summary = title
        else
          summary = nil
        end
      else
        w = c_res(summary)
        summary = TDiaryResolver.resolve(@config, @site, self, w)
        summary = title << summary unless no_title
      end

      @req.base = org_base

      @summary_running = false
      return summary
    end
  end ### class Action

  class Page
    def get_summary
      body = self.get_body
      
      str = ''
      body.split("\n").each do |line|
        if (/^\*/ =~ line)
          break
        else
          str += (line + "\n")
        end
      end
      
      return str
    end ### get_summary
  end ### class Page
end ### module Qwik

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestPageClassMethod < Test::Unit::TestCase
    include TestSession

    def test_get_summary
      page = @site.create_new
      page.store("* [This is a tag.] t1
summary1
summary2
* section1
body of section1")
      
      ok_eq("summary1\nsummary2\n", page.get_summary)
    end
  end

  class TestActSummary < Test::Unit::TestCase
    include TestSession

    def test_summary
       page = @site.create_new
       page.store("* t1
* t1")

      page2 = @site.create_new
      page2.store("* t2
Here is a summary.
Summary continued.
* Section 1 of t2
contents in Sec. 1.
* Section 2 of t2
contents in Sec. 2.")

      page3 = @site.create_new
      page3.store("* t3
# an empty summary
* Section 1 of t3
contents in Sec. 1.")

      page4 = @site.create_new
      page4.store("* t4
This is a summary of t4.
* Section")

      summary_w = [:div, {:class=>'day'},
        '',
        [:div,
          {:class=>'body'},
          [:div, {:class=>'section'}, 
            [[:p, 'Here is a summary.', "\n", 'Summary continued.']]]]]

      # test_for_recursive_call
      ok_wi([:div,
	      [:h2, [:a, {:href=>'1.html'}, '1']],
	      [[:div,
		  {:class=>'day'},
		  '',
		  [:div, {:class=>'body'}, [:div, {:class=>'section'}, []]]]]],
            "{{summary(#{page.key})}}")
      
      ok_wi([:div, [:h2, [:a, {:href=>page2.url}, page2.get_title]],
            [summary_w]],
            "{{summary(#{page2.key})}}")

      ok_wi(summary_w,
            "{{summary(#{page2.key}, 't')}}")

      ok_wi([:div, [:h2, [:a, {:href=>page3.url}, page3.get_title]]],
            "{{summary(#{page3.key})}}")
      
      ok_wi([], "{{summary(#{page3.key}, 't')}}")

      # test for many summaries
      ok_wi(summary_w, # becaus page3 has an empty summary
            "{{summary(#{page3.key}, 't')}}\n{{summary(#{page2.key}, 't')}}")
    end
  end
end
