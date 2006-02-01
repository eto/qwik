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
    D_comment = {
      :dt => 'Comment plugin',
      :dd => 'You can show comment field.',
      :dc => "
* Multiline comment plugin
{{mcomment}}
 {{mcomment}}
You can show a multi line comment field.
 {{mcomment(1)}}
If you specify (1) as the argment, the newest comment is placed on the top.
* Hiki like comment plugin
 {{hcomment}}
{{hcomment}}
You can show a comment field almost like Hiki's one.
The usage of this plugin is almost same as Hiki comment plugin.
* Old comment plugin
 {{comment}}
{{comment}}
This plugin is obsolete.  Please use 'mcomment' plugin instead.
" }

    # http://colinux:9190/HelloQwik/ActMComment.html
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

    def ext_mcomment
      #c_require_login	# Guest can also post comment.
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
      return c_nerror(_('No message')) if msg.nil? || msg.empty?
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
	[[:h2, _('Message is added.')],
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
  class TestActMcomment < Test::Unit::TestCase
    include TestSession

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
      ok_eq("{{mcomment
|0|u|m
}}
", page.load)

      res = session("POST /test/1.1.0.mcomment?u=u2&m=m2")
      ok_eq("{{mcomment
|0|u|m
|0|u2|m2
}}
", page.load)

      page.store("{{mcomment(1)}}
")
      res = session("POST /test/1.1.1.mcomment?u=u&m=m")
      ok_eq("{{mcomment(1)
|0|u|m
}}
", page.load)

      res = session("POST /test/1.1.1.mcomment?u=u2&m=m2")
      ok_eq("{{mcomment(1)
|0|u2|m2
|0|u|m
}}
", page.load)

      page.store("{{mcomment}}
{{mcomment}}
")
      res = session("POST /test/1.1.0.mcomment?u=u&m=m")
      ok_eq("{{mcomment
|0|u|m
}}
{{mcomment}}
", page.load)

      res = session("POST /test/1.2.0.mcomment?u=u2&m=m2")
      ok_eq("{{mcomment
|0|u|m
}}
{{mcomment
|0|u2|m2
}}
", page.load)
    end

    def test_ext_mcomment2
      t_add_user

      page = @site.create_new
      page.store("{{mcomment}}\n")
      res = session("POST /test/1.1.0.mcomment?u=u&m=m\n")
      ok_eq('{{mcomment
|0|u|m\n
}}
', page.load)

      page.store("{{mcomment}}\n")
      res = session("POST /test/1.1.0.mcomment?u=u&m=m\r\n")
      ok_eq('{{mcomment
|0|u|m\n
}}
', page.load)

      page.store("{{mcomment}}\n")
      res = session("POST /test/1.1.0.mcomment?u=u&m=m\r")
      ok_eq('{{mcomment
|0|u|m\n
}}
', page.load)

      page.store("{{mcomment}}\n")
      res = session("POST /test/1.1.0.mcomment?u=u&m=m\n\r")
      ok_eq('{{mcomment
|0|u|m\n\n
}}
', page.load)
    end
  end
end
