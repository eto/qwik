# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/act-edit'
require 'qwik/wabisabi-table'

module Qwik
  class Action
    D_PluginTable = {
      :dt => 'Table edit plugin',
      :dd => 'You can edit a table in the page.',
      :dc => "* Example
{{table}}
 {{table}}
You see a five by five table here.
You can edit the table in the page.

This is just a description page.
You should try this plugin on your own page.
"
    }

    D_PluginTable_ja = {
      :dt => 'テーブル編集プラグイン',
      :dd => 'ページ中でテーブルを編集できます。',
      :dc => "* 例
 {{table}}
{{table}}
ここに5x5のテーブルが見えます。
それぞれの項目は入力フィールドになっており、書き換えられます。
最後に「更新」を押すと、それらの入力が反映されます。

この画面は説明用の画面なので、編集できません。
自分のページで試してみてください。
"
    }

    def plg_table
      content = nil
      content = yield if block_given?

      if content.nil? || content.empty?		# no contents
	content = Action.table_default_content
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

      # @table_num is global for an action.
      @table_num = 0 if !defined?(@table_num)
      @table_num += 1
      num = @table_num

      action = "#{@req.base}.#{num}.table"
      div = [:div, {:class=>'table'},
	[:form, {:method=>'POST', :action=>action},
	  table,
	  [:div, {:class=>'submit'},
	    [:input, {:type=>'submit', :value=>_('Update')}]]]]
      return div
    end

    def self.table_default_content
      content = ''
      content << "||A|B|C|D|E\n"
      (1..5).each {|n|
	content << "|#{n}||||||\n"
      }
      return content
    end

    def ext_table
      num = @req.ext_args[0].to_i
      return c_nerror(_('Error')) if num < 1

      query = @req.query
      new_table_str = table_construct(query)

      begin
	plugin_edit(:table, num) {
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

      c_make_log('table')	# TABLE

      url = "#{@req.base}.html"
      return c_notice(_('Edit done.'), url){
	[[:h2, _('Edit done.')],
	  [:p, [:a, {:href=>url}, _('Go back')]]]
      }
    end

    def table_construct(query)
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
  class TestActTable < Test::Unit::TestCase
    include TestSession

    def test_plg_table
      t_add_user
      ok_wi([:div, {:class=>'error'},
	      [:strong, 'Error', ':'], ' ', 'You can only use a table.'],
	    "{{table
a
}}")
      ok_wi([:div, {:class=>'error'},
	      [:strong, 'Error', ':'], ' ', 'You can only use a table.'],
	    "{{table
|a

|b
}}")
      ok_wi([:div, {:class=>'table'},
	      [:form, {:action=>'1.1.table', :method=>'POST'},
		[:table,
		  [:tr,
		    [:th, [:input, {:size=>'1', :value=>'a', :name=>'t_0_0'}]],
		    [:th, {:class=>'new_col'},
		      [:input, {:size=>'1', :value=>'', :name=>'t_1_0'}]],
		    [:td, {:class=>'new_col_button'},
		      [:a, {:href=>"javascript:show_new_col();"}, ">>"]]],
		  [:tr, {:class=>'new_row'},
		    [:th, [:input, {:size=>'1', :value=>'', :name=>'t_0_1'}]],
		    [:td, {:class=>'new_col'},
		      [:input, {:size=>'1', :value=>'', :name=>'t_1_1'}]]],
		  [:tr, {:class=>'new_row_button_row'},
		    [:td, {:class=>'new_row_button'},
		      [:a, {:href=>"javascript:show_new_row();"}, 'v']]]],
		[:div, {:class=>'submit'},
		  [:input, {:value=>'Update', :type=>'submit'}]]]],
	    "{{table
|a
}}")
      ok_wi([:div, {:class=>'table'},
	      [:form, {:action=>'1.1.table', :method=>'POST'},
		[:table,
		  [:tr,
		    [:th, [:input, {:size=>'1', :value=>'a', :name=>'t_0_0'}]],
		    [:th, [:input, {:size=>'1', :value=>'b', :name=>'t_1_0'}]],
		    [:th, {:class=>'new_col'},
		      [:input, {:size=>'1', :value=>'', :name=>'t_2_0'}]],
		    [:td, {:class=>'new_col_button'},
		      [:a, {:href=>"javascript:show_new_col();"}, ">>"]]],
		  [:tr,
		    [:th, [:input, {:size=>'1', :value=>'c', :name=>'t_0_1'}]],
		    [:td, [:input, {:size=>'1', :value=>'d', :name=>'t_1_1'}]],
		    [:td, {:class=>'new_col'},
		      [:input, {:size=>'1', :value=>'', :name=>'t_2_1'}]]],
		  [:tr, {:class=>'new_row'},
		    [:th, [:input, {:size=>'1', :value=>'', :name=>'t_0_2'}]],
		    [:td, [:input, {:size=>'1', :value=>'', :name=>'t_1_2'}]],
		    [:td, {:class=>'new_col'},
		      [:input, {:size=>'1', :value=>'', :name=>'t_2_2'}]]],
		  [:tr, {:class=>'new_row_button_row'},
		    [:td, {:class=>'new_row_button'},
		      [:a, {:href=>"javascript:show_new_row();"}, 'v']]]],
		[:div, {:class=>'submit'},
		  [:input, {:value=>'Update', :type=>'submit'}]]]],
	    "{{table
|a|b
|c|d
}}")
    end

    def nutest_ext_table
      t_add_user
      page = @site.create_new
      page.store("{{table
|a
}}")

      res = session('/test/1.html')
      expected = [:form, {:action=>'1.1.table', :method=>'POST'},
	[:table,
	  [:tr,
	    [:th, [:input, {:size=>'1', :value=>'a', :name=>'t_0_0'}]],
	    [:th, {:class=>'new_col'},
	      [:input, {:size=>'1', :value=>'', :name=>'t_1_0'}]],
	    [:td, {:class=>'new_col_button'},
	      [:a, {:href=>"javascript:show_new_col();"}, ">>"]]],
	  [:tr, {:class=>'new_row'},
	    [:th, [:input, {:size=>'1', :value=>'', :name=>'t_0_1'}]],
	    [:td, {:class=>'new_col'},
	      [:input, {:size=>'1', :value=>'', :name=>'t_1_1'}]]],
	  [:tr, {:class=>'new_row_button_row'},
	    [:td, {:class=>'new_row_button'},
	      [:a, {:href=>"javascript:show_new_row();"}, 'v']]]],
	[:div, {:class=>'submit'},
	  [:input, {:value=>'Update', :type=>'submit'}]]]
      ok_in(expected, "//div[@class='table']")

      res = session("/test/1.1.table?t_0_0=bb")
      ok_in(['Edit done.'], '//h2')

      res = session('/test/1.html')
      ok_xp([:input, {:size=>'2', :value=>'bb', :name=>'t_0_0'}],
	    "//div[@class='table']/form/input")
    end
  end
end
