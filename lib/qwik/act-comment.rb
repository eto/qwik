# -*- coding: shift_jis -*-
# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    D_PluginComment = {
      :dt => 'Comment plugin',
      :dd => 'You can show comment field.',
      :dc => "
* Multiline comment plugin
You can show a multi line comment field.
{{mcomment}}
 {{mcomment}}
Add (1) to args, then you see the newest comment on the top.
 {{mcomment(1)}}
* Hiki like comment plugin
You can show a Hiki like comment field.
 {{hcomment}}
{{hcomment}}
Add (1) to args, then you see the newest comment on the top.
 {{hcomment(1)}}
* Old comment plugin
This plugin is obsolete.  Please use 'mcomment' plugin instead.
 {{comment}}
{{comment}}
"
    }

    D_PluginComment_ja = {
      :dt => 'コメント・プラグイン',
      :dd => 'コメント入力欄を表示します。',
      :dc => "
* 複数行コメント・プラグイン
複数行入力できるコメント・プラグインです。
{{mcomment}}
 {{mcomment}}
このように、(1)をつけると、新しいコメントが一番上につくようになります。
 {{mcomment(1)}}
* Hiki風コメント・プラグイン
Hikiのコメント・プラグインとほぼ同じ使い方ができます。
{{hcomment}}
 {{hcomment}}
同様に、(1)をつけると、新しいコメントが一番上につくようになります。
 {{hcomment(1)}}
* 旧コメント・プラグイン
古い仕様のコメントプラグインですので、利用は推奨しません。
「mcomment」プラグインを推奨します。
{{comment}}
 {{comment}}
"
    }

    # ============================== comment
    def plg_comment
      action = "#{@req.base}.comment"
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
      return c_notice(_('Message has been added.'), url) {
	[[:h2, _('Message has been added.')],
	  [:p, [:a, {:href=>url}, _('Go back')]]]
      }
    end

    # ============================== Hiki style comment
    def plg_hcomment(style='0')
      action = @req.base+'.hcomment'

      style = style.to_i
      style = 0 if style != 1

      # @hcomment_num is global for an action.
      @hcomment_num = 0 if !defined?(@hcomment_num)
      @hcomment_num += 1
      num = @hcomment_num

      return [:div, {:class=>'hcomment'},
	[:form, {:method=>'POST', :action=>action},
	  _('Name'), ': ', [:input, {:name=>'name', :size=>10}], ' ',
	  _('Comment'), ': ', [:input, {:name=>'msg', :size=>50}], ' ',
	  [:input, {:type=>'submit', :name=>'comment', :value=>_('Submit')}],
	  [:input, {:type=>'hidden', :name=>'comment_no', :value=>num}],
	  [:input, {:type=>'hidden', :name=>'style', :value=>style}]]]
    end

    def ext_hcomment
      #c_require_login	# Guest can post.
      c_require_login	# Guest cannot post.
      c_require_post

      date = @req.start_time.ymdx
      user = @req.query['name']
      user = _('Anonymous') if user.nil? || user.empty?
      msg = @req.query['msg']
      return c_nerror('no message') if msg.nil? || msg.empty?
      content = "- #{date} '''#{user}''' : #{msg}\n"

      comment_no = @req.query['comment_no'].to_i
      comment_no = 1 if comment_no < 1
      style = @req.query['style'].to_i
      style = 0 if style != 1

      page = @site[@req.base]
      str = page.load
      md5 = str.md5hex

      new_str, written = hcomment_add_to_page(str, comment_no, style, content)

      return c_nerror(_('Failed')) if !written

      begin
	page.put_with_md5(new_str, md5)
      rescue PageCollisionError
	return hcomment_error(_('Page collision detected.'))
      end

      c_make_log('hcomment') # COMMENT

      url = @req.base+'.html'
      return c_notice(_('Add a comment.'), url){
	[[:h2, _('Message has been added.')],
	  [:p, [:a, {:href=>url}, _('Go back')]]]
      }
    end

    def hcomment_error(msg, url)
	return c_nerror(msg){
	  [[:h2, msg],
	    [:p, msg],
	    [:p, _('Go back and input again.')],
	    [:dl,
	      [:dt, _('Name')], [:dd, user],
	      [:dt, _('Comment')], [:dd, msg],
	    [:p, [:a, {:href=>url}, _('Go back')]]]]
      }
    end

    def hcomment_add_to_page(str, comment_no, style, content)
      new_str = ''
      num = 1
      written = false
      str.each {|line|
	if /\A\{\{hcomment/ =~ line && !written
	  if num == comment_no
	    new_str << content if style == 0 # new comment is on the bottom.
	    new_str << line
	    new_str << content if style == 1 # new comment is on the top.
	    written = true
	  else
	    new_str << line
	    num += 1
	  end
	else
	  new_str << line
	end
      }
      return new_str, written
    end

    # ============================== Multiline comment
    def plg_nomore_mcomment(style='0', cols='50', rows='4')
      # Just show the content. No more post.
      content = ''
      content = yield if block_given?
      messages = mcomment_construct_messages(content)
      div = [:div, {:class=>'mcomment'}]
      div += messages
      return div
    end

    def plg_mcomment(style='0', cols='50', rows='4')
      # @mcomment_num is global for an action.
      @mcomment_num = 0 if !defined?(@mcomment_num)
      @mcomment_num += 1
      num = @mcomment_num
      style = style.to_i
      style = 0 if style != 1
      action = "#{@req.base}.#{num}.#{style}.mcomment"

      content = ''
      content = yield if block_given?
      messages = mcomment_construct_messages(content)

      div = [:div, {:class=>'mcomment'}]
      div += messages if style == 0

      form = [:form, {:method=>'POST', :action=>action},
	[:p, _('Name'), ': ', [:input, {:name=>'u', :size=>'30'}]],
	[:p, _('Comment'), ': ',
	  [:textarea, {:name=>'m', :cols=>cols, :rows=>rows}, '']],
	[:input, {:type=>'submit', :value=>_('Submit')}]]

      form = [:form, {:method=>'POST', :action=>action},
	[:table,
	  [:tr,
	    [:th, _('Name')],
	    [:td, [:input, {:name=>'u', :size=>'30'}]]],
	  [:tr,
	    [:th, _('Comment')],
	    [:td, [:textarea, {:name=>'m', :cols=>cols, :rows=>rows}, '']]],
	  [:tr,
	    [:th, ''],
	    [:td, [:input, {:type=>'submit', :value=>_('Submit')}]]]]]

      div << form

      div += messages if style == 1
      return div
    end

    def mcomment_construct_messages(content)
      messages = []
      content.each {|line|
	line.chomp!
	dummy, date, user, msg = line.split('|', 4)
	date = Time.at(date.to_i).ymd
	msg ||= ''
	msg.gsub!(/\\n/, "\n")
	mm = []
	msg.each {|m|
	  mm << m
	  mm << [:br]
	}
	messages << [:div, {:class=>'msg'},
	  [:dl, [:dt, [:span, {:class=>'date'}, date],
	      [:span, {:class=>'user'}, user]], [:dd, *mm]]]
      }
      return messages
    end

    def ext_mcomment
      #c_require_login	# Guest can also post comment.
      c_require_login	# Guest cannot post.
      c_require_post
      c_require_page_exist

      date = @req.start_time.to_i

      num = @req.ext_args[0].to_i
      return c_nerror(_('Error')) if num < 1

      style = @req.ext_args[1].to_i
      style = 0 if style != 1

      user = @req.query['u']
      user = _('Anonymous') if user.nil? || user.empty?

      msg = @req.query['m']
      return c_nerror(_('No message.')) if msg.nil? || msg.empty?
      msg = msg.normalize_newline
      msg.gsub!("\n", "\\n")

      comment = "|#{date}|#{user}|#{msg}\n"

      begin
	plugin_edit(:mcomment, num) {|content|
	  if style == 0
	    content += comment
	  else
	    content = comment + content
	  end
	  content
	}
      rescue NoCorrespondingPlugin
	return c_nerror(_('Failed'))
      rescue PageCollisionError
	return mcomment_error(_('Page collision detected.'))
      end

      c_make_log('mcomment')	# COMMENT

      url = "#{@req.base}.html"
      return c_notice(_('Add a comment.'), url){
	[[:h2, _('Message has been added.')],
	  [:p, [:a, {:href=>url}, _('Go back')]]]
      }
    end

    def mcomment_error(msg, url)
	return c_nerror(msg){
	  [[:h2, msg],
	    [:p, msg],
	    [:p, _('Go back and input again.')],
	    [:dl,
	      [:dt, _('Name')], [:dd, user],
	      [:dt, _('Comment')], [:dd, msg],
	    [:p, [:a, {:href=>url}, _('Go back')]]]]
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

    def test_comment
      t_add_user

      page = @site.create_new
      page.store '{{comment}}'

      res = session('/test/1.html')
      ok_xp([:textarea, {:cols=>'40', :rows=>'7', :name=>'msg'}, ''],
	    '//textarea')

      # The 1st comment.
      res = session('/test/1.comment?msg=Hi')
      ok_title('Message has been added.')

      res = session('/test/1.html')
      ok_xp([:dl, [:dt, 'user@e... (1970-01-01 09:00:00)'], [:dd, [:br], 'Hi']],
	    "//div[@class='section']/dl[2]")

      page = @site['_SiteChanged']
      assert_match(/^,[.0-9]+,user@e.com,comment,1$/, page.load)

      # The 2nd comment.
      res = session('/test/1.comment?msg=hello%0aworld')
      ok_title('Message has been added.')

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

    def test_plg_hcomment
      ok_wi([:div, {:class=>'hcomment'},
	      [:form, {:action=>'1.hcomment', :method=>'POST'},
		'Name', ': ', [:input, {:size=>10, :name=>'name'}], ' ',
		'Comment', ': ', [:input, {:size=>50, :name=>'msg'}], ' ',
		[:input, {:value=>'Submit', :type=>'submit', :name=>'comment'}],
		[:input, {:value=>1, :type=>'hidden', :name=>'comment_no'}],
		[:input, {:value=>0, :type=>'hidden', :name=>'style'}]]],
	    '{{hcomment}}')
    end

    def test_ext_hcomment
      t_add_user

      page = @site.create_new
      page.store("{{hcomment}}\n")
      res = session('POST /test/1.hcomment?name=n&msg=m&comment_no=1&style=0')
      ok_eq("- 1970-01-01 09:00:00 '''n''' : m\n{{hcomment}}\n",
	    page.load)

      page.store("{{hcomment(1)}}\n")
      res = session('POST /test/1.hcomment?name=n&msg=m&comment_no=1&style=1')
      ok_eq("{{hcomment(1)}}\n- 1970-01-01 09:00:00 '''n''' : m\n",
	    page.load)
    end

    def test_plg_mcomment
      ok_wi([:div, {:class=>'mcomment'},
	      [:form, {:method=>'POST', :action=>'1.1.0.mcomment'},
		[:table,
		  [:tr, [:th, 'Name'],
		    [:td, [:input, {:size=>'30', :name=>'u'}]]],
		  [:tr,
		    [:th, 'Comment'],
		    [:td, [:textarea,
			{:cols=>'50', :rows=>'4', :name=>'m'}, '']]],
		  [:tr, [:th, ''],
		    [:td, [:input, {:value=>'Submit', :type=>'submit'}]]]]]],
	    "{{mcomment}}")
      ok_wi([:div, {:class=>'mcomment'},
	      [:div, {:class=>'msg'},
		[:dl, [:dt,
		    [:span, {:class=>'date'}, '1970-01-01'],
		    [:span, {:class=>'user'}, 'u']],
		  [:dd, 'm', [:br]]]],
	      [:form, {:method=>'POST', :action=>'1.1.0.mcomment'},
		[:table,
		  [:tr, [:th, 'Name'],
		    [:td, [:input, {:size=>'30', :name=>'u'}]]],
		  [:tr,[:th, 'Comment'],
		    [:td, [:textarea,
			{:cols=>'50', :rows=>'4', :name=>'m'}, '']]],
		  [:tr, [:th, ''],
		    [:td, [:input, {:value=>'Submit', :type=>'submit'}]]]]]],
	    "{{mcomment
|0|u|m
}}")
      ok_wi([:div, {:class=>'mcomment'},
	      [:form, {:method=>'POST', :action=>'1.1.1.mcomment'},
		[:table,
		  [:tr, [:th, 'Name'],
		    [:td, [:input, {:size=>'30', :name=>'u'}]]],
		  [:tr, [:th, 'Comment'],
		    [:td, [:textarea,
			{:cols=>'50', :rows=>'4', :name=>'m'}, '']]],
		  [:tr, [:th, ''],
		    [:td, [:input, {:value=>'Submit', :type=>'submit'}]]]]],
	      [:div, {:class=>'msg'},
		[:dl, [:dt,
		    [:span, {:class=>'date'}, '1970-01-01'],
		    [:span, {:class=>'user'}, 'u']],
		  [:dd, 'm', [:br]]]]],
	    "{{mcomment(1)
|0|u|m
}}")
    end

    def test_ext_mcomment
      t_add_user

      page = @site.create_new
      page.store("{{mcomment}}\n")
      res = session('POST /test/1.html')
      ok_xp([:div, {:class=>'mcomment'},
	      [:form, {:method=>'POST', :action=>'1.1.0.mcomment'},
		[:table,
		  [:tr, [:th, 'Name'],
		    [:td, [:input, {:size=>'30', :name=>'u'}]]],
		  [:tr, [:th, 'Comment'],
		    [:td, [:textarea,
			{:cols=>'50', :rows=>'4', :name=>'m'}, '']]],
		  [:tr, [:th, ''],
		    [:td, [:input, {:value=>'Submit', :type=>'submit'}]]]]]],
	    "//div[@class='mcomment']")

      res = session("POST /test/1.1.0.mcomment?u=u&m=m")
      eq "{{mcomment
|0|u|m
}}
", page.load

      res = session("POST /test/1.1.0.mcomment?u=u2&m=m2")
      eq "{{mcomment
|0|u|m
|0|u2|m2
}}
", page.load

      page.store("{{mcomment(1)}}
")
      res = session("POST /test/1.1.1.mcomment?u=u&m=m")
      eq "{{mcomment(1)
|0|u|m
}}
", page.load

      res = session("POST /test/1.1.1.mcomment?u=u2&m=m2")
      eq "{{mcomment(1)
|0|u2|m2
|0|u|m
}}
", page.load

      page.store("{{mcomment}}
{{mcomment}}
")
      res = session("POST /test/1.1.0.mcomment?u=u&m=m")
      eq "{{mcomment
|0|u|m
}}
{{mcomment}}
", page.load

      res = session("POST /test/1.2.0.mcomment?u=u2&m=m2")
      eq "{{mcomment
|0|u|m
}}
{{mcomment
|0|u2|m2
}}
", page.load
    end

    def test_ext_mcomment2
      t_add_user

      page = @site.create_new
      page.store("{{mcomment}}\n")
      res = session("POST /test/1.1.0.mcomment?u=u&m=m\n")
      eq '{{mcomment
|0|u|m\n
}}
', page.load

      page.store("{{mcomment}}\n")
      res = session("POST /test/1.1.0.mcomment?u=u&m=m\r\n")
      eq '{{mcomment
|0|u|m\n
}}
', page.load

      page.store("{{mcomment}}\n")
      res = session("POST /test/1.1.0.mcomment?u=u&m=m\r")
      eq '{{mcomment
|0|u|m\n
}}
', page.load

      page.store("{{mcomment}}\n")
      res = session("POST /test/1.1.0.mcomment?u=u&m=m\n\r")
      eq '{{mcomment
|0|u|m\n\n
}}
', page.load
    end
  end
end
