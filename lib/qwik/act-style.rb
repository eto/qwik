#
# Copyright (C) 2003-2006 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    D_style = {
      :dt => 'Style plugin',
      :dd => 'You can specify styles of the page.',
      :dc => "* Examples
** CSS
 {{css
 body {
  background: #efe;
 }
 }}
{{css
body {
 background: #efe;
}
}}

You see green background of this page.
You can specify any CSS by using this plugin.

You can not use these inhibit patterns in this plugin.

{{code
#{Qwik::CSS::INHIBIT_PATTERN.join('
')}
}}

** Specify style to a div block
 {{style_div(\"font-size:200%;\")
 This is a test.
 }}
{{style_div(\"font-size:200%;\")
This is a test.
}}

** Specify class for a div block
{{block_div(\"notice\")
This is a test.
}}
 {{block_div(\"notice\")
 This is a test.
 }}
You can specify any class here.

** Align center
 {{center
 This is a test.~
 This is a test too.
 }}
{{center
This is a test.~
This is a test too.
}}

** Align right
 {{right
 This is a test.~
 This is a test too.
 }}
{{right
This is a test.~
This is a test too.
}}

** Align left
 {{left
 This is a test.~
 This is a test too.
 }}
{{left
This is a test.~
This is a test too.
}}

Usually, this plugin is not useful.
I made this plugin only for the symmetry of plugins.

** Float left
{{float_left
This is a test.
}}
This is a dummy text.~
This is a dummy text.~
This is a dummy text.~
 {{float_left
 This is a test.
 }}

** Float right
{{float_right
This is a test.
}}
This is a dummy text.~
This is a dummy text.~
This is a dummy text.~
 {{float_right
 This is a test.
 }}

** Style span
 This is a {{style_span(\"font-size:200%;\", \"very big\")}} test string.
This is a {{style_span(\"font-size:200%;\", \"very big\")}} test string.

** Small
 This is a {{small(\"small\")}} string.
This is a {{small(\"small\")}} string.

** Insert an image
 {{img(\".theme/i/login_qwik_logo.gif\")}}
{{img(\".theme/i/login_qwik_logo.gif\")}}

** Make a link to a pge
 {{a(FrontPage)}}
{{a(FrontPage)}}
 {{a(FrontPage, go back)}}
{{a(FrontPage, go back)}}

** Ascii Art plugin
You can include ascii art.
This plugin specify a style sheet for ascii art.

{{{
{{aa
@@ ÈQÈ@@^PPPPP
@@i@LÍMjƒ@monar
@@i@@@@j @_QQQQQ
@@b b@|
@@i_QjQj
}}
}}}
{{aa
@@ ÈQÈ@@^PPPPP
@@i@LÍMjƒ@monar
@@i@@@@j @_QQQQQ
@@b b@|
@@i_QjQj
}}

{{aa
@@@ZQZ 
@@ i@E(ª)Ej @ƒKumar!
@@/J@¤J 
@@‚µ\-J 
}}

The style sheet simply set the font to 'MS P Gothic' and
set the line height to 100%.

** Code plugin
You can show codes by this plugin.
 {{code
 puts \"hello, world!\"
 puts \"hello, qwik users!\"
 }}
{{code
puts \"hello, world!\"
puts \"hello, qwik users!\"
}}
There are small differences between 'pre' and 'code'.
The line height is set to 100% in code plugin.

** Notice plugin
You can show a notice by this plugin.
{{notice
'''WARNING''': This is just a sample!
}}
 {{notice
 '''WARNING''': This is just a sample!
 }}

" }

    def plg_a(page, text=page)
      return [:a, {:href=>page+'.html'}, text]
    end

    def plg_img(f, alt=f)
      return [:img, {:src=>f, :alt=>alt}]
    end

    def plg_style_div(style='', a='', &b)
      return unless CSS.valid?(style)
      b = ''
      b = yield if block_given?
      msg = a.to_s + b.to_s
      x = c_res(msg)
      return [:div, {:style=>style}, x]
    end
    
    def plg_block_div(div_class='',a='', &b)
      return unless CSS.valid?(div_class)
      b = ''
      b = yield if block_given?
      msg = a.to_s + b.to_s
      x = c_res(msg)
      return [:div, {:class=>div_class}, x]
    end
    
    def plg_float_left(a='', &b)
      return plg_style_div("float:left;", &b)
    end

    def plg_float_right(a='', &b)
      return plg_style_div("float:right;", &b)
    end

    def plg_left(a='', &b)
      return plg_style_div("text-align:left;", &b)
    end

    def plg_center(a='', &b)
      return plg_style_div("text-align:center;", &b)
    end

    def plg_right(a='', &b)
      return plg_style_div("text-align:right;", &b)
    end

    def style_strip_p(str)
      return str.delete("\n").sub(/^<p>/, "").sub(%r|</p>$|, "")
   end

    def plg_style_span(style='', a='')
      return unless CSS.valid?(style)

      b = ''
      b = yield if block_given?

      msg = a.to_s + b.to_s
      x = c_res(msg)
      w = x[0]
      war = []
      if w.nil?
	war << '' 
      elsif w.first == :p
	w.shift
	war += w
      else
	war << w
      end
      return [:span, {:style=>style}, *war]
    end

    def plg_small(a='', &b)
      return plg_style_span("font-size:smaller;", a, &b)
    end

    def plg_css
      str = yield
      return 'error' unless CSS.valid?(str)
      return [:style, str]
    end
    alias plg_style plg_css
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActStyle < Test::Unit::TestCase
    include TestSession

    def test_style_span
      ok_wi("<img alt=\"t\" src=\"t\"/>", "{{img(t)}}")
      ok_wi("<img alt=\"m\" src=\"t\"/>", "{{img(t, m)}}")
      ok_wi("<span style=\"font-size:smaller;\">a</span>", "{{small(a)}}")
      ok_wi("<span style=\"font-size:smaller;\">a</span>",
	    "{{small\na\n}}")
      ok_wi("<span style=\"font-size:smaller;\">a</span>",
	    "{{small(a)\n}}")
      ok_wi("<span style=\"font-size:smaller;\">aa</span>",
	    "{{small(a)\na\n}}")
      ok_wi("<span style=\"font-size:smaller;\"></span>", "{{small\n}}")
      ok_wi("<span style=\"font-size:smaller;\"><img alt=\"t\" src=\"t\"/></span>", "{{small\n{{img(t)}}\n}}")
    end

    def test_style_div
      ok_wi("<div style=\"text-align:center;\"></div>", "{{center(a)}}")
      ok_wi("<div style=\"text-align:center;\"></div>", "{{center(a)\n}}")
      ok_wi("<div style=\"text-align:center;\"><p>y</p></div>", "{{center\ny\n}}")
      ok_wi("<div style=\"text-align:center;\"><img alt=\"t\" src=\"t\"/></div>", "{{center\n{{img(t)}}\n}}")
      ok_wi("<div style=\"text-align:right;\"><img alt=\"t\" src=\"t\"/></div>", "{{right\n{{img(t)}}\n}}")
      ok_wi("<div style=\"text-align:center;\"><p>y</p></div>", "{{style_div(text-align:center;)\ny\n}}")
      ok_wi("<div style=\"text-align:center;\"><p>&lt;</p></div>", "{{style_div(text-align:center;)\n<\n}}")
      ok_wi("", "{{style_div(@i)\ny\n}}")
      ok_wi("<br/>", "{{br}}")
    end

    def test_css_plugin
      ok_wi("<style>h2 { color: red }\n)}}\n</style>",
	    "{{css\nh2 { color: red }\n)}}")
      ok_wi('error', "{{css\n@import\n}}")
      ok_wi('error', "{{css\n\\important\n}}")
      ok_wi('error', "{{css\njavascript\n}}")
    end

    def test_style_with_plugin
      ok_wi("<div style=\"text-align:center;\"><p>t</p></div>",
	    "{{center\nt\n}}")
      ok_wi("<div style=\"text-align:center;\">test</div>",
	    "{{center\n{{qwik_test}}\n}}")
    end
  end
end
