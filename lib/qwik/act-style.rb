# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/util-css'
require 'qwik/act-code'

module Qwik
  class Action
    D_PluginStyle = {
      :dt => 'Style plugin',
      :dd => 'You can specify styles of the page.',
      :dc => '* Examples
** Embed CSS
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

You can embed any CSS style except some inhibit pattern by this plugin.
This code specifies the background color of this page.

*** CSS Inhibit Patterns List
{{css_inhibit_pattern}}

** Specify style to a div block
 {{style_div("font-size:200%;")
 This is a test.
 }}
{{style_div("font-size:200%;")
This is a test.
}}

** Specify class for a div block
{{block_div("notice")
This is a test.
}}
 {{block_div("notice")
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
 This is a {{style_span("font-size:200%;", "very big")}} test string.
This is a {{style_span("font-size:200%;", "very big")}} test string.

** Small
 This is a {{small("small")}} string.
This is a {{small("small")}} string.

** Insert an image
 {{img(".theme/i/login_qwik_logo.gif")}}
{{img(".theme/i/login_qwik_logo.gif")}}
You can specify a link.
 {{img(".theme/i/login_qwik_logo.gif", "qwikWeb", "http://qwik.jp/")}}
{{img(".theme/i/login_qwik_logo.gif", "qwikWeb", "http://qwik.jp/")}}

** Make a link to a pge
 {{a(FrontPage)}}
{{a(FrontPage)}}
 {{a(FrontPage, go back)}}
{{a(FrontPage, go back)}}

** Ascii Art plugin
You can include ascii art.
This plugin specifies style sheet for ascii art.

{{{
{{aa
　　 ∧＿∧　　／￣￣￣￣￣
　　（　´∀｀）＜　monar
　　（　　　　） 　＼＿＿＿＿＿
　　｜ ｜　|
　　（_＿）＿）
}}
}}}
{{aa
　　 ∧＿∧　　／￣￣￣￣￣
　　（　´∀｀）＜　monar
　　（　　　　） 　＼＿＿＿＿＿
　　｜ ｜　|
　　（_＿）＿）
}}

{{aa
　　　〇＿〇 
　　 （　・(ｪ)・） 　＜Kumar!
　　/J　▽J 
　　し―-J 
}}

The style sheet simply set "MS P Gothic" font and the line height.

** Code plugin
You can show codes by this plugin.
 {{code
 puts "hello, world!"
 puts "hello, qwik users!"
 }}
{{code
puts "hello, world!"
puts "hello, qwik users!"
}}
You can see line number in the left of each line.

** Notice plugin
You can show a notice by this plugin.
{{notice
\'\'\'WARNING\'\'\': This is just a sample!
}}
 {{notice
 \'\'\'WARNING\'\'\': This is just a sample!
 }}

* Monta method plugin
You can hide a part of text.  Click black box and you\'ll see the text.
 {{monta("This is an example.")}}
{{monta("This is an example.")}}
'
    }

    D_PluginStyle_ja = {
      :dt => 'スタイルプラグイン',
      :dd => '文字や段落の表示スタイルを選べます。',
      :dc => '* 例
** CSS埋め込み
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

禁止パターン以外の任意のCSSを埋込めます。
ここではページの背景を緑色に設定してます。

*** 禁止パターン一覧
{{css_inhibit_pattern}}

** 段落へのスタイル指定
 {{style_div("font-size:200%;")
 This is a test.
 }}
{{style_div("font-size:200%;")
This is a test.
}}

** 段落へのクラス指定
{{block_div("notice")
This is a test.
}}
 {{block_div("notice")
 This is a test.
 }}
任意のクラスを指定できます。

** 中心寄せ
 {{center
 This is a test.~
 This is a test too.
 }}
{{center
This is a test.~
This is a test too.
}}

** 右寄せ
 {{right
 This is a test.~
 This is a test too.
 }}
{{right
This is a test.~
This is a test too.
}}

** 左寄せ
 {{left
 This is a test.~
 This is a test too.
 }}
{{left
This is a test.~
This is a test too.
}}

左寄せはあまり使われないと思いますが、
プラグインの対称性から残しています。

** 左に回りこみ
{{float_left
This is a test.
}}
This is a dummy text.~
This is a dummy text.~
This is a dummy text.~
 {{float_left
 This is a test.
 }}

** 右に回りこみ
{{float_right
This is a test.
}}
This is a dummy text.~
This is a dummy text.~
This is a dummy text.~
 {{float_right
 This is a test.
 }}

** テキストの一部にスタイル指定
 This is a {{style_span("font-size:200%;", "very big")}} test string.
This is a {{style_span("font-size:200%;", "very big")}} test string.

** テキストを小さく
 This is a {{small("small")}} string.
This is a {{small("small")}} string.

** 画像埋込み
 {{img(".theme/i/login_qwik_logo.gif")}}
{{img(".theme/i/login_qwik_logo.gif")}}
リンクをはることもできます。
 {{img(".theme/i/login_qwik_logo.gif", "qwikWeb", "http://qwik.jp/")}}
{{img(".theme/i/login_qwik_logo.gif", "qwikWeb", "http://qwik.jp/")}}

** ページへのリンク
 {{a(FrontPage)}}
{{a(FrontPage)}}
 {{a(FrontPage, go back)}}
{{a(FrontPage, go back)}}

** アスキー・アート・プラグイン
アスキー・アートを書くときにご利用下さい。
{{{
{{aa
　　 ∧＿∧　　／￣￣￣￣￣
　　（　´∀｀）＜　monar
　　（　　　　） 　＼＿＿＿＿＿
　　｜ ｜　|
　　（_＿）＿）
}}
}}}
{{aa
　　 ∧＿∧　　／￣￣￣￣￣
　　（　´∀｀）＜　monar
　　（　　　　） 　＼＿＿＿＿＿
　　｜ ｜　|
　　（_＿）＿）
}}

{{aa
　　　〇＿〇 
　　 （　・(ｪ)・） 　＜Kumar!
　　/J　▽J 
　　し―-J 
}}

単にフォントを「MS Pゴシック」に指定しているだけです。

** コード・プラグイン
コードを埋込むときに使います。
 {{code
 puts "hello, world!"
 puts "hello, qwik users!"
 }}
{{code
puts "hello, world!"
puts "hello, qwik users!"
}}
行番号が埋込まれます。

** 注意事項表示プラグイン
注意事項を表示するのに使えます。
{{notice
\'\'\'WARNING\'\'\': This is just a sample!
}}
 {{notice
 \'\'\'WARNING\'\'\': This is just a sample!
 }}

* モンタ・メソッド・プラグイン
テキストの一部を隠します。クリックすると表示されます。
 {{monta("This is an example.")}}
{{monta("This is an example.")}}
'
    }

    def plg_a(page, text=page)
      return [:a, {:href=>"#{page}.html"}, text]
    end

    def plg_img(f, alt=f, link=nil)
      img = [:img, {:src=>f, :alt=>alt}]
      img = [:a, {:href=>link}, img] if link
      return img
    end

    def plg_css_inhibit_pattern
      return plg_code { CSS::INHIBIT_PATTERN.join("\n") }
    end

    def plg_style_div(style='', a='', &b)
      return unless CSS.valid?(style)
      b = ''
      b = yield if block_given?
      msg = a.to_s + b.to_s
      x = c_res(msg)
      x << '' if x.empty?
      return [:div, {:style=>style}, *x]
    end

    def plg_block_div(div_class='', a='', &b)
      return unless CSS.valid?(div_class)
      b = ''
      b = yield if block_given?
      msg = a.to_s + b.to_s
      x = c_res(msg)
      x << '' if x.empty?
      return [:div, {:class=>div_class}, *x]
    end
    
    def plg_float_left(a='', &b)
      return plg_style_div('float:left;', &b)
    end

    def plg_float_right(a='', &b)
      return plg_style_div('float:right;', &b)
    end

    def plg_left(a='', &b)
      return plg_style_div('text-align:left;', &b)
    end

    def plg_center(a='', &b)
      return plg_style_div('text-align:center;', &b)
    end

    def plg_right(a='', &b)
      return plg_style_div('text-align:right;', &b)
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
      return plg_style_span('font-size:smaller;', a, &b)
    end

    def plg_css
      str = yield
      return 'error' unless CSS.valid?(str)
      return [:style, str]
    end
    alias plg_style plg_css

    # ============================== monta
    MONTA_STYLE = 'background-color:black;text:black;'
    MONTA_SCRIPT = "this.style.backgroundColor='transparent';this.style.text='inherited';return true;"
    def plg_monta(*a)
      element = :span
      txt = a.shift
      if block_given?
	element = :div
	txt = yield
      end

      return if txt.nil?

      return [element, {:style=>MONTA_STYLE, :onmouseup=>MONTA_SCRIPT}, txt]
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActStyle < Test::Unit::TestCase
    include TestSession

    def test_all
      # test_a
      ok_wi [:a, {:href=>"b.html"}, "b"], '{{a(b)}}'
      ok_wi [:a, {:href=>"b.html"}, "c"], '{{a(b, c)}}'

      # test_img
      ok_wi([:img, {:alt=>"t", :src=>"t"}], '{{img(t)}}')
      ok_wi([:img, {:alt=>"m", :src=>"t"}], '{{img(t, m)}}')
      ok_wi([:a, {:href=>"http://e.com/"}, [:img, {:alt=>"m", :src=>"t"}]],
	    "{{img(t, m, http://e.com/)}}")
      ok_wi([:a, {:href=>"http://qwik.jp/"},
	      [:img, {:alt=>"qwikWeb", :src=>".theme/i/login_qwik_logo.gif"}]],
	    "{{img(\".theme/i/login_qwik_logo.gif\", \"qwikWeb\", \"http://qwik.jp/\")}}")

      # test_inhibit_pattern
      ok_wi(/javascript/, "{{css_inhibit_pattern}}")

      # test_style_div
      ok_wi [:div, {:style=>"text-align:center;"}, [:p, "y"]],
	    "{{style_div(text-align:center;)
y
}}"
      ok_wi [:div, {:style=>"text-align:center;"}, [:p, "<"]],
	    "{{style_div(text-align:center;)
<
}}"
      ok_wi [], "{{style_div(@i)
y
}}"

      # test_float_left
      ok_wi [:div, {:style=>"float:left;"}, [:p, "This is a test."]],
	"{{float_left
This is a test.
}}"

      # test_float_right
      ok_wi [:div, {:style=>"float:right;"}, [:p, "This is a test."]],
	"{{float_right
This is a test.
}}"

      # test_left
      ok_wi [:div, {:style=>"text-align:left;"}, [:p, "a"]],
	"{{left
a
}}"

      # test_center
      ok_wi [:div, {:style=>"text-align:center;"}, [:p, "a"]],
	"{{center
a
}}"
      ok_wi [:div, {:style=>"text-align:center;"}, "test"],
	    "{{center
{{qwik_test}}
}}"
      ok_wi [:div, {:style=>"text-align:center;"},
	[:img, {:alt=>"t", :src=>"t"}]],
	"{{center
{{img(t)}}
}}"

      # test_right
      ok_wi [:div, {:style=>"text-align:right;"}, [:p, "a"]],
	"{{right
a
}}"

      # test_style_span
      ok_wi [:p, "a", [:span, {:style=>"font-size:200%;"}, "b"], "c"],
	'a{{style_span("font-size:200%;", "b")}}c'

      # test_small
      ok_wi [:span, {:style=>"font-size:smaller;"}, ""],
	"{{small
}}"
      ok_wi [:span, {:style=>"font-size:smaller;"}, "a"],
	'{{small(a)}}'
      ok_wi [:span, {:style=>"font-size:smaller;"}, "a"],
	"{{small
a
}}"
      ok_wi [:span, {:style=>"font-size:smaller;"}, "a"],
	"{{small(a)
}}"
      ok_wi [:span, {:style=>"font-size:smaller;"}, "aa"],
	"{{small(a)
a
}}"
      ok_wi [:span, {:style=>"font-size:smaller;"},
	[:img, {:alt=>"t", :src=>"t"}]],
	"{{small
{{img(t)}}
}}"

      # test_css
      ok_wi [:style, "a\n"],
	    "{{css
a
}}"
      ok_wi [:style, "a\n"],
	    "{{style
a
}}"
      ok_wi [:style, "h2 { color: red }\n"],
	    "{{css
h2 { color: red }
}}"
      ok_wi ["error"], "{{css
@import
}}"
      ok_wi ["error"], "{{css
\\important
}}"
      ok_wi ["error"], "{{css
javascript
}}"

      ok_wi [:div, {:class=>"notice"}, [:p, "y"]],
	"{{block_div(notice)
y
}}"

      # test_monta
      ok_wi [], '{{monta}}'
      ok_wi [:span, {:style=>'background-color:black;text:black;',
	  :onmouseup=>"this.style.backgroundColor='transparent';this.style.text='inherited';return true;"},
	't'],
	'{{monta(t)}}'

      ok_wi [:div, {:style=>'background-color:black;text:black;',
	  :onmouseup=>"this.style.backgroundColor='transparent';this.style.text='inherited';return true;"},
	"t
"],
	"{{monta
t
}}"
    end
  end
end
