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
require "qwik/common-plain"

module Qwik
  class Action

    def act_report
      c_require_login

      ids = []
      tags = []
      @req.query.each do |k, v|
        ids << k if v == 'on'
        tags += v.split('|') if k == 'tags'
      end

      if ids.empty?
        return c_notice(_("New Report Page"), '.new', 200) {	# 200
          [[:h2, _("Make a new report.")],
            [:p, [:a, {:href=>'.new'}, _("Make a rew repor.")]]]
        }
      end

      form = [:form, {:action=>'.save_report', :method=>'POST'}]

      pages = ''
      summaries = ''
      ids.each do |id|
        pages += "- [[#{id}]]\n"
        summaries += "{{summary(#{id})}}\n"
      end
      tags = tags.map {|tag| "[#{tag}]"}.to_s unless tags.empty?
      title = [:input, {:name=>'title', :class=>'focus', :size=>'80',
          :value=>"#{tags} Report of #{ids.sort.join(', ')}"}]
      form << [:div, title]

      ta = [:textarea, {:name=>'content', 
          :rows=>'20', :cols=>'80'}, 
        pages + "\n# Summary\n" + summaries]
      form << ta
      form << [:div, [:input, {:type=>'submit', :value=>_('Save'), :class=>'submit'}]]

      div = [:div]
      div << form
      return c_plain(_('Make a Report')) { TDiaryResolver.resolve(@config, @site, self, div) }
    end

    def act_save_report
      c_require_login
      c_require_post

      title = @req.query['title']
      # Check if the title is already exist.      
      page_title, tags = Qwik::Page.parse_title(title)
      page = @site.get_by_title(page_title)
      return new_already_exist(page_title, page.key) if page

      content = @req.query['content']
      if content.nil? or content.empty?
        return c_nerror('No content') {
          [[:p, 'You cannot make an empty report.'],
            [:p, [:a, {:href=>".tags?q=#{tags.join('|')}"}, _('Back')]]]
        }
      end

      key = @site.get_new_id
      create_save_page(key, '* ' + title + "\n" + content)

      url = key + '.html'
      return c_notice(_("Report is saved."), url){
        [:p, [:a, {:href=>url}, _("Read your report.")]]
      }
    end

    def create_save_page(key, content)
      begin
        page = @site.create(key)  # CREATE
      rescue PageExistError
        # Is there any other better solution?
        return save_conflict(content)
      end
      c_make_log('create', key)		# CREATE
      c_monitor('create' + key)		# CREATE

      require 'qwik/act-save'
      ### BEGIN from act-save.rb
      newcontent = page.embed_password(content) # embed the password
      if !page.match_password?(newcontent)
	return save_password_does_not_match(content)
      end
      content = newcontent

      content = content.gsub(/\r/, "")
      md5hex = @req.query["md5hex"]
      md5hex = nil if page.have_password?
      begin
	page.put_with_md5(content, md5hex) # STORE
      rescue PageCollisionError # failed to save?
	return save_conflict(content)
      end

      c_make_log("save", key) # STORE
      c_monitor("save") # STORE
      c_event("save") # STORE
      
      return
    end
  end # class Action
end

if $0 == __FILE__
  require "qwik/test-common"
  $test = true
end

if defined?($test) && $test
  class TestActReport < Test::Unit::TestCase
    include TestSession

    
    def test_act_report
      res = session('/test/.report')
      ok_title('Member Only')

      t_add_user

      # no argument
      res = session('/test/.report')
      ok_title('New Report Page')

      # valid
      res = session('/test/.report?1=on&2=on&tags=TAG1|TAG2')
      ok_xp([:form, {:action=>'.save_report', :method=>'POST'},
              [:div,
                [:input, {:size=>'80', :name=>'title', :value=>'[TAG1][TAG2] Report of 1, 2', :class=>'focus'}]],
        [:textarea, {:name=>'content', :rows=>'20', :cols=>'80'}, 
                '- [[1]]
- [[2]]

# Summary
{{summary(1)}}
{{summary(2)}}
'],
        [:div, [:input, {:type=>'submit', :value=>'Save', :class=>'submit'}]]],
            '//form')
    end

    def test_save_report
      res = session('/test/.save_report')
      ok_title('Member Only')

      t_add_user

      res = session('/test/.save_report')
      ok_title('Need POST')
    end
  end
end
