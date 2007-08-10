# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

module Qwik
  class Action
    D_PluginRuby = {
      :dt => 'Embed Ruby code plugin',
      :dd => 'You can embed ruby code on pages.',
      :dc => "* Examples
 {{ruby
 \"<b>hello</b>\"
 }}
{{ruby
\"<b>hello</b>\"
}}

* enable_ruby

Please enable ruby plugin from 'config.txt'.
Ask for the administrator.
}}
"
    }

    def plg_ruby(*argv)
      return [:p, "Ruby plugin is not enabled."] if ! @config.enable_ruby

      return if ! block_given?
      ruby_code = yield

      require 'date'

      th = Thread.new {
	$SAFE = 4
	eval(ruby_code)
      }
      result = th.value.to_s
      wabisabi = HTree(result).to_wabisabi
      return [:p, wabisabi]
    end
  end
end

if $0 == __FILE__
  $LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActRuby < Test::Unit::TestCase
    include TestSession

    def test_plg_ruby
      res = session
      ok_wi [:p, "Ruby plugin is not enabled."],
	"{{ruby
'hello'
}}"

      @config[:enable_ruby] = true

      ok_wi [], "{{ruby}}"

      ok_wi [:p, ["hello"]],
	"{{ruby
\"hello\"
}}"

      ok_wi [:p, ["2"]],
	"{{ruby
1 + 1
}}"

      ok_wi [:p, ["11"]],
	"{{ruby(1, 1)
argv[0] + argv[1]
}}"

      ok_wi [:p, ["2"]],
	"{{ruby(1, 1)
argv[0].to_i + argv[1].to_i
}}"

      ok_wi [:p,
 [[:pre,
   "\nSun Mon Tue Wed Thu Fri Sat\n              1   2   3   4 \n  5   6   7   8   9  10  11 \n 12  13  14  15  16  17  18 \n 19  20  21  22  23  24  25 \n 26  27  28  29  30  31 \n"],
  "\n"]],
	'{{ruby(2007, 8)
year = argv[0].to_i
month = argv[1].to_i

str = ""
str << "<pre>\n"
str << Date::ABBR_DAYNAMES.join(" ")
str << "\n"

day = Date.new(year, month)

str << ("    " * day.wday)
loop do
  str << day.strftime(" %e ")
  str << "\n" if day.wday == 6
  day += 1
  break if day.month != month
end
str << "\n"
str << "</pre>\n"

str
}}'

    end
  end
end
