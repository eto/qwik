# -*- coding: shift_jis -*-
# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

# Under constraction.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/site-member'

module Qwik
  class Action
    NotYet_D_ExtMember = {
      :dt => 'Member control function',
      :dd => 'Member control.',
      :dc => "* How to
** Member add
[[.member_add]]
** Member list
[[.member_list]]
** Member list in CSV format
[[.member_list_csv]]
"
    }

    def act_member_add
      if @req.query && tomail = @req.query['tomail']
	return member_add_exec(tomail)
      end
      return member_add_form
    end

    def member_add_form
      return c_notice(_('Add a member')) {
	[[:form, {:action=>".member_add",
	      :style=>'text-align: center; margin: 32px 0 32px;'},
	    [:p, [:em, _('Mail address to add'), ': ']],
	    [:p, [:input, {:name=>'tomail', :class=>'focus'}]],
	    [:div, {:class=>'rightbutton'},
	      [:input, {:value=>_('Add'), :type=>'submit'}]]],
	  [:hr],
	  [:p, [:a, {:href=>'FrontPage.html'}, _('Go back')]]]
      }
    end

    def member_add_exec(tomail)
      return member_error(_('Error')) if tomail.nil?
      return member_error(_('Invalid Mail')) if ! MailAddress.valid?(tomail)
      return member_error(_('Already exists')) if @site.member.exist?(tomail)

      @site.member.add(tomail, @req.user)

      c_make_log("member_add\t#{tomail}")	# member_add

      return member_error(_('Error')) if ! @site.member.exist?(tomail)

      return c_notice(_('Member added')) {
	[[:p, _('Member added')],
	  [:hr],
	  [:p, [:a, {:href=>'.member_add'}, _('Go back')]]]
      }
    end

    def member_error(title)
      return c_nerror(title) {
	[[:p, title],
	  [:hr],
	  [:p, [:a, {:href=>'.member_add'}, _('Go back')]]]
      }
    end

    def act_member_list
      list = @site.member.list
      return c_notice(_('Member list')) {
	[[:ul] + list.sort.map {|user| [:li, user] },
	  [:p, _('Member'), ': ', list.length.to_s]]
      }
    end

    CSV_DIVIDE = 50
    def act_member_list_csv
      list = @site.member.list
      str = ''
      list.sort.each_with_index {|user, i|
	str += user+((i % CSV_DIVIDE == 0) ? "\n" : ', ')
      }
      return c_plain(_('Member list')) {
	[:div, {:class=>'day'},
	  [:h2, _('Member list')],
	  [:form, {:action=>".member_list_csv"},
	    [:textarea, {:class=>'memberlist'}, str]
	  ]
	]
      }
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActMember < Test::Unit::TestCase
    include TestSession

    def nutest_member_plugin_unit
      ok_wi([:form, {:action=>'1.html'},
	      [:p, '新規メンバーを追加します。'],
	      [:dl,
		[:dt, 'あなたのメール'],
		[:dd, [:em, 'user@e.com']],
		[:dt, '追加メール'],
		[:dd, [:input, {:name=>'tomail'}]],
		[:dd, '追加したい人のメールアドレスを入力してください。'],
		[:dd, [:input, {:value=>'追加', :type=>'submit'}]]]],
	    '{{member_add}}')
    end

    def test_member_plugin
      t_add_user

      # test_act_member_add
      res = session('/test/.member_add')
      ok_title('Add a member')
      ok_xp([:form,
	      {:action=>".member_add",
		:style=>"text-align: center; margin: 32px 0 32px;"},
	      [:p, [:em, "Mail address to add", ": "]],
	      [:p, [:input, {:class=>"focus", :name=>"tomail"}]],
	      [:div, {:class=>"rightbutton"},
		[:input, {:value=>"Add", :type=>"submit"}]]],
	    '//form')

      res = session('/test/.member_add?tomail=guest@example.com')
      ok_title('Member added')
      ok_eq(true, @site.member.exist?('guest@example.com'))
      ok_eq(',user@e.com,
,guest@example.com,user@e.com
',
	    @site['_SiteMember'].load)

      # test_act_member_list
      res = session('/test/.member_list')
      ok_title('Member list')
      ok_in([[:ul, [:li, "guest@example.com"], [:li, "user@e.com"]],
	      [:p, "Member", ": ", "2"]],
	    "//div[@class='section']")

      # test_act_member_list_csv
      res = session('/test/.member_list_csv')
      ok_title('Member list')
      ok_in(["guest@example.com\nuser@e.com, "], "//textarea")
    end
  end
end
