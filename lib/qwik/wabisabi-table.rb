# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/wabisabi-basic'

module Qwik
  class WabisabiTable
    def self.error_check(table)
      each_td(table) {|td, col, row|
	if 2 < td.length	# Error!
	  return true
	end
      }
      return false	# No error.
    end

    def self.prepare(table)
      fill_empty_td(table)
      add_new_col(table)
      add_new_row(table)
      replace_with_input(table)
      make_th(table)
      set_new_col_and_new_row(table)
      add_new_col_button(table)
      add_new_row_button(table)
      return table
    end

    def self.fill_empty_td(table, max_col=nil)
      max_col = max_col(table) if max_col.nil?
      table.each_child_with_index {|tr, row|
	col_len = tr.children.length
	if col_len < max_col
	  (max_col - col_len).times {
	    tr << [:td, '']
	  }
	end
      }
      return nil
    end

    def self.add_new_col(table)
      each_tr(table) {|tr, row|
	tr << [:td, '']
      }
    end

    def self.max_col(table)
      max_col = 0
      each_tr(table) {|tr, row|
	col_len = tr.children.length
	max_col = col_len if max_col < col_len
      }
      return max_col
    end

    def self.each_tr(table)
      table.each_child_with_index {|tr, row|
	yield(tr, row)
      }
    end

    def self.each_td(table)
      each_tr(table) {|tr, row|
	tr.each_child_with_index {|td, col|
	  yield(td, col, row)
	}
      }
    end

    def self.add_new_row(table, max_col=nil)
      max_col = max_col(table) if max_col.nil?
      tr = [:tr]
      (max_col).times {
	tr << [:td, '']
      }
      table << tr
    end

    def self.replace_with_input(table)
      max_len = Array.new(0)
      each_td(table) {|td, col, row|
	name = "t_#{col}_#{row}"
	text = td[1]
	len = text.length
	len = 1 if len < 1
	max_len[col] ||= 0
	max_len[col] = len if max_len[col] < len
	td[1] = [:input, {:name=>name, :value=>text}]
      }
      each_td(table) {|td, col, row|
	td[1].set_attr(:size=>max_len[col].to_s)
      }
    end

    def self.make_th(table)
      each_td(table) {|td, col, row|
	td[0] = :th if row == 0 || col == 0
      }
    end

    def self.set_new_col_and_new_row(table)
      last_tr = table.last
      last_tr.set_attr(:class=>'new_row')
      each_tr(table) {|tr, row|
	tr.last.set_attr(:class=>'new_col')
      }
    end

    def self.add_new_col_button(table)
      first_tr = table.children.first
      first_tr << [:td, {:class=>'new_col_button'},
	[:a, {:href=>'javascript:show_new_col();'}, '>>']]
    end

    def self.add_new_row_button(table)
      table << [:tr, {:class=>'new_row_button_row'},
	[:td, {:class=>'new_row_button'},
	  [:a, {:href=>'javascript:show_new_row();'}, 'v']]]
    end
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  $test = true
end

if defined?($test) && $test
  module Qwik
    class WabisabiTable
      attr_reader :table	# Only for debug.
    end
  end

  class TestWabisabiTable < Test::Unit::TestCase
    def test_class_method
      table_1x1 = [:table, [:tr, [:td, '']]]
      table_2x2 = [:table,
	[:tr, [:td, ''], [:td, '']],
	[:tr, [:td, ''], [:td, '']]]
      table_with_empty = [:table,
	[:tr, [:td, ''], [:td, '']],
	[:tr, [:td, '']]]

      c = Qwik::WabisabiTable

      # test_max_col
      assert_equal 1, c.max_col(table_1x1)
      assert_equal 2, c.max_col(table_2x2)
      assert_equal 2, c.max_col(table_with_empty)

      # test_fill_empty_td
      c.fill_empty_td(table_with_empty)
      eq([:table, [:tr, [:td, ''], [:td, '']], [:tr, [:td, ''], [:td, '']]],
	 table_with_empty)

      # test_each_tr
      c.each_tr(table_1x1) {|tr, row|
	assert_equal :tr, tr[0]
	assert_instance_of Fixnum, row
      }

      # test_each_td
      c.each_td(table_1x1) {|td, col, row|
	assert_equal :td, td[0]
	assert_instance_of Fixnum, col
	assert_instance_of Fixnum, row
      }
      # test_add_new_col
      c.add_new_col(table_1x1)
      assert_equal [:table, [:tr, [:td, ''], [:td, '']]], table_1x1

      # test_add_new_row
      c.add_new_row(table_1x1)
      assert_equal [:table, [:tr, [:td, ''], [:td, '']],
	[:tr, [:td, ''], [:td, '']]],
	    table_1x1
    end

    def test_for_schedule
      table_1x1 = [:table, [:tr, [:td, '']]]

      c = Qwik::WabisabiTable

      c.prepare(table_1x1)
      assert_equal [:table,
	      [:tr,
		[:th, [:input, {:size=>'1', :value=>'', :name=>'t_0_0'}]],
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
	    table_1x1
    end
  end
end
