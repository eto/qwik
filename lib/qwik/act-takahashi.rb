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
    D_takahashi = {
      :dt => 'Takahashi method plugin',
      :dd => 'You can do your presentaion in Takahashi method.',
      :dc => "* Example
{{takahashi
Takahashi
method
plugin

What is
Takahashi
method?

A way of
presentaion
method.

Thank
you.
}}
"
    }

    Dja_takahashi = {
      :dt => '高橋メソッドプラグイン',
      :dd => '高橋メソッドでプレゼンできます。',
      :dc => '* 例
{{takahashi
高橋メソッド
プラグイン

それって
何?

プレゼン
手法の
一種

どうも
ありがとう
}}
'
    }

    def plg_takahashi
      c_require_page_exist

      files = @site.files(@req.base)

      # Copy T_method_module.swf from theme directory.
      fname = 'T_method_module.swf'
      if ! files.exist?(fname)
	swf_path = @config.theme_dir.path+'swf'+fname
	return nil if ! swf_path.exist?
	swf = swf_path.read
	files.overwrite(fname, swf)
      end

      # Generate a text file.
      content = yield
      content.chomp!
      text = content.set_page_charset.to_utf8
      files.overwrite('textData.txt', text)

      # Generate a html file.
      title = @req.base
      movie = 'T_method_module.swf'
      embed = [:embed,	{
	  :src		=> movie,
	  :flashvars	=> 'text_url=textData.txt',
	  :quality	=> 'high',
	  :name		=> 'T_method_module',
	  :class	=> 'T_method_module',
	  :type		=> 'application/x-shockwave-flash',
	}]

      style = '
* {
  padding: 0;
  margin: 0;
}
body {
  background: #000;
  width:100%;
  height:100%;
}
div {
  position: absolute;
  top: 0;
  right: 0;
  bottom: 0;
  left: 0;
  width: 100%;
  height: 100%;
}
.T_method_module {
  width: 100%;
  height: 100%;
}
'
      html = [
	[:"!DOCTYPE", 'html', 'PUBLIC',
	  '-//W3C//DTD XHTML 1.0 Transitional//EN',
	  'http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd'],
	[:html, {:xmlns=>'http://www.w3.org/1999/xhtml',
	    :'xml:lang'=>'ja', :lang=>'ja'},
	  [:head,
	    [:meta, {:'http-equiv'=>'Content-Type',
		:content=>'text/html; charset=shift_jis'}],
	    [:title, title],
	    [:style, {:type=>'text/css'}, [:'!--', style]]],
	  [:body,
	    [:div,
	      embed]]]
      ]
      html_str = html.format_xml
      files.overwrite('takahashi.html', html_str)

      # Embed the html file as iframe.
      h = "#{@req.base}.files/takahashi.html"
      return [:div, {:class=>'takahashi'},
	[:iframe, {:src=>h, :style=>'width:700px;height:400px;border:0;'}, ''],
	[:br],
	[:div, {:style=>'margin: 0 0 1em 0;'},
	  [:a, {:href=>h, :style=>'font-size:x-small;'},
	    _('Show in fullscreen.')]]]
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActTakahashi < Test::Unit::TestCase
    include TestSession

    def test_all
      t_add_user

      page = @site.create_new
      page.store('{{takahashi
a
}}')

      res = session('/test/1.html')
      ok_xp(
[:div, {:class=>"takahashi"},
 [:iframe, {:src=>"1.files/takahashi.html",
   :style=>"width:700px;height:400px;border:0;"},
  ""],
 [:br],
 [:div, {:style=>"margin: 0 0 1em 0;"},
  [:a, {:href=>"1.files/takahashi.html", :style=>"font-size:x-small;"},
   "Show in fullscreen."]]],
	    "//div[@class='takahashi']")

      files = @site.files('1')
      ok_eq(true, files.exist?('T_method_module.swf'))
      ok_eq(true, files.exist?('textData.txt'))
      ok_eq("a", files.get('textData.txt'))
      ok_eq(true, files.exist?('takahashi.html'))
    end
  end
end
