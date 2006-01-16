#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '../../lib' unless $LOAD_PATH.include?('../../lib')
require 'qwik/qrcode-view'
require 'qwik/server-memory'
require 'qwik/act-text'

module Qwik
  class Action
    D_qrcode = {
      :dt => 'QR-Code plugin',
      :dd => 'You can input QR-Code to the page.',
      :dc => "* Example
{{qrcode(\"http://qwik.jp/\")}}
 {{qrcode(\"http://qwik.jp/\")}}
" }

    def plg_qrcode(str=nil)
      y = yield if block_given?
      str = y.chomp if y && y != ''

      if str
	str = str.to_s
	n = str.md5hex
      else
	str = @site.site_url
	n = @site.sitename
      end

      f = "qrcode-#{n}.png"
      files = @site.files('FrontPage')
      if ! files.exist?(f)
	return nil if @config.test && !(defined?($test_qrcode) && $test_qrcode)

	q = @memory.qrcode

	begin
	  png = q.generate_png(str)
	  return nil if png.nil?
	rescue
	  return nil	# no GD library
	end

	files = @site.files('FrontPage')
	files.put(f, png)
      end

      ar = [
	[:img, {:src=>".files/#{f}", :alt=>str}],
	[:br]
      ] + c_pre_text { str }
      ar = [[:a, {:href=>str}] + ar] if is_valid_url?(str)
      div = [:div, {:class=>'qrcode'}] + ar
      return div
    end
  end

  class QRCodeMemory
    def initialize(config, memory)
      @config = config
      @memory = memory
      path = @config.qrcode_dir
      @qrcode = ::QRCode.new(path)
      @qrcodeimage = ::QRCodeView.new(path)
    end

    def have_qrcode_data
      @qrcodeimage.have_qrcode_data
    end

    def generate_data(d)
      return nil if ! @qrcodeimage.have_qrcode_data
      begin
	return @qrcode.make_qrcode(d)
      rescue
	qp $!
	qp $!.backtrace
	return ''
      end
    end

    def generate_png(d)
      return nil if ! @qrcodeimage.have_qrcode_data
      @qrcodeimage.generate_png_from_data(generate_data(d))
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
      $test_qrcode = true

      return if ! $have_gd

      return if ! @memory.qrcode.have_qrcode_data

      res = session

      # test_plg_qrcode
      ok_wi([:div, {:class=>'qrcode'},
	      [:a, {:href=>'http://example.com/test/'},
		[:img, {:src=>'.files/qrcode-test.png',
		    :alt=>'http://example.com/test/'}], [:br],
		[:p, [:a, {:class=>'external',
		      :href=>'http://example.com/test/'},
		    'http://example.com/test/']]]],
	    '{{qrcode}}')

      files = @site.files('FrontPage')

      ok_eq(true, files.exist?('qrcode-test.png'))
      str = files.path('qrcode-test.png').read
      assert_match(/\A\211PNG\r\n/, str)

      ok_wi([:div, {:class=>'qrcode'},
	      [:img, {:alt=>'0',
		  :src=>'.files/qrcode-cfcd208495d565ef66e7dff9f98764da.png'}],
		[:br], [:p, '0']],
	    '{{qrcode(0)}}')

      ok_eq(true, files.exist?('qrcode-cfcd208495d565ef66e7dff9f98764da.png'))

      ok_wi([:div, {:class=>'qrcode'},
	      [:img, {:alt=>'0',
		  :src=>'.files/qrcode-cfcd208495d565ef66e7dff9f98764da.png'}],
		[:br], [:p, '0']],
	    "{{qrcode\n0\n}}")

      $test_qrcode = nil
    end
  end
end
