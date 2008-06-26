# -*- coding: cp932 -*-
# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    D_christel = {
      :dt => 'Takigawa Christel plugin',
      :dd => 'You can embed Takigawa Christel image.',
      :dc => "
Follow [[PluginChristel.describe]]"
    }

    D_PluginChristel = {
      :dt => 'Takigawa Christel plugin',
      :dd => 'You can embed Takigawa Christel image.',
      :dc => "* Example
{{christel
This is Takigawa Christel plugin.
}}
 {{christel
 This is Takigawa Christel plugin.
 }}

{{christel
You can embed images.
http://qwik.jp/.theme/i/login_qwik_logo.gif
}}
 {{christel
 You can embed images.
 http://qwik.jp/.theme/i/login_qwik_logo.gif
 }}

{{christel(640)
You can see bigger one.
}}
 {{christel(640)
 You can see bigger one.
 }}
"
    }

    D_PluginChristel_ja = {
      :dt => '滝川クリステルプラグイン',
      :dd => '滝川クリステルさんに代りにしゃべってもらいます。',
      :dc => "* Example
{{christel
滝川クリステルプラグインです
}}
 {{christel
 滝川クリステルプラグインです
 }}

{{christel
画像も埋め込めます
http://qwik.jp/.theme/i/login_qwik_logo.gif
}}
 {{christel
 画像も埋め込めます
 http://qwik.jp/.theme/i/login_qwik_logo.gif
 }}

{{christel(640)
大きくしてみました
}}
 {{christel(640)
 大きくしてみました
 }}
"
    }

    def plg_christel(width = 320)
      width = width.to_i.to_s
      content = yield
      message, image_url = content.to_a
      message.chomp!
      image_url.chomp! if image_url
      query_str = {
	:m => message.set_page_charset.to_euc,
	:u => image_url
      }.to_query_string
      url = "http://gedo-style.com/crstl/crstl.php?#{query_str}"
      return [:img, {:src=>url, :width=>width}]
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActChristel < Test::Unit::TestCase
    include TestSession

    def test_all
      ok_wi([:img, {:width=>'320',
		:src=>"http://gedo-style.com/crstl/crstl.php?m=a"}],
	    "{{christel\na\n}}")
      ok_wi([:img, {:width=>'320',
		:src=>"http://gedo-style.com/crstl/crstl.php?m=a&u=b"}],
	    "{{christel\na\nb\n}}")
      ok_wi([:img, {:width=>'640',
		:src=>"http://gedo-style.com/crstl/crstl.php?m=a"}],
	    "{{christel(640)\na\n}}")
    end
  end
end
