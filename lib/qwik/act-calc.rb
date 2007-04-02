# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/wabisabi-table'

module Qwik
  class Action
    D_PluginCalc = {
      :dt => 'Spreadsheet plugin',
      :dd => 'You can caliculate sum by a simple table.',
      :dc => '* Example
 {{calc
 ,$100	,CPU
 ,$100	,Memory
 ,$20.5	,Cable
 ,$250	,Graphic Card
 ,$250	,HDD
 ,$400	,Mother Board
 }}
{{calc
,$100	,CPU
,$100	,Memory
,$20.5	,Cable
,$250	,Graphic Card
,$250	,HDD
,$400	,Mother Board
}}
* Tab Caliculator Plugin
You can use a table splited by tabs.
 {{tab_calc
 6000	Book
 3000	Mouse
 }}
{{tab_calc
6000	Book
3000	Mouse
}}
'
    }

    D_PluginCalc_ja = {
      :dt => '表計算プラグイン',
      :dd => '簡単な表計算を行うことができます。',
      :dc => '* 例
 {{calc
 ,$100	,CPU
 ,$100	,Memory
 ,$20.5	,Cable
 ,$250	,Graphic Card
 ,$250	,HDD
 ,$400	,Mother Board
 }}
{{calc
,$100	,CPU
,$100	,Memory
,$20.5	,Cable
,$250	,Graphic Card
,$250	,HDD
,$400	,Mother Board
}}
* タブ区切り表計算プラグイン
タブ区切りによる表も計算できます。
 {{tab_calc
 6000	書籍
 3000	マウス
 }}
{{tab_calc
6000	書籍
3000	マウス
}}
'
    }

    def plg_tab_calc
      str = yield
      table = Action.tab_to_table(str)
      WabisabiTable.fill_empty_td(table)
      Action.table_calc(table)
      return table
    end

    def self.tab_to_table(str)
      table = [:table]
      str.each {|line|
	ff = line.chomp.split(/\t/)
	next if ff.empty?
	tr = [:tr]
	ff.each {|f|
	  tr << [:td, f]
	}
	table << tr
      }
      return nil if table.length == 1
      return table
    end

    def self.table_calc(table)
      sum = Array.new(0)
      #pp table
      WabisabiTable.each_td(table) {|td, col, row|
	t = td[1]
	prefix, n, suffix = Action.parse_num(t)
	if n
	  #qp col, n
	  sum[col] ||= 0
	  sum[col] += n
	end
      }

      max_col = WabisabiTable.max_col(table)
      
      tr = [:tr, {:class=>'sum'}]
      max_col.times {|n|
	s = sum[n]
	ss = ''
	ss = s.to_s if s
	tr << [:td, ss]
      }

      table << tr

      return table
    end

    def plg_calc
      str = yield

      tokens = TextTokenizer.tokenize(str)

      table = []
      sum = []

      used_prefix = []
      used_suffix = []

      tokens.each {|token|
	case token[0]
	when :table
	  col = []
	  token[1..-1].each_with_index {|t, i|
	    prefix, n, suffix = Action.parse_num(t)
	    col << t
	    if n
	      sum[i] ||= 0
	      if sum[i] != :NaN
		sum[i] += n
	      end

	      if prefix
		if used_prefix[i].nil?
		  used_prefix[i] = prefix
		end
	      end

	      if suffix
		if used_suffix[i].nil?
		  used_suffix[i] = suffix
		end
	      end

	    else
	      sum[i] = :NaN
	    end
	  }
	  table << col
	else
	  return 'you can use only tables in calc plugin'
	end
      }

      if 0 < sum.length
	sum_str = []
	sum.each_with_index {|s, i|
	  if s == :NaN
	    sum_str << ''
	  else
	    sum_str << [used_prefix[i], s.to_s, used_suffix[i]].join
	  end
	}
	tokens << [:table, *sum_str]
      end

      tree = TextParser.make_tree(tokens)

      table = tree[0]
      last_tr = table.last
      last_tr.insert(1, {:class=>'sum'})

      return tree
    end

    CALC_INT_RE   = /\A[0-9,]+\z/
    CALC_FLOAT_RE = /\A[0-9,.]+\z/

    def self.parse_num(str)
      return [nil, 0, nil] if str.empty?
      return [nil, nil, nil] if /\A[^0-9]+\z/ =~ str	# no number

      prefix = suffix = nil

      if /\A([^-0-9]+)[0-9]/ =~ str
	prefix = $1
	str = str.sub($1, '')
      end

      if /[0-9]([^0-9]+)\z/ =~ str
	suffix = $1
	str = str.sub($1, '')
      end

      if /[^-.,0-9]/ =~ str 
	return [nil, nil, nil]
      end

      i = str.to_i
      f = str.to_f
      n = (f-i) == 0 ? i : f
      return [prefix, n, suffix]
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActCalc < Test::Unit::TestCase
    include TestSession

    def test_class_method
      c = Qwik::Action

      # test_tab_to_table
      eq nil, c.tab_to_table("")
      eq [:table, [:tr, [:td, "a"]]], c.tab_to_table("a")
      eq [:table, [:tr, [:td, "a"], [:td, "b"]]], c.tab_to_table("a\tb")
      eq [:table, [:tr, [:td, "a"], [:td, "b"]], [:tr, [:td, "c"]]],
	c.tab_to_table("a\tb\nc")
      eq [:table, [:tr, [:td, "a"], [:td, "b"]], [:tr, [:td, "c"], [:td, "d"]]],
	c.tab_to_table("a\tb\nc\td")

      # test_parse_num
      ok_eq([nil, 0,   nil], c.parse_num(''))
      ok_eq([nil, nil, nil], c.parse_num('a'))
      ok_eq([nil, 1,   nil], c.parse_num('1'))
      ok_eq([nil, 1.5, nil], c.parse_num('1.5'))
      ok_eq([nil, 1,  'MB'], c.parse_num('1MB'))
      ok_eq([nil, 1.5,'MB'], c.parse_num('1.5MB'))
      ok_eq(['$', 1,   nil], c.parse_num('$1'))
      ok_eq(['$', 1.5, nil], c.parse_num('$1.5'))
      eq [nil, nil, nil], c.parse_num('1/2')
    end

    def test_tab_calc
      res = session

      ok_wi [:table, [:tr, [:td, '1']], [:tr, [:td, '2']],
	      [:tr, {:class=>'sum'}, [:td, '3']]],
	    '{{tab_calc
1
2
}}'

      ok_wi [:table,
	[:tr, [:td, "6/7"], [:td, "100"], [:td, "Item A"]],
	[:tr, [:td, "6/8"], [:td, "200"], [:td, "Item B"]],
	[:tr, {:class=>"sum"}, [:td, ""], [:td, "300"], [:td, ""]]],
	    '{{tab_calc
6/7	100	Item A
6/8	200	Item B
}}'
    end

    def test_all
      res = session

      # test plg_calc
      ok_wi([:table, [:tr, [:td, '0']], [:tr, {:class=>'sum'}, [:td, '0']]],
	    '{{calc
,0
}}')
      ok_wi([:table, [:tr, [:td, '1']], [:tr, [:td, '2']],
	      [:tr, {:class=>'sum'}, [:td, '3']]], '{{calc
,1
,2
}}')
      ok_wi([:table,
	      [:tr, [:td, '1'], [:td, '3.4']],
	      [:tr, [:td, '2'], [:td, '5.6']],
	      [:tr, {:class=>'sum'}, [:td, '3'], [:td, '9.0']]],
	    '{{calc
,1,3.4
,2,5.6
}}')
      ok_wi([:table, [:tr, [:td, 'a'], [:td, '0']],
	      [:tr, {:class=>'sum'}, [:td, ''], [:td, '0']]],
	    '{{calc
,a,0
}}')
      ok_wi([:table, [:tr, [:td, '1MB']], [:tr, {:class=>'sum'}, [:td, '1MB']]],
	    '{{calc
,1MB
}}')
      ok_wi([:table, [:tr, [:td, '$1']], [:tr, {:class=>'sum'}, [:td, '$1']]],
	    '{{calc
,$1
}}')
      ok_wi([:table, [:tr, [:td, '$1']], [:tr, {:class=>'sum'}, [:td, '$1']]],
	    '{{calc
,$1,
}}' )
      ok_wi([:table,
	      [:tr, [:td, "$100\t"], [:td, 'CPU']],
	      [:tr, [:td, "$100\t"], [:td, 'Memory']],
	      [:tr, [:td, "$20.5\t"], [:td, 'Cable']],
	      [:tr, [:td, "$250\t"], [:td, 'Graphic Card']],
	      [:tr, [:td, "$250\t"], [:td, 'HDD']],
	      [:tr, [:td, "$400\t"], [:td, 'Mother Board']],
	      [:tr, {:class=>'sum'}, [:td, "$1120.5\t"], [:td, '']]],
	    '{{calc
,$100	,CPU
,$100	,Memory
,$20.5	,Cable
,$250	,Graphic Card
,$250	,HDD
,$400	,Mother Board
}}')
      ok_wi([:table,
	      [:tr, [:td, '1万'], [:td, "\tCPU"]],
	      [:tr, [:td, '1万'], [:td, "\tMemory"]],
	      [:tr, [:td, '0.2万'], [:td, "\tAdapter"]],
	      [:tr, [:td, '2.5万'], [:td, "\tnVidia"]],
	      [:tr, [:td, '2.5万'], [:td, "\tHDD 250GB"]],
	      [:tr, [:td, '4万'], [:td, "\tNAS"]],
	      [:tr, [:td, '22万'], [:td, "\tThinkPad X40"]],
	      [:tr, {:class=>'sum'}, [:td, '33.2万'], [:td, '']]],
	 '{{calc
,1万,	CPU
,1万,	Memory
,0.2万,	Adapter
,2.5万,	nVidia
,2.5万,	HDD 250GB
,4万,	NAS
,22万,	ThinkPad X40
}}')
      ok_wi([:table,
	      [:tr, [:td, "a\t"], [:td, '10,000']],
	      [:tr, [:td, "b\t"], [:td, '20,000']],
	      [:tr, {:class=>'sum'}, [:td, ''], [:td, '30']]],
	    '{{calc
|a	|10,000
|b	|20,000
}}')
      # Don't work.
      ok_wi([:table,
	      [:tr, [:td, "物品\t"], [:td, '値段']],
	      [:tr, [:td, "a\t"], [:td, "\\10,000"]],
	      [:tr, [:td, "b\t"], [:td, "\\20,000"]],
	      [:tr, {:class=>'sum'}, [:td, ''], [:td, '']]],
	    '{{calc
|物品	|値段
|a	|\\10,000
|b	|\\20,000
}}')
    end
  end
end
