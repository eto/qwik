#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'
require 'qwik/qrcode'
require 'qwik/wabisabi-generator'

$have_gd = false
begin
  require 'GD'
  $have_gd = true
rescue LoadError
  $have_gd = false
end

class QRCodeView
  def initialize(path)
    @have_qrcode_data = false
    if File.exist?(path)
      @have_qrcode_data = true
      @qrcode = QRCode.new(path)
    end
  end
  attr_reader :have_qrcode_data

  # Generate QRCode html string.
  def generate_html(d)
    return nil if ! @have_qrcode_data
    return generate_html_from_data(@qrcode.make_qrcode(d))
  end

  def generate_html_from_data(d)
    ar = []
    ar[?0] = '<td/>'
    ar[?1] = '<th/>'
    return ['<table class="qrcode">',
      d.map {|line|
	tr = '<tr>'
	line.chomp.each_byte {|b|
	  tr << ar[b]
	}
	tr << '</tr>'
	tr
      }.join,
      '</table>'].join
  end

  # Generate QRCode html data by wabisabi.
  def generate_wabisabi(d)
    return nil if ! @have_qrcode_data
    return generate_wabisabi_from_data(@qrcode.make_qrcode(d))
  end

  def generate_wabisabi_from_data(d)
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

  # Generate QRCode image by using GD.
  def generate(d)
    return nil if ! @have_qrcode_data
    return generate_png_from_data(@qrcode.make_qrcode(d))
  end

  def generate_png_from_data(data)
    return mkimage(data).pngStr
  end

  def mkimage(data, m=2, q=4)
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
	if (row[x,1] == '1')
	  img.setPixel(x, y, black)
	end
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
  require 'qwik/testunit'
  require 'qwik/util-kconv'
  require 'qwik/config'
  require 'qwik/qp'
  require 'qwik/wabisabi-format-xml'
  $test = true
end

if defined?($test) && $test
  class TestQRCode < Test::Unit::TestCase
    def test_all
      return if $0 != __FILE__		# Only for separated test.

      config = Qwik::Config.new
      q = QRCode.new(config.qrcode_dir)
      return if ! q.have_qrcode_data

      ok_eq(
'111111101111101111111
100000100110101000001
101110100010001011101
101110101110001011101
101110101010101011101
100000101111001000001
111111101010101111111
000000001001100000000
100010111111011111001
001010010011100101011
100100101011001111100
111010001100011010100
100000111100111000111
000000001000111000111
111111101100110000010
100000100001100101000
101110101011001111111
101110100011100101011
101110100101001111100
100000100100011010110
111111101100111000111
',
	    q.make_qrcode('0'))
      ok_eq(0, q.qrcode_version)
      ok_eq(1, q.qrcode_version_used)

      ok_eq('1fdf7f:104d41:17445d:175c5d:17555d:105e41:1fd57f:1300:117ef9:5272b:12567c:1d18d4:1079c7:11c7:1fd982:104328:17567f:17472b:174a7c:1048d6:1fd9c7', q.qrcode_ar('0'))
      ok_eq('1fdb7f:105441:174d5d:17585d:174c5d:104c41:1fd57f:1800:16e44b:2b52c:12f1f2:1a258a:3f290:1ca1:1fd0d6:1057c5:174a41:175496:175694:104b5b:1fd322', q.qrcode_ar('01234567'))
      ok_eq('1fdf7f:105c41:174f5d:17555d:174c5d:104041:1fd57f:1c00:16e44b:e252c:10cdf2:c2d8a:1dea90:18a1:1fd4d4:1057c1:17464d:17549a:175a90:104b5b:1fd722', q.qrcode_ar('012345678'))
      #ok_eq('1fd837f:1053141:175b35d:174415d:175a75d:104f341:1fd557f:5b00:13f0997:b9f93e:64aba9:1e3da6f:1561941:b98e12:3ebb0f:b26195:cec7f6:13f12:1fda159:1055712:175dffa:1750469:17457b7:104c437:1fd8d89', q.qrcode_ar('http://example.com/'))
      ok_eq('1fce17f:1046a41:175655d:175cc5d:175885d:1054f41:1fd557f:1c500:17c887c:4ba9a2:b51ffb:4261a1:3d9c77:b092a:fd3abb:ca2229:d6adf4:1d71c:1fcc15f:105911a:1755bff:175c8f7:1753ea5:104a739:1fdb0ff', q.qrcode_ar('http://www.yahoo.co.jp/'))
      ok_eq('1fd77f:104e41:17475d:17525d:17515d:105641:1fd57f:1700:117ef9:18af2f:11d273:618d0:bedc3:1dcf:1fd18d:10472d:175a73:174f0f:17467c:104cfe:1fddcf', q.qrcode_ar('0123456789'))
      ok_eq('1fca7f:104b41:17495d:17445d:17415d:105341:1fd57f:700:12d0a0:19a842:e4d8c:8e0b:dc151:1e30:1fc0ab:1057bf:174673:17562b:174111:1048fe:1fd330', q.qrcode_ar('01234567890'))
      ok_eq('1fdd7f:105541:17475d:175a5d:17425d:104341:1fd57f:1b00:16eb4b:141fc8:13560d:13967c:17cd24:1a48:1fd328:105836:1745f1:175e7e:175d60:1044a5:1fd890', q.qrcode_ar('a'))
      ok_eq('1fd27f:104641:17495d:175e5d:17535d:105941:1fd57f:1800:1175f9:1db9cc:8498a:e1320:dda7a:1f2e:1fd27a:1040d0:175dc9:1749c7:174d88:104328:1fda75', q.qrcode_ar('http'))
      ok_eq('1fc67f:105541:17565d:175d5d:17415d:104e41:1fd57f:1800:105ece:1fb56e:7186:1a10bc:12ee02:109d:1fcfe6:1048ef:17465b:174454:17477f:104294:1fd87a', q.qrcode_ar('http://qwik.j'))
      ok_eq('1fc47f:105041:175a5d:17555d:17475d:104d41:1fd57f:1f00:1055ce:1c195d:ae69f:1db41c:ee84b:13cc:1fc962:104392:174130:174d0c:17485b:10442a:1fd2a0', q.qrcode_ar('0123456789012'))
      ok_eq('1fce7f:105341:17535d:175c5d:17415d:104e41:1fd57f:1400:105ace:d17bd:1a555f:18bcc:1f4beb:1d5c:1fce30:104c43:174a12:174fcc:17439b:104bea:1fdd20', q.qrcode_ar('01234567890123456789'))
      ok_eq('1fdf7f:104341:174d5d:175d5d:17555d:105e41:1fd57f:1b00:117af9:178d2f:187ac3:1082b0:15e713:139f:1fd06d:104a2f:175271:174d0f:174b5c:104ed6:1fda43', q.qrcode_ar('012345678901234567890123456789'))
      ok_eq('1fdb7f:105441:174d5d:17585d:174c5d:104c41:1fd57f:1800:16e44b:2b52c:12f1f2:1a258a:3f290:1ca1:1fd0d6:1057c5:174a41:175496:175694:104b5b:1fd322', q.qrcode_ar('01234567'))
      ok_eq('1fdf7f:105c41:174f5d:17555d:174c5d:104041:1fd57f:1c00:16e44b:e252c:10cdf2:c2d8a:1dea90:18a1:1fd4d4:1057c1:17464d:17549a:175a90:104b5b:1fd722', q.qrcode_ar('012345678'))
      ok_eq('1fc2527f:104ead41:175e745d:175ded5d:1758125d:10512c41:1fd5557f:185000:17cf2d7c:1a939251:1447f1be:198684d3:7697fae:18381259:8712092:172b7050:56d2fae:baed259:fc1f93a:cb8a782:d5a6dfe:151319:1fcc2b56:105f5113:17512dfc:175159ab:175d765e:104f6712:1fd4dc0c', q.qrcode_ar('012345678901234567890123456789fadsfdsa'))
      #ok_eq('1fdf7f:104341:174d5d:175d5d:17555d:105e41:1fd57f:1b00:117af9:178d2f:187ac3:1082b0:15e713:139f:1fd06d:104a2f:175271:174d0f:174b5c:104ed6:1fda43', q.qrcode_ar('abcdefghijklmnopqrstuvwxyz'))
      ok_eq('1fda77f:104ad41:175175d:174665d:174fc5d:1051041:1fd557f:3600:1469d25:fb0f89:1949329:1211b56:445a09:15311a8:2d9f08:1d1753c:4fcdfb:10d10:1fd2357:1048919:1743bfe:174106c:1759dcb:10436c6:1fd8deb', q.qrcode_ar('0123456789012345678901234567890123456789'))
      ok_eq('1fd43af9f29c67f:10561da0e61fa41:174edf10850365d:1756be00070e25d:174a9347fbc1a5d:104f6a7461ff441:1fd55555555557f:1786ac4f5ca00:16e2c65fc27c94b:1aa63b32c5bf3b1:34f99c9f32c527:f228b037ae7d08:dd0a2562502842:1af2d1a28c08c0:276765d70f43f0:3a098addafdc5c:176472f6f86f72d:14039da69c3ae91:145815f1c6164a:53e803d491c270:16dca85746f0f57:596efb2b01e3a1:1e91d3d974d40b:41ab2d2a5c3489:18e63a24730a288:168e2b4809c28c4:ff61b1fd1c61fc:1b1fca345871d1c:135db3f5786f95e:1b1cd824771af15:ffbbe7fd15bdf6:60f2fce4a90190:15d4716043b4dc4:131101000bc308:11c46489251c6da:538708b71cb7ca:1cdf1d426b46570:10125e032bf0a28:eea4e48a2d4328:f0f0e75bcdde7f:1c5bb63df02f69c:10b46bef0e79f79:10f59ccecd20c16:d09eccfffde503:65e2b5026fc52e:99cbf4e08f205:14c12eeb940e4c3:1f3bfcd1bb833f8:51ba67ef8a5f8:19790c6cd1110:1fd8c1c574c4354:105570745f7111c:174987aff2ab5fc:1756523cbe2af86:17583e00ed727c8:104eb75c2b34ac1:1fd161d0467c7f4', q.qrcode_ar('http://qwik/shfdosadhfashofhasodufhosduahfuoasdsdfsdafsadhfkjdshafkjahdskfjhdsakhfsalkhfkdashkjsdfhaskjlfhlkajsdhflkjashdlkfjhasdlkjfhlskajdhfkjsahdljkfhsalkjdfhlksjadhfkjsadhfjklsahdlkjfhaskj'))
    end
  end

  class TestQRCodeView < Test::Unit::TestCase
    def test_wabisabi
      return if $0 != __FILE__		# Only for separated test.

      config = Qwik::Config.new
      q = QRCodeView.new(config.qrcode_dir)
      return if ! q.have_qrcode_data

      qrcode = q.instance_eval { @qrcode }
      d = nil
      (1..1).each { # 100times: 23.628 seconds.
	d = qrcode.make_qrcode('0')
	ok_eq(
'111111101111101111111
100000100110101000001
101110100010001011101
101110101110001011101
101110101010101011101
100000101111001000001
111111101010101111111
000000001001100000000
100010111111011111001
001010010011100101011
100100101011001111100
111010001100011010100
100000111100111000111
000000001000111000111
111111101100110000010
100000100001100101000
101110101011001111111
101110100011100101011
101110100101001111100
100000100100011010110
111111101100111000111
',
	      d)
      }

      h = nil
      (1..1).each {
	h = q.generate_wabisabi_from_data(d)
      }
      ok_eq('<table class="qrcode"><tr><th/><th/><th/><th/><th/><th/><th/><td/><th/><th/><th/><th/><th/><td/><th/><th/><th/><th/><th/><th/><th/></tr><tr><th/><td/><td/><td/><td/><td/><th/><td/><td/><th/><th/><td/><th/><td/><th/><td/><td/><td/><td/><td/><th/></tr><tr><th/><td/><th/><th/><th/><td/><th/><td/><td/><td/><th/><td/><td/><td/><th/><td/><th/><th/><th/><td/><th/></tr><tr><th/><td/><th/><th/><th/><td/><th/><td/><th/><th/><th/><td/><td/><td/><th/><td/><th/><th/><th/><td/><th/></tr><tr><th/><td/><th/><th/><th/><td/><th/><td/><th/><td/><th/><td/><th/><td/><th/><td/><th/><th/><th/><td/><th/></tr><tr><th/><td/><td/><td/><td/><td/><th/><td/><th/><th/><th/><th/><td/><td/><th/><td/><td/><td/><td/><td/><th/></tr><tr><th/><th/><th/><th/><th/><th/><th/><td/><th/><td/><th/><td/><th/><td/><th/><th/><th/><th/><th/><th/><th/></tr><tr><td/><td/><td/><td/><td/><td/><td/><td/><th/><td/><td/><th/><th/><td/><td/><td/><td/><td/><td/><td/><td/></tr><tr><th/><td/><td/><td/><th/><td/><th/><th/><th/><th/><th/><th/><td/><th/><th/><th/><th/><th/><td/><td/><th/></tr><tr><td/><td/><th/><td/><th/><td/><td/><th/><td/><td/><th/><th/><th/><td/><td/><th/><td/><th/><td/><th/><th/></tr><tr><th/><td/><td/><th/><td/><td/><th/><td/><th/><td/><th/><th/><td/><td/><th/><th/><th/><th/><th/><td/><td/></tr><tr><th/><th/><th/><td/><th/><td/><td/><td/><th/><th/><td/><td/><td/><th/><th/><td/><th/><td/><th/><td/><td/></tr><tr><th/><td/><td/><td/><td/><td/><th/><th/><th/><th/><td/><td/><th/><th/><th/><td/><td/><td/><th/><th/><th/></tr><tr><td/><td/><td/><td/><td/><td/><td/><td/><th/><td/><td/><td/><th/><th/><th/><td/><td/><td/><th/><th/><th/></tr><tr><th/><th/><th/><th/><th/><th/><th/><td/><th/><th/><td/><td/><th/><th/><td/><td/><td/><td/><td/><th/><td/></tr><tr><th/><td/><td/><td/><td/><td/><th/><td/><td/><td/><td/><th/><th/><td/><td/><th/><td/><th/><td/><td/><td/></tr><tr><th/><td/><th/><th/><th/><td/><th/><td/><th/><td/><th/><th/><td/><td/><th/><th/><th/><th/><th/><th/><th/></tr><tr><th/><td/><th/><th/><th/><td/><th/><td/><td/><td/><th/><th/><th/><td/><td/><th/><td/><th/><td/><th/><th/></tr><tr><th/><td/><th/><th/><th/><td/><th/><td/><td/><th/><td/><th/><td/><td/><th/><th/><th/><th/><th/><td/><td/></tr><tr><th/><td/><td/><td/><td/><td/><th/><td/><td/><th/><td/><td/><td/><th/><th/><td/><th/><td/><th/><th/><td/></tr><tr><th/><th/><th/><th/><th/><th/><th/><td/><th/><th/><td/><td/><th/><th/><th/><td/><td/><td/><th/><th/><th/></tr></table>',
	    h.rb_format_xml(-1, -1))
    end

    def test_html
      return if $0 != __FILE__		# Only for separated test.

      config = Qwik::Config.new
      q = QRCodeView.new(config.qrcode_dir)
      return if ! q.have_qrcode_data

      qrcode = q.instance_eval { @qrcode }
      d = qrcode.make_qrcode('0')

      h = nil
      (1..1000).each {
	h = q.generate_html_from_data(d)
      }
      ok_eq('<table class="qrcode"><tr><th/><th/><th/><th/><th/><th/><th/><td/><th/><th/><th/><th/><th/><td/><th/><th/><th/><th/><th/><th/><th/></tr><tr><th/><td/><td/><td/><td/><td/><th/><td/><td/><th/><th/><td/><th/><td/><th/><td/><td/><td/><td/><td/><th/></tr><tr><th/><td/><th/><th/><th/><td/><th/><td/><td/><td/><th/><td/><td/><td/><th/><td/><th/><th/><th/><td/><th/></tr><tr><th/><td/><th/><th/><th/><td/><th/><td/><th/><th/><th/><td/><td/><td/><th/><td/><th/><th/><th/><td/><th/></tr><tr><th/><td/><th/><th/><th/><td/><th/><td/><th/><td/><th/><td/><th/><td/><th/><td/><th/><th/><th/><td/><th/></tr><tr><th/><td/><td/><td/><td/><td/><th/><td/><th/><th/><th/><th/><td/><td/><th/><td/><td/><td/><td/><td/><th/></tr><tr><th/><th/><th/><th/><th/><th/><th/><td/><th/><td/><th/><td/><th/><td/><th/><th/><th/><th/><th/><th/><th/></tr><tr><td/><td/><td/><td/><td/><td/><td/><td/><th/><td/><td/><th/><th/><td/><td/><td/><td/><td/><td/><td/><td/></tr><tr><th/><td/><td/><td/><th/><td/><th/><th/><th/><th/><th/><th/><td/><th/><th/><th/><th/><th/><td/><td/><th/></tr><tr><td/><td/><th/><td/><th/><td/><td/><th/><td/><td/><th/><th/><th/><td/><td/><th/><td/><th/><td/><th/><th/></tr><tr><th/><td/><td/><th/><td/><td/><th/><td/><th/><td/><th/><th/><td/><td/><th/><th/><th/><th/><th/><td/><td/></tr><tr><th/><th/><th/><td/><th/><td/><td/><td/><th/><th/><td/><td/><td/><th/><th/><td/><th/><td/><th/><td/><td/></tr><tr><th/><td/><td/><td/><td/><td/><th/><th/><th/><th/><td/><td/><th/><th/><th/><td/><td/><td/><th/><th/><th/></tr><tr><td/><td/><td/><td/><td/><td/><td/><td/><th/><td/><td/><td/><th/><th/><th/><td/><td/><td/><th/><th/><th/></tr><tr><th/><th/><th/><th/><th/><th/><th/><td/><th/><th/><td/><td/><th/><th/><td/><td/><td/><td/><td/><th/><td/></tr><tr><th/><td/><td/><td/><td/><td/><th/><td/><td/><td/><td/><th/><th/><td/><td/><th/><td/><th/><td/><td/><td/></tr><tr><th/><td/><th/><th/><th/><td/><th/><td/><th/><td/><th/><th/><td/><td/><th/><th/><th/><th/><th/><th/><th/></tr><tr><th/><td/><th/><th/><th/><td/><th/><td/><td/><td/><th/><th/><th/><td/><td/><th/><td/><th/><td/><th/><th/></tr><tr><th/><td/><th/><th/><th/><td/><th/><td/><td/><th/><td/><th/><td/><td/><th/><th/><th/><th/><th/><td/><td/></tr><tr><th/><td/><td/><td/><td/><td/><th/><td/><td/><th/><td/><td/><td/><th/><th/><td/><th/><td/><th/><th/><td/></tr><tr><th/><th/><th/><th/><th/><th/><th/><td/><th/><th/><td/><td/><th/><th/><th/><td/><td/><td/><th/><th/><th/></tr></table>', h)
    end

    def test_image
      return if $0 != __FILE__		# Only for separated test.

      return if ! $have_gd

      config = Qwik::Config.new
      q = QRCodeView.new(config.qrcode_dir)
      #return if ! q.have_qrcode_data

      ok_eq("\211PNG\r\n\032\n\000\000\000\rIHDR\000\000\000\022\000\000\000\022\001\003\000\000\000l\000\034\024\000\000\000\003PLTE\377\377\377\247\304\e\310\000\000\000\fIDAT\010\231c`\240\016\000\000\000H\000\001{\245\021\310\000\000\000\000IEND\256B`\202", q.mkimage('0').pngStr)
      ok_eq("\211PNG\r\n\032\n\000\000\000\rIHDR\000\000\000\022\000\000\000\022\001\003\000\000\000l\000\034\024\000\000\000\006PLTE\377\377\377\000\000\000U\302\323~\000\000\000\020IDAT\010\231c` \004\016@1~\000\0006H\001\201N\024'\263\000\000\000\000IEND\256B`\202", q.mkimage('1').pngStr)
      ok_eq("\211PNG\r\n\032\n\000\000\000\rIHDR\000\000\000\003\000\000\000\003\001\003\000\000\000l\346'\374\000\000\000\006PLTE\377\377\377\000\000\000U\302\323~\000\000\000\016IDAT\010\231c``p``\000\000\000\306\000A\316q\f\035\000\000\000\000IEND\256B`\202", q.mkimage('1', 1, 1).pngStr)
    end

    def test_image_generate
      return if $0 != __FILE__		# Only for separated test.

      return if ! $have_gd

      config = Qwik::Config.new
      q = QRCodeView.new(config.qrcode_dir)
      return if ! q.have_qrcode_data

      ok_eq("\211PNG\r\n\032\n\000\000\000\rIHDR\000\000\000:\000\000\000:\001\003\000\000\000\333u\330k\000\000\000\006PLTE\377\377\377\000\000\000U\302\323~\000\000\000|IDAT(\221\255\3161\n\304P\010\204a!\255\340U\002i\003{\365\001[\301\253\274\003\010\356\203}\t\232m3\325\327\315O\364\3262\322\023\025\340\323\250\301\2159\036\210?\230u\200\223\251!\303\256\257\005\"\305\nY\200\347g\240\202U\364hPv\t\252\010\214\331Z\001\031!\250\230| c\214\215*\300\233\356\rn.\211\216\225Qp\3742n\200\367\323\e\346\305}ze\274\261/Y\240\2213q\313+w\000\000\000\000IEND\256B`\202", q.generate('0'))
      ok_eq("\211PNG\r\n\032\n\000\000\000\rIHDR\000\000\000:\000\000\000:\001\003\000\000\000\333u\330k\000\000\000\006PLTE\377\377\377\000\000\000U\302\323~\000\000\000~IDAT(\221\255\3201\n\0051\010\004P!\255\207\t\244\r\354\325\al\005\257\022H+\270\360I>&\365N\365\n\031E\242\257\022>-\220\001V\246\003\246]\375\302\340\e\375\002\270\357\236\205p\335\273\026\210\306>d\301\036\346\206\214\322T:e\310\203\220\003\263\360h\aJH\305\001\"o\204\214pt\243\f\2609#\303\264\355'\374\241\3657\234`U\017\200\233Nd\204\213\024\312\370&/\254\244\204\205c\263\274 \000\000\000\000IEND\256B`\202", q.generate('01234567'))
    end
  end
end
