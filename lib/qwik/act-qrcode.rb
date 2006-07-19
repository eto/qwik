# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'
require 'qwik/qrcode-view'
require 'qwik/server-memory'
require 'qwik/act-text'

module Qwik
  class Action
    D_PluginQRcode = {
      :dt => 'QR-Code plugin',
      :dd => 'You can input QR-Code to the page.',
      :dc => "* Example
{{qrcode}}
 {{qrcode}}
You see a QR-Code for this site.

{{qrcode(\"http://qwik.jp/\")}}
 {{qrcode(\"http://qwik.jp/\")}}
You can embed a URL to the QR-Code.

{{qrcode
This is a test.
This is a test, too.
}}
 {{qrcode
 This is a test.
 This is a test, too.
 }}
You can also embed multiple lines.
"
    }

    D_PluginQRcode_ja = {
      :dt => 'QR-Codeプラグイン',
      :dd => 'QR-Codeを埋込めます。',
      :dc => "* 例
{{qrcode}}
 {{qrcode}}
このサイトのURLが埋込まれているQRCodeを表示します。

{{qrcode(\"http://qwik.jp/\")}}
 {{qrcode(\"http://qwik.jp/\")}}
ある特定のサイトへのQRCodeを埋込むこともできます。

{{qrcode
This is a test.
This is a test, too.
}}
 {{qrcode
 This is a test.
 This is a test, too.
 }}
このように、文章を埋込むこともできます。
"
    }

    def plg_qrcode(str=nil)
      y = yield if block_given?
      str = y.chomp if y && ! y.empty?

      if str
	str = str.to_s
	n = str.md5hex
      else
	str = @site.site_url
	n = @site.sitename
      end

      f = "qrcode-#{n}.png"
      files = @site.files(@req.base)
      if ! files.exist?(f)
	return nil if @config.test && !(defined?($test_qrcode) && $test_qrcode)

	png = qrcode_generate_png(str)
	return nil if png.nil?		# no data or no GD.

	files.put(f, png)
      end

      ar = [
	[:img, {:src=>"#{@req.base}.files/#{f}", :alt=>str}],
	[:br]
      ] + c_pre_text { str }
      ar = [[:a, {:href=>str}] + ar] if is_valid_url?(str)
      div = [:div, {:class=>'qrcode'}] + ar
      return div
    end

    def qrcode_generate_png(d)
      qrcode = QRCode.new(@config.qrcode_dir)
      return nil if ! qrcode.have_data?
      data = qrcode.make_qrcode(d)

      png = QRCodeView.generate_png(data)
      return nil if ! png.nil?
      return png
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActQRCode < Test::Unit::TestCase
    include TestSession

    def test_qrcode_plugin
      return if $0 != __FILE__		# Only for separated test.

      $test_qrcode = true

      return if ! $have_gd

      qrcode = QRCode.new(@config.qrcode_dir)
      return if ! qrcode.have_data?

      res = session

      # test_plg_qrcode
      ok_wi [:div, {:class=>'qrcode'},
	[:a, {:href=>'http://example.com/test/'},
	  [:img, {:src=>'1.files/qrcode-test.png',
	      :alt=>'http://example.com/test/'}], [:br],
	  [:p, [:a, {:class=>'external',
		:href=>'http://example.com/test/'},
	      'http://example.com/test/']]]],
	'{{qrcode}}'

      files = @site.files('1')

      eq true, files.exist?('qrcode-test.png')
      str = files.path('qrcode-test.png').read
      assert_match /\A\211PNG\r\n/, str

      ok_wi [:div, {:class=>'qrcode'},
	[:img, {:alt=>'0',
	    :src=>'1.files/qrcode-cfcd208495d565ef66e7dff9f98764da.png'}],
	[:br], [:p, '0']],
	'{{qrcode(0)}}'

      eq true, files.exist?('qrcode-cfcd208495d565ef66e7dff9f98764da.png')

      ok_wi [:div, {:class=>'qrcode'},
	[:img, {:alt=>'0',
	    :src=>'1.files/qrcode-cfcd208495d565ef66e7dff9f98764da.png'}],
	[:br], [:p, '0']],
	"{{qrcode\n0\n}}"

      $test_qrcode = nil
    end
  end
end
