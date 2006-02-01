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
    def plg_comment
      action = @req.base+'.comment'
      user = @req.user
      return [:div, {:class=>'comment'},
	[:form, {:action=>action},
	  [:dl,
	    [:dt, _('User')],
	    [:dd, [:em, user]],
	    [:dt, _('Message')],
	    [:dd, [:textarea, {:name=>'msg', :cols=>'40', :rows=>'7'}, '']],
	    [:dd, [:input, {:type=>'submit', :value=>'POST'}]]]]]
    end

    def ext_comment
      user = MailAddress.obfuscate(@req.user)
      ymdx = @req.start_time.ymdx

      msg = "\n" + @req.query['msg']
      msg = msg.normalize_newline
      msg = msg.gsub("\n", '{{br}}')
      content = ":#{user} (#{ymdx}):#{msg}\n"

      page = @site[@req.base]
      page.add(content)
      c_make_log('comment')	# COMMENT
      url = @req.base+'.html'
      return c_notice(_('Message is added.'), url) {
	[[:h2, _('Message is added.')],
	  [:p, [:a, {:href=>url}, _('Go back')]]]
      }
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActComment < Test::Unit::TestCase
    include TestSession

    def test_plg_comment
      t_add_user
      ok_wi([:div, {:class=>'comment'},
	      [:form, {:action=>'1.comment'},
		[:dl,
		  [:dt, 'User'],
		  [:dd, [:em, 'user@e.com']],
		  [:dt, 'Message'],
		  [:dd, [:textarea,
		      {:rows=>'7', :name=>'msg', :cols=>'40'}, '']],
		  [:dd, [:input, {:value=>'POST', :type=>'submit'}]]]]],
	    '{{comment}}')
    end

    def test_all
      t_add_user

      page = @site.create_new
      page.store('{{comment}}')

      res = session('/test/1.html')
      ok_xp([:textarea, {:cols=>'40', :rows=>'7', :name=>'msg'}, ''],
	    '//textarea')

      # The 1st comment.
      res = session('/test/1.comment?msg=Hi')
      ok_title('Message is added.')

      res = session('/test/1.html')
      ok_xp([:dl, [:dt, 'user@e... (1970-01-01 09:00:00)'], [:dd, [:br], 'Hi']],
	    "//div[@class='section']/dl[2]")

      page = @site['_SiteChanged']
      assert_match(/^,[.0-9]+,user@e.com,comment,1$/, page.load)

      # The 2nd comment.
      res = session('/test/1.comment?msg=hello%0aworld')
      ok_title('Message is added.')

      res = session('/test/1.html')
      ok_xp([:dl,
	      [:dt, 'user@e... (1970-01-01 09:00:00)'],
	      [:dd, [:br], 'Hi'],
	      [:dt, 'user@e... (1970-01-01 09:00:00)'],
	      [:dd, [:br], 'hello', [:br], 'world']],
	    '//div[@class="section"]/dl[2]')

      page = @site['_SiteChanged']
      assert_match(/^,[.0-9]+,user@e.com,comment,1$/, page.load)
    end
  end
end
