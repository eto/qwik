#
# Copyright (C) 2005 Masashi Miyamura
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '..' unless $LOAD_PATH.include?('..')
require 'qwik/act-summary' # Page.get_summary()
require 'qwik/common-plain' # c_plain()
require 'qwik/act-tag' # self.tag_get_pages()

module Qwik
  class Action
    def plg_all_tags
      tags_hash = Action.tag_get_pages(@site)
      return nil if tags_hash.nil? or tags_hash.empty?

      div = [:div, {:class=>'tags'}]
      tags = tags_hash.keys.sort
      tags.each do |tag|
        div <<
          [:a, {:href=>".tags?q=#{URI.encode(tag)}"},
          "#{tag} (#{tags_hash[tag].length})"] << ' '
      end
      return div
    end

    def act_tags
      c_require_login

      target_tags = @req.query['q']
      if target_tags.nil? or target_tags.empty?
        return c_plain('no tag') {
          [:div, {:align=>'center'}] << 
            tag_search_form(size = '80', focus = true)
        }
      end

      tags = target_tags.split(',').map {|tag| tag.strip}

      all_tagged_pages = Action.tag_get_pages(@site)

      all_pages = []
      @site.each { |page| all_pages << page.key}
      pages = all_pages

      tags.each do |tag|
        if pages.empty?
          pages = all_pages & all_tagged_pages[tag]
        else
          pages = pages & all_tagged_pages[tag]
        end
      end

      if pages.empty?
        return c_plain('no match') {
          [:div, {:align=>'center'}] << 
            tag_search_form(size = '80', focus = true, tags = tags)
        }
      end
      pages.uniq!

      pages = pages.sort do |p1, p2| 
        @site[p1].mtime <=> @site[p2].mtime
      end.reverse

      return c_plain("tag: #{pages.length} hits") {
        tag_search_result(pages, tags) 
      }
    end

    def plg_tag_search_form(size)
      size = '80' if size.nil? or size.empty?
      size = size.to_s
      return tag_search_form(size)
    end

    def tag_search_form(size = '80', focus = nil, tags = [])
      attr = {:size=>size, :name=>'q', :value=>tags.join(', ')}
      attr[:class] = 'focus' unless focus.nil?

      form = [:form, {:action=>'.tags'}]
      form << [:input, attr]
      form <<
        [:input, {:type=>'submit', :value=>_('Tag Search'), :class=>'submit'}]
      return form
    end

# Future Work
#     def tag_editor(tags = [])
#       return if tags.empty?
#       form = [:form, {:action=>'.tag_save'}]
#       tags.each do |tag|
#         form << [:div, tag, ' ==> ', [:input, {:name=>tag, :value=>tag}]]
#       end
#       form << [:input, 
#         {:type=>'submit', :class=>'submit', :value=>_('Change Tags')}]
#     end

    def page_selector(pages, tags = [])
      form = [:form, {:action=>'.report'}] # must set action
      submit = 
        [:input, {:type=>'submit', :value=>_('Report'), :class=>'submit'}]
      select_all = [:a, {:onclick=>''}, 'All']

      form << [:div, submit]
      form << [:input, {:type=>'hidden', :name=>'tags', :value=>tags.join('|')}]

      body = []
      org_base = @req.base
      pages.each do |key|
        @req.base = key

        page = @site[key]
        summary = page.get_summary

        page_title = [:h2, [:input, {:type=>'checkbox', :name=>key}],
          " [#{key}] ",
          [:a, {:href=>"#{page.key}.html"}, page.get_title], ' ',
          [:a, {:href=>"#{key}.edit"}, _('Edit')] ]

        summary = c_res(summary)

        other_tags = []
        page.get_tags.each do |tag|
          next if tags.include?(tag)
          other_tags <<
            [:a, {:href=>".tags?q=#{URI.encode(tag)}"}, tag] << ' '
        end
        other_tags = 
          [:div, {:class=>'tags'}] << other_tags unless other_tags.empty?
        body << page_title << summary << other_tags
      end
      @req.base = org_base

      form << TDiaryResolver.resolve(@config, @site, self, body)
      form << [:div, submit, ' ']

      return form
    end
    
    def tag_search_result(pages, target_tags)
      search_form = 
        [:div, {:align=>'center'}] << tag_search_form('80', nil, target_tags)
      div = [:div, {:class=>'searh_result_pages'}]
      div << page_selector(pages, target_tags)
      return [search_form, div, search_form]
    end

    def describe_tags
      '* Show tags assigned to that page
* Example:
  {{tags}}
'
    end

    def plg_tags
      key = @req.base
      page = @site[key]
      tags = page.get_tags
      return nil if tags.nil? or tags.empty?

      div = [:div, {:class=>'tags'}]
      tags.each do |tag|
        div << [:a, {:href=>".tags?q=#{URI.encode(tag)}"}, tag] << ' '
      end
      return div
    end
  end # class Action
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActTagsearch < Test::Unit::TestCase
    include TestSession

    def test_act_tags
      page = @site.create_new
      res = session('/test/.tags')
      ok_title('Member Only') # require login
      page.delete

      t_add_user

      page1 = @site.create_new
      page1.store('* [TAG1] Title 1')

      sleep(1) # for mtime comparisions
      page2 = @site.create_new
      page2.store('* [TAG2] Title 2')

      sleep(1)
      page3 = @site.create_new
      page3.store('* [TAG3][TAG1] Title 3')

      res = session('/test/.tags?q=nosuchtag')
      ok_title('no match')

      # no query
      res = session('/test/.tags') 
      ok_title('no tag')

      res = session('/test/.tags?q=TAG1,TAG2')
      ok_title('no match')
      ok_xp([:input, {:value=>'TAG1, TAG2', :name=>'q', :size=>'80', :class=>'focus'}],
            '//input[@name="q"]')

      res = session('/test/.tags?q=TAG1, TAG3')
      ok_title('tag: 1 hits')
      ok_xp([:h1, 'tag: 1 hits'], '//h1')
      ok_xp([:input, {:type=>'checkbox', :name=>'3'}], '//h2/input')
    end

    def test_tag_search_form
      res = session
      ok_eq([:form, {:action=>'.tags'},
              [:input, {:size=>'80', :value=>'', :name=>'q'}],
              [:input, {:type=>'submit', :class=>'submit', :value=>'Tag Search'}]], 
            @action.tag_search_form)
            
    end

# Future Work
#     def test_tag_editor
#
#     end

    def test_page_selector
      t_add_user
      page = @site.create_new
      page.store('* [TAG1] Title')
      res = session('/test/.tags?q=TAG1')

      ok_xp([:input, {:type=>'checkbox', :name=>'1'}],
            '//input[@type="checkbox"]')
    end

    def test_plg_tags
      t_add_user

      page = @site.create('1')
      page.store('* [TAG1][TAG 2] Title 1
{{tags}}')
      res = session('/test/1.html')
      ok_xp([:div, {:class=>'tags'}, 
              [:a, {:href=>'.tags?q=TAG1'}, 'TAG1'], ' ',
              [:a, {:href=>'.tags?q=TAG%202'}, 'TAG 2'], ' '],
            '//div[@class="tags"]')

      page_dummy = @site.create('2')
      page_dummy.store('* No tag page
{{tags}}')
      res = session('/test/2.html')
      ok_xp(nil, '//div[@class="tags"]')
    end

    def test_plg_all_tags
      t_add_user

      res = session
      ok_xp(nil, '//div[@class="tags"]')

      page1 = @site.create_new
      page1.store('* [TAG1][TAG2] Title 1')

      page2 = @site.create_new
      page2.store('* [TAG2] Title 2')

      page3 = @site.create_new
      page3.store('* [TAG2][TAG3] Title 3')

      page4 = @site.create_new
      page4.store('* Title 4
{{all_tags}}')
      res = session('/test/4.html')

      ok_xp([:div, {:class=>'tags'},
              [:a, {:href=>'.tags?q=TAG1'}, 'TAG1 (1)'], ' ',
              [:a, {:href=>'.tags?q=TAG2'}, 'TAG2 (3)'], ' ',
              [:a, {:href=>'.tags?q=TAG3'}, 'TAG3 (1)'], ' '],
            '//div[@class="tags"]')
              
    end
  end
end
