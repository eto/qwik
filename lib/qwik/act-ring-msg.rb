#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '..' unless $LOAD_PATH.include?('..')
require 'qwik/act-ring-catalog'
require 'qwik/act-ring-user'

module Qwik
  class Action
    # ============================== write a message
    # http://colinux:9190/ring.sfc.keio.ac.jp/_TestActRingMsg.html
    def plg_ring_message_form(arg=nil)
      action = @req.base+'.ring_msg'
      username = @req.user
      div = [:div, {:class=>'form'},
	[:form, {:method=>'POST', :action=>action},
	  [:table,
	    [:tr,
	      [:th, _r(:BULLET)+_r(:USER)],
	      [:td, username]],
	    [:tr,
	      [:th, _r(:BULLET)+_r(:MESSAGE)],
	      [:td, [:textarea, {:name=>'message', :cols=>'40', :rows=>'7'},
		  _r(:MSG_INPUT_HERE)]]],
	    [:tr,
	      [:th, ''],
	      [:td, [:input, {:type=>'submit', :class=>'submit',
		    :value=>" POST! "}]]]]]]
      return div
    end

    def plg_ring_message_go(arg=nil)
      return	# obsolete
    end

    # Append a a message to the page.
    def ext_ring_msg
      c_require_page_exist

      href = @req.base+'.html'
      message = @req.query['message']

      # Check error.
      if !message || message == '' || message == _r(:MSG_INPUT_HERE)
	return ring_msg_input_message(href)
      end

      mail = @req.user
      datenum = @req.start_time.to_i.to_s

      # Add a message.
      content = ":{{ring_ul(#{mail})}} ({{ring_date(#{datenum})}}):#{message}\n"
      page = @site[@req.base]
      page.add(content)

      return c_notice(_r(:MSG_MESSAGE_IS_ADDED), href){
	[[:h3, _r(:MSG_MESSAGE_IS_ADDED)],
	  [:p, _r(:THANKYOU)],
	  [:p, [:a, {:href=>href}, _('Go back')]]]
      }
    end

    def ring_msg_input_message(href)
      return c_notice(_r(:MSG_INPUT_MESSAGE), href, 200, 3) { # 3sec.
	[[:h3, _r(:MSG_INPUT_MESSAGE)],
	  [:p, [:a, {:href=>href}, _('Go back')]]]
      }
    end

    def plg_ring_date(n)
      time = Time.at(n.to_i)
      return [:span, {:class=>'ring_date'}, time.ymdx]
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActRingMsg < Test::Unit::TestCase
    include TestSession

    def test_plg_ring_message_form
      t_add_user

      page = @site.create_new
      page.store("{{ring_message_form}}")

      # See the message form.
      res = session('/test/1.html')
      div = res.body.get_path("//div[@class='form']/form")
      ok_eq({:method=>'POST', :action=>'1.ring_msg'}, div.attr)
      ok_eq([:tr, [:th, "●ユーザ名"], [:td, 'user@e.com']],
	    div.get_path('/table/tr'))
      ok_xp([:input, {:value=>" POST! ", :type=>'submit', :class=>'submit'}],
	    "//div[@class='form']/input")
    end

    def test_ext_ring_msg
      t_add_user

      page = @site.create_new
      page.store('')

      # Try to write, but it cause error.
      res = session('/test/1.ring_msg')
      ok_in(["メッセージを入力してください"], '//h3')

      # Try to write, but it cause error.
      res = session("/test/1.ring_msg?message=")
      ok_in(["メッセージを入力してください"], '//h3')

      # Send a message.
      res = session("/test/1.ring_msg?message=Hi")
      ok_in(["メッセージを追加しました"], '//h3')

      # Check the content.
      ok_eq(":{{ring_ul(user@e.com)}} ({{ring_date(0)}}):Hi\n", page.load)
    end

    def test_ring_link
      page = @site.create('_RingMember')
      page.store(",gu@e.com,gugu,T Y,ei,1990,1,0\n")

      ok_wi([:p, [:a, {:href=>'1.html'}, "ゲスト"]], "[[ゲスト|1]]")
      ok_wi([:a, {:href=>'1.html'}, 'gugu'], "{{ring_link('gu@e.com')}}")
      ok_wi([:span, {:class=>'ring_ul'}, [:a, {:href=>'1.html'}, 'gugu']],
	    "{{ring_ul('gu@e.com')}}")
    end
  end
end
