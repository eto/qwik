# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

#
# This is a sample plugin for qwikWeb.
# If you'd like to check the details of qwikWeb plugin, please see URL below.
# http://qwik.jp/HowToMakePlugin.html
#

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    D_PluginSample = {
      :dt => 'Sample plugins',
      :dd => 'These are sample plugins.',
      :dc => "* Example
You can show famous \"hello, world!\" string by this plugin.

As you know, this \"hello world\" plugin is an example to describe
how you can create your own plugin.

Please check this URL for detail.
http://qwik.jp/HowToMakePlugin.html

** hello world plugin
 {{hello}}
{{hello}}
 {{hello(\"qwik users\")}}
{{hello(\"qwik users\")}}
You can specify the target in the argument.
** hello world action
 [[.hello]]
[[.hello]]
You can see a page with 'hello world' message.
** Monospace plugin
{{tt(\"This is a test.\")}}
 {{tt(\"This is a test.\")}}
You can make the string as monotype font face.

** Quote plugin
{{quote
This is a text to quote.
}}
 {{quote
 This is a text to quote.
 }}
You can make block quote of the string.
"
    }

    D_PluginSample_ja = {
      :dt => 'サンプル・プラグイン',
      :dd => 'プラグインのサンプルです。',
      :dc => '
qwikWebのプラグインを自分で作ってみる際の参考となるプラグインを提供し
ています。このプラグインを改造して、自由に自分なりのプラグインを作って
みてください。

詳しくは、こちらのURLをごらんください。
http://qwik.jp/HowToMakePlugin.html
* 例
** ハローワールド・プラグイン
{{hello}}
 {{hello}}
有名な「hello, world!」を画面に表示させることができます。
{{hello(\"qwik users\")}}
 {{hello(\"qwik users\")}}
引数をとることもできます。
** ハローワールド・アクション
[[.hello]]
 [[.hello]]
「hello, world!」と表示されます。
** 等幅プラグイン
{{tt(\"This is a test.\")}}
 {{tt(\"This is a test.\")}}
等幅を指定します。
** 引用プラグイン
{{quote
This is a text to quote.
}}
 {{quote
 This is a text to quote.
 }}
引用できます。
'
    }

    def plg_hello(target='world')
      return [:strong, "hello, #{target}!"]
    end

    def plg_bhello
      content = yield
      content = content.map {|line|
	"hello, #{line.chomp}!\n"
      }.join
      return [:pre, content]
    end

    def act_hello
      c_notice('hello, world!') {
	'hi, there.'
      }
    end

    def plg_tt(text)
      return [:tt, text]
    end

    def plg_quote
      text = ''
      text = yield if block_given?
      ar = []
      text.each {|line|
	ar << line
	ar << [:br]
      }
      bq = [:blockquote, [:p, {:style=>'font-size:smaller;'}, *ar]]
      return bq
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActSample < Test::Unit::TestCase
    include TestSession

    def test_plg_hello
      ok_wi([:strong, 'hello, world!'], '{{hello}}')
      ok_wi([:strong, 'hello, qwik!'], '{{hello(qwik)}}')
      ok_wi [:pre, "hello, s!\nhello, t!\n"], '{{bhello
s
t
}}'
    end

    def test_act_hello
      t_add_user
      res = session('/test/.hello')
      ok_title 'hello, world!'
      ok_in(['hi, there.'], '//div[@class="section"]')
    end

    def test_plg_tt
      ok_wi([:tt, 't'], '{{tt(t)}}')
    end

    def test_plg_quote
      ok_wi([:blockquote, [:p, {:style=>'font-size:smaller;'}]],
	    '{{quote}}')
      ok_wi([:blockquote, [:p, {:style=>'font-size:smaller;'}]],
	    "{{quote\n\n}}")
      ok_wi([:blockquote, [:p, {:style=>'font-size:smaller;'}, "t\n", [:br]]],
	    "{{quote\nt\n}}")
      ok_wi([:blockquote, [:p, {:style=>'font-size:smaller;'}, "t\n", [:br]]],
	    "{{quote\n\nt\n}}")
      ok_wi([:blockquote, [:p, {:style=>'font-size:smaller;'},
		"t1\n", [:br],
		"t2\n", [:br]]],
	    "{{quote\nt1\nt2\n}}")
    end
  end
end
