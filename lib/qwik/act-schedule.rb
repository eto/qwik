# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/act-edit'
require 'qwik/wabisabi-table'

module Qwik
  class Action
    D_PluginSchedule = {
      :dt => 'Input your scuedule plugin',
      :dd => 'You can input your schedule.',
      :dc => "* Example
 {{schedule}}
{{schedule}}
You can see a 5x5 table here.
You can not edit this table because this is a description page.
"
    }

    def plg_schedule
      content = nil
      content = yield if block_given?

      if content.nil? || content.empty?		# no contents
	now = @req.start_time
	content = Action.schedule_default_content(now)
      end

      w = c_parse(content)
      return p_error(_('You can only use a table.')) if 1 < w.length

      table = w[0]
      if table.nil? || table[0] != :table
	return p_error(_('You can only use a table.'))
      end

      if WabisabiTable.error_check(table)
	return p_error(_('You can only use text.'))
      end

      WabisabiTable.prepare(table)

      # @schedule_num is global for an action.
      @schedule_num = 0 if !defined?(@schedule_num)
      @schedule_num += 1
      num = @schedule_num

      action = "#{@req.base}.#{num}.schedule"
      div = [:div, {:class=>'table'},
	[:form, {:method=>'POST', :action=>action},
	  table,
	  [:div, {:class=>'submit'},
	    [:input, {:type=>'submit', :value=>_('Update')}]]]]
      return div
    end

    def self.schedule_default_content(now)
      content = ''
      date = 'Date'
      content << "|#{date}|A|B|C|D|E\n"
      5.times {|n|
	theday = Time.at(now.to_i + (n+1) * (60*60*24))
	ymd = theday.ymd
	content << "|#{ymd}|||||\n"
      }
      return content
    end

    def ext_schedule
      num = @req.ext_args[0].to_i
      return c_nerror(_('Error')) if num < 1

      query = @req.query
      new_table_str = schedule_construct(query)

      begin
	plugin_edit(:schedule, num) {
	  new_table_str
	}
      rescue NoCorrespondingPlugin
	return c_nerror(_('Failed'))
      rescue PageCollisionError
	url = "#{@req.base}.html"
	editing_content = [:pre, new_table_str]
	message = edit_conflict_message(url, editing_content)
	return mcomment_error(_('Page collision detected.')) {
	  message
	}
      end

      c_make_log('schedule')	# COMMENT

      url = "#{@req.base}.html"
      return c_notice(_('Schedule'), url){
	[[:h2, _('Schedule edit done.')],
	  [:p, [:a, {:href=>url}, _('Go back')]]]
      }
    end

    def schedule_construct(query)
      table = []
      query.each {|k, v|
	prefix, col, row = k.split('_')
	next if prefix != 't' || col.nil? || row.nil?
	col = col.to_i
	row = row.to_i
	table[row] = [] if table[row].nil?
	table[row][col] = v
      }

      # Check last row
      last_tr = table.last
      empty = true
      last_tr.each {|col|
	if col && ! col.empty?
	  empty = false
	end
      }
      if empty
	table[table.length-1] = nil	# Delete the last row.
      end

      str = ''
      table.each_with_index {|row, y|
	next if row.nil?
	row.each_with_index {|col, x|
	  str << "|#{col}"
	}
	str << "\n"
      }

      return str
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActSchedule < Test::Unit::TestCase
    include TestSession

    def test_schedule
      now = Time.at(0)
      content = Qwik::Action.schedule_default_content(now)
      ok_eq('|Date|A|B|C|D|E
|1970-01-02|||||
|1970-01-03|||||
|1970-01-04|||||
|1970-01-05|||||
|1970-01-06|||||
', content)
    end

    def test_plg_schedule
      t_add_user
      ok_wi([:div, {:class=>'error'},
	      [:strong, 'Error', ':'], ' ', 'You can only use a table.'],
	    '{{schedule
a
}}')
      ok_wi([:div, {:class=>'error'},
	      [:strong, 'Error', ':'], ' ', 'You can only use a table.'],
	    '{{schedule
|a

|b
}}')
      ok_wi(
[:div,
 {:class=>'table'},
 [:form,
  {:action=>'1.1.schedule', :method=>'POST'},
  [:table,
   [:tr,
    [:th, [:input, {:size=>'1', :value=>'a', :name=>'t_0_0'}]],
    [:th,
     {:class=>'new_col'},
     [:input, {:size=>'1', :value=>'', :name=>'t_1_0'}]],
    [:td,
     {:class=>'new_col_button'},
     [:a, {:href=>'javascript:show_new_col();'}, '>>']]],
   [:tr,
    {:class=>'new_row'},
    [:th, [:input, {:size=>'1', :value=>'', :name=>'t_0_1'}]],
    [:td,
     {:class=>'new_col'},
     [:input, {:size=>'1', :value=>'', :name=>'t_1_1'}]]],
   [:tr,
    {:class=>'new_row_button_row'},
    [:td,
     {:class=>'new_row_button'},
     [:a, {:href=>'javascript:show_new_row();'}, 'v']]]],
  [:div, {:class=>'submit'}, [:input, {:value=>'Update', :type=>'submit'}]]]],
	    '{{schedule
|a
}}')

      ok_wi(
[:div,
 {:class=>'table'},
 [:form,
  {:action=>'1.1.schedule', :method=>'POST'},
  [:table,
   [:tr,
    [:th, [:input, {:size=>'1', :value=>'a', :name=>'t_0_0'}]],
    [:th, [:input, {:size=>'1', :value=>'b', :name=>'t_1_0'}]],
    [:th,
     {:class=>'new_col'},
     [:input, {:size=>'1', :value=>'', :name=>'t_2_0'}]],
    [:td,
     {:class=>'new_col_button'},
     [:a, {:href=>'javascript:show_new_col();'}, '>>']]],
   [:tr,
    [:th, [:input, {:size=>'1', :value=>'c', :name=>'t_0_1'}]],
    [:td, [:input, {:size=>'1', :value=>'d', :name=>'t_1_1'}]],
    [:td,
     {:class=>'new_col'},
     [:input, {:size=>'1', :value=>'', :name=>'t_2_1'}]]],
   [:tr,
    {:class=>'new_row'},
    [:th, [:input, {:size=>'1', :value=>'', :name=>'t_0_2'}]],
    [:td, [:input, {:size=>'1', :value=>'', :name=>'t_1_2'}]],
    [:td,
     {:class=>'new_col'},
     [:input, {:size=>'1', :value=>'', :name=>'t_2_2'}]]],
   [:tr,
    {:class=>'new_row_button_row'},
    [:td,
     {:class=>'new_row_button'},
     [:a, {:href=>'javascript:show_new_row();'}, 'v']]]],
  [:div, {:class=>'submit'}, [:input, {:value=>'Update', :type=>'submit'}]]]],
	    '{{schedule
|a|b
|c|d
}}')
    end

    def test_ext_schedule
      t_add_user
      page = @site.create_new
      page.store('{{schedule
|a
}}')

      res = session('/test/1.html')
      expected = [:form,
 {:action=>'1.1.schedule', :method=>'POST'},
 [:table,
  [:tr,
   [:th, [:input, {:size=>'1', :value=>'a', :name=>'t_0_0'}]],
   [:th,
    {:class=>'new_col'},
    [:input, {:size=>'1', :value=>'', :name=>'t_1_0'}]],
   [:td,
    {:class=>'new_col_button'},
    [:a, {:href=>'javascript:show_new_col();'}, '>>']]],
  [:tr,
   {:class=>'new_row'},
   [:th, [:input, {:size=>'1', :value=>'', :name=>'t_0_1'}]],
   [:td,
    {:class=>'new_col'},
    [:input, {:size=>'1', :value=>'', :name=>'t_1_1'}]]],
  [:tr,
   {:class=>'new_row_button_row'},
   [:td,
    {:class=>'new_row_button'},
    [:a, {:href=>'javascript:show_new_row();'}, 'v']]]],
 [:div, {:class=>'submit'}, [:input, {:value=>'Update', :type=>'submit'}]]]
      ok_in(expected, "//div[@class='table']")

      res = session('/test/1.1.schedule?t_0_0=bb')
      ok_in(['Schedule edit done.'], '//h2')

      res = session('/test/1.html')
      ok_xp([:input, {:size=>'2', :value=>'bb', :name=>'t_0_0'}],
	    "//div[@class='table']/form/input")

      ok_eq('{{schedule
|bb
}}
', page.load)

    end

    def test_ext_schedule2
      t_add_user
      page = @site.create_new
      page.store('b
{{schedule
|a
}}
c
')
      res = session('/test/1.html')
      ok_in([:input, {:size=>'1', :value=>'a', :name=>'t_0_0'}],
	    "//div[@class='table']/table/tr/th")

      res = session('/test/1.1.schedule?t_0_0=bb')
      ok_in(['Schedule edit done.'], '//h2')

      ok_eq('b
{{schedule
|bb
}}
c
', page.load)
    end

    def test_ext_schedule_dbl
      t_add_user
      page = @site.create_new
      page.store('p1
{{schedule
|a
}}
{{schedule
|b
}}
p2
')
      res = session('/test/1.html')
      ok_in([:input, {:size=>'1', :value=>'a', :name=>'t_0_0'}],
	    "//div[@class='table']/table/tr/th")

      res = session('/test/1.1.schedule?t_0_0=bb')
      ok_in(['Schedule edit done.'], '//h2')

      ok_eq('p1
{{schedule
|bb
}}
{{schedule
|b
}}
p2
', page.load)
    end

    def test_ext_schedule_with_mail
      t_add_user
      page = @site.create_new
      page.store('p1
{{schedule
|a
}}
{{mail
m
}}
p2
')
      res = session('/test/1.html')
      ok_in([:input, {:size=>'1', :value=>'a', :name=>'t_0_0'}],
	    "//div[@class='table']/table/tr/th")

      res = session('/test/1.1.schedule?t_0_0=bb')
      ok_in(['Schedule edit done.'], '//h2')
      ok_eq('p1
{{schedule
|bb
}}
{{mail
m
}}
p2
', page.load)
    end
  end
end
