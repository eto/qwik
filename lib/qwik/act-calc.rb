#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '..' unless $LOAD_PATH.include?('..')

module Qwik
  class Action
    D_calc = {
      :dt => 'Calicurator plugin',
      :dd => 'You can sum numbers by simple table.',
      :dc => "* Example
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
"
    }

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
	    prefix, n, suffix = calc_parse_num(t)
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

    def calc_parse_num(str)
      return [nil, 0, nil] if str.empty?
      return [nil, nil, nil] if /\A[^0-9]+\z/ =~ str # no number

      prefix = suffix = nil

      if /\A([^-0-9]+)[0-9]/ =~ str
	prefix = $1
	str = str.sub($1, '')
      end

      if /[0-9]([^0-9]+)\z/ =~ str
	suffix = $1
	str = str.sub($1, '')
      end

      i = str.to_i
      f = str.to_f
      n = (f-i) == 0 ? i : f
      return [prefix, n, suffix]
    end
  end
end

if $0 == __FILE__
  $LOAD_PATH << '../../lib' unless $LOAD_PATH.include?('../../lib')
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActCalc < Test::Unit::TestCase
    include TestSession

    def ok(e, str)
      ok_wi(e, str)
    end

    def test_all
      res = session

      # test calc_parse_num
      ok_eq([nil, 0,   nil], @action.calc_parse_num(''))
      ok_eq([nil, nil, nil], @action.calc_parse_num('a'))
      ok_eq([nil, 1,   nil], @action.calc_parse_num('1'))
      ok_eq([nil, 1.5, nil], @action.calc_parse_num('1.5'))
      ok_eq([nil, 1,  'MB'], @action.calc_parse_num('1MB'))
      ok_eq([nil, 1.5,'MB'], @action.calc_parse_num('1.5MB'))
      ok_eq(["$", 1,   nil], @action.calc_parse_num("$1"))
      ok_eq(["$", 1.5, nil], @action.calc_parse_num("$1.5"))

      # test plg_calc
      ok_wi([:table, [:tr, [:td, '0']], [:tr, {:class=>'sum'}, [:td, '0']]],
	    "{{calc\n,0\n}}")
      ok_wi([:table, [:tr, [:td, '1']], [:tr, [:td, '2']],
	      [:tr, {:class=>'sum'}, [:td, '3']]], "{{calc\n,1\n,2\n}}")
      ok_wi([:table,
	      [:tr, [:td, '1'], [:td, '3.4']],
	      [:tr, [:td, '2'], [:td, '5.6']],
	      [:tr, {:class=>'sum'}, [:td, '3'], [:td, '9.0']]],
	    "{{calc\n,1,3.4\n,2,5.6\n}}")
      ok_wi([:table, [:tr, [:td, 'a'], [:td, '0']],
	      [:tr, {:class=>'sum'}, [:td, ''], [:td, '0']]],
	    "{{calc\n,a,0\n}}")
      ok_wi([:table, [:tr, [:td, '1MB']], [:tr, {:class=>'sum'}, [:td, '1MB']]],
	    "{{calc\n,1MB\n}}")
      ok_wi([:table, [:tr, [:td, "$1"]], [:tr, {:class=>'sum'}, [:td, "$1"]]],
	    "{{calc\n,$1\n}}")
      ok_wi([:table, [:tr, [:td, "$1"]], [:tr, {:class=>'sum'}, [:td, "$1"]]],
	    "{{calc\n,$1,\n}}")
      ok_wi([:table,
	      [:tr, [:td, "$100"], [:td, 'CPU']],
	      [:tr, [:td, "$100"], [:td, 'Memory']],
	      [:tr, [:td, "$20.5"], [:td, 'Cable']],
	      [:tr, [:td, "$250"], [:td, 'Graphic Card']],
	      [:tr, [:td, "$250"], [:td, 'HDD']],
	      [:tr, [:td, "$400"], [:td, 'Mother Board']],
	      [:tr, {:class=>'sum'}, [:td, "$1120.5"], [:td, '']]],
	    "{{calc
,$100	,CPU
,$100	,Memory
,$20.5	,Cable
,$250	,Graphic Card
,$250	,HDD
,$400	,Mother Board
}}")
      ok_wi([:table,
	      [:tr, [:td, "1万"], [:td, 'CPU']],
	      [:tr, [:td, "1万"], [:td, 'Memory']],
	      [:tr, [:td, "0.2万"], [:td, 'Adapter']],
	      [:tr, [:td, "2.5万"], [:td, 'nVidia']],
	      [:tr, [:td, "2.5万"], [:td, 'HDD 250GB']],
	      [:tr, [:td, "4万"], [:td, 'NAS']],
	      [:tr, [:td, "22万"], [:td, 'ThinkPad X40']],
	      [:tr, {:class=>'sum'}, [:td, "33.2万"], [:td, '']]],
	 "{{calc
,1万,	CPU
,1万,	Memory
,0.2万,	Adapter
,2.5万,	nVidia
,2.5万,	HDD 250GB
,4万,	NAS
,22万,	ThinkPad X40
}}")

=begin
      ok_wi([:table,
 [:tr, [:td, "物品"], [:td, "値段"]],
 [:tr, [:td, 'a'], [:td, "\\10,000"]],
 [:tr, [:td, 'b'], [:td, "\\20,000"]],
 [:tr, {:class=>'sum'}, [:td, ''], [:td, '']]],
"{{calc
|a	|10,000
|b	|20,000
}}")

      ok_wi([:table,
 [:tr, [:td, "物品"], [:td, "値段"]],
 [:tr, [:td, 'a'], [:td, "\\10,000"]],
 [:tr, [:td, 'b'], [:td, "\\20,000"]],
 [:tr, {:class=>'sum'}, [:td, ''], [:td, '']]],
"{{calc
|物品	|値段
|a	|\\10,000
|b	|\\20,000
}}")
=end

    end
  end
end
