#
# Copyright (C) 2003-2006 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'
require 'qwik/qrcode'

begin
  require 'GD'
  $have_gd = true
rescue LoadError
  $have_gd = false
end

class QRCodeView
  # Generate QRCode html string.
  def self.generate_html(d)
    ar = []
    ar[?0] = '<td/>'
    ar[?1] = '<th/>'
    html = ['<table class="qrcode">',
      d.map {|line|
	tr = '<tr>'
	line.chomp.each_byte {|b|
	  tr << ar[b]
	}
	tr << '</tr>'
	tr
      }.join,
      '</table>'].join
    return html
  end

  # Generate QRCode wabisabi html data.
  def self.generate_wabisabi(d)
    ar = []
    ar[?0] = [:td]
    ar[?1] = [:th]
    table = d.map {|line|
      tr = []
      line.chomp.each_byte {|b|
	tr << ar[b]
      }
      [:tr, *tr]
    }
    return [:table, {:class=>'qrcode'}, *table]
  end

  # Generate QRCode PNG image by using GD.
  def self.generate_png(data)
    image = make_image(data)
    return nil if image.nil?
    return image.pngStr
  end

  private

  def self.make_image(data, m=2, q=4)
    return if ! $have_gd

    raise unless 0 < m && m < 9
    raise unless 0 < q && q < 9

    module_size = m
    quiet_zone  = q

    data_array = data.split("\n")
    image_size = data_array.size

    output_size = (image_size + quiet_zone * 2) * module_size

    img = GD::Image.new(image_size, image_size)		# original image

    white = img.colorAllocate(255, 255, 255)
    black = img.colorAllocate(0, 0, 0)

    im = GD::Image.new(output_size, output_size)	# canvas with quiet zone

    white2 = im.colorAllocate(255, 255, 255)
    im.fill(0, 0, white2)

    data_array.each_with_index {|row, y|
      (0..image_size).each {|x|
	img.setPixel(x, y, black) if row[x, 1] == '1'
      }
    }

    quiet_zone_offset = quiet_zone * module_size
    image_width = image_size * module_size
    img.copyResized(im, quiet_zone_offset, quiet_zone_offset, 0, 0,
		    image_width, image_width, image_size, image_size)
    return im
  end
end

if $0 == __FILE__
  require 'test/unit'
  require 'qwik/util-charset'
  require 'qwik/config'
  require 'qwik/wabisabi-format-xml'
  $test = true
end

if defined?($test) && $test
  class TestQRCodeView < Test::Unit::TestCase
    def test_class_method
      c = QRCodeView

      # test_generate_html
      assert_equal "<table class=\"qrcode\"><tr><td/><th/></tr></table>",
	c.generate_html('01')

      # test_generate_wabisabi
      assert_equal [:table, {:class=>"qrcode"}, [:tr, [:td], [:th]]],
	c.generate_wabisabi('01')
      assert_equal "<table class=\"qrcode\"><tr><td/><th/></tr></table>",
	c.generate_wabisabi('01').rb_format_xml(-1, -1)

      return if ! $have_gd
      # test_generate_png
      assert_equal "\211PNG\r\n\032\n\000\000\000\rIHDR\000\000\000\022\000\000\000\022\001\003\000\000\000l\000\034\024\000\000\000\003PLTE\377\377\377\247\304\e\310\000\000\000\fIDAT\010\231c`\240\016\000\000\000H\000\001{\245\021\310\000\000\000\000IEND\256B`\202", c.generate_png('0')
      assert_equal "\211PNG\r\n\032\n\000\000\000\rIHDR\000\000\000\022\000\000\000\022\001\003\000\000\000l\000\034\024\000\000\000\006PLTE\377\377\377\000\000\000U\302\323~\000\000\000\020IDAT\010\231c` \004\016@1~\000\0006H\001\201N\024'\263\000\000\000\000IEND\256B`\202", c.generate_png('1')
      assert_equal "\211PNG\r\n\032\n\000\000\000\rIHDR\000\000\000\022\000\000\000\022\001\003\000\000\000l\000\034\024\000\000\000\003PLTE\377\377\377\247\304\e\310\000\000\000\fIDAT\010\231c`\240\016\000\000\000H\000\001{\245\021\310\000\000\000\000IEND\256B`\202", c.generate_png('01')
      assert_equal "\211PNG\r\n\032\n\000\000\000\rIHDR\000\000\000\003\000\000\000\003\001\003\000\000\000l\346'\374\000\000\000\006PLTE\377\377\377\000\000\000U\302\323~\000\000\000\016IDAT\010\231c``p``\000\000\000\306\000A\316q\f\035\000\000\000\000IEND\256B`\202", c.make_image('1', 1, 1).pngStr
    end

    def ok(e, d)
      config = Qwik::Config.new
      config.update Qwik::Config::DebugConfig
      qrcode = QRCode.new(config.qrcode_dir)
      data = qrcode.make_qrcode(d)
      png = QRCodeView.generate_png(data)
      assert_equal(e, png)
    end

    def test_image_generate
      return if $0 != __FILE__		# Only for separated test.
      return if ! $have_gd

      config = Qwik::Config.new
      config.update Qwik::Config::DebugConfig
      qrcode = QRCode.new(config.qrcode_dir)
      return if ! qrcode.have_data?

      ok "\211PNG\r\n\032\n\000\000\000\rIHDR\000\000\000:\000\000\000:\001\003\000\000\000\333u\330k\000\000\000\006PLTE\377\377\377\000\000\000U\302\323~\000\000\000|IDAT(\221\255\3161\n\304P\010\204a!\255\340U\002i\003{\365\001[\301\253\274\003\010\356\203}\t\232m3\325\327\315O\364\3262\322\023\025\340\323\250\301\2159\036\210?\230u\200\223\251!\303\256\257\005\"\305\nY\200\347g\240\202U\364hPv\t\252\010\214\331Z\001\031!\250\230| c\214\215*\300\233\356\rn.\211\216\225Qp\3742n\200\367\323\e\346\305}ze\274\261/Y\240\2213q\313+w\000\000\000\000IEND\256B`\202", '0'
      ok "\211PNG\r\n\032\n\000\000\000\rIHDR\000\000\000:\000\000\000:\001\003\000\000\000\333u\330k\000\000\000\006PLTE\377\377\377\000\000\000U\302\323~\000\000\000~IDAT(\221\255\3201\n\0051\010\004P!\255\207\t\244\r\354\325\al\005\257\022H+\270\360I>&\365N\365\n\031E\242\257\022>-\220\001V\246\003\246]\375\302\340\e\375\002\270\357\236\205p\335\273\026\210\306>d\301\036\346\206\214\322T:e\310\203\220\003\263\360h\aJH\305\001\"o\204\214pt\243\f\2609#\303\264\355'\374\241\3657\234`U\017\200\233Nd\204\213\024\312\370&/\254\244\204\205c\263\274 \000\000\000\000IEND\256B`\202", '01234567'
    end
  end
end
