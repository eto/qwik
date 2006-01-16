#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '../../lib' unless $LOAD_PATH.include?('../../lib')
require 'qwik/wabisabi-get'

module Qwik
  class WabisabiTable
    def initialize(table)
      @table = table
    end
    attr_reader :table	# For debug.

    def error_check
      each_td {|td, col, row|
	if 2 < td.length
	  return true	# Error!
	end
      }
      return false	# no error.
    end

    def prepare
      fill_empty_td

      add_new_col

      add_new_row

      replace_with_input

      make_th

      set_new_col_and_new_row

      add_new_col_button

      add_new_row_button

      return @table
    end
    #def prepare_for_table_edit
    #alias prepare_for_schedule prepare_for_table_edit

    def replace_with_input
      max_len = Array.new(0)
      each_td {|td, col, row|
	name = "t_#{col}_#{row}"
	text = td[1]
	len = text.length
	len = 1 if len < 1
	max_len[col] ||= 0
	max_len[col] = len if max_len[col] < len
	td[1] = [:input, {:name=>name, :value=>text}]
      }
      each_td {|td, col, row|
	td[1].set_attr(:size=>max_len[col].to_s)
      }
    end

    def make_th
      each_td {|td, col, row|
	if row == 0 || col == 0
	  td[0] = :th
	end
      }
    end

    def set_new_col_and_new_row
      last_tr = @table.last
      last_tr.set_attr(:class=>'new_row')
      each_tr {|tr, row|
	tr.last.set_attr(:class=>'new_col')
      }
    end

    def add_new_col_button
      first_tr = @table.children.first
      first_tr << [:td, {:class=>"new_col_button"},
	[:a, {:href=>"javascript:show_new_col();"}, ">>"]]
    end

    def add_new_row_button
      @table << [:tr, {:class=>"new_row_button_row"},
	[:td, {:class=>'new_row_button'},
	  [:a, {:href=>"javascript:show_new_row();"}, 'v']]]
    end

    def each_tr
      @table.each_child_with_index {|tr, row|
	yield(tr, row)
      }
    end

    def each_td
      each_tr {|tr, row|
	tr.each_child_with_index {|td, col|
	  yield(td, col, row)
	}
      }
    end

    def max_col
      max_col = 0
      each_tr {|tr, row|
	col_len = tr.children.length
	max_col = col_len if max_col < col_len
      }
      return max_col
    end

    def fill_empty_td(max_col=nil)
      max_col = self.max_col if max_col.nil?

      @table.each_child_with_index {|tr, row|
	col_len = tr.children.length
	if col_len < max_col
	  (max_col - col_len).times {
	    tr << [:td, '']
	  }
	end
      }
    end

    def add_new_col
      each_tr {|tr, row|
	tr << [:td, '']
      }
    end

    def add_new_row(max_col=nil)
      max_col = self.max_col if max_col.nil?
      tr = [:tr]
      (max_col).times {
	tr << [:td, '']
      }
      @table << tr
    end
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  $test = true
end

if defined?($test) && $test
  class TestWabisabiTable < Test::Unit::TestCase
    alias ok_eq ok_eq

    def test_table
      table_1x1 = [:table, [:tr, [:td, '']]]
      table_2x2 = [:table,
	[:tr,
	  [:td, ''],
	  [:td, '']],
	[:tr,
	  [:td, ''],
	  [:td, '']]]
      table_with_empty = [:table,
	[:tr,
	  [:td, ''],
	  [:td, '']],
	[:tr,
	  [:td, '']]]


      # test_each_tr
      wt = Qwik::WabisabiTable.new(table_1x1)
      wt.each_tr {|tr, row|
	ok_eq(:tr, tr[0])
	assert_instance_of(Fixnum, row)
      }

      # test_each_td
      wt.each_td {|td, col, row|
	ok_eq(:td, td[0])
	assert_instance_of(Fixnum, col)
	assert_instance_of(Fixnum, row)
      }

      # test_max_col
      ok_eq(1, wt.max_col)

      wt = Qwik::WabisabiTable.new(table_2x2)
      ok_eq(2, wt.max_col)

      wt = Qwik::WabisabiTable.new(table_with_empty)
      ok_eq(2, wt.max_col)

      # test_fill_empty_td
      wt = Qwik::WabisabiTable.new(table_with_empty)
      wt.fill_empty_td
      ok_eq([:table, [:tr, [:td, ''], [:td, '']], [:tr, [:td, ''], [:td, '']]],
	    wt.table)

      # test_add_new_col
      wt = Qwik::WabisabiTable.new(table_1x1)
      wt.add_new_col
      ok_eq([:table, [:tr, [:td, ''], [:td, '']]], wt.table)

      # test_add_new_row
      wt.add_new_row
      ok_eq([:table, [:tr, [:td, ''], [:td, '']], [:tr, [:td, ''], [:td, '']]],
	    wt.table)
    end

    def test_for_schedule
      table_1x1 = [:table, [:tr, [:td, '']]]
      wt = Qwik::WabisabiTable.new(table_1x1)
      #wt.prepare_for_schedule
      wt.prepare
      ok_eq([:table,
	      [:tr,
		[:th, [:input, {:size=>'1', :value=>'', :name=>'t_0_0'}]],
		[:th,
		  {:class=>'new_col'},
		  [:input, {:size=>'1', :value=>'', :name=>'t_1_0'}]],
		[:td,
		  {:class=>'new_col_button'},
		  [:a, {:href=>"javascript:show_new_col();"}, ">>"]]],
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
		  [:a, {:href=>"javascript:show_new_row();"}, 'v']]]],
	    wt.table)
    end
  end
end

