$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'
require 'qwik/act-theme'

module Qwik
  class Action
    D_PluginAlbum = {
      :dt => 'Album plugin',
      :dd => 'Show attached images in a window.',
      :dc => "* Example
 {{album}}
* Thanks
I use '[[Nameraka Alubum|http://sappari.org/na.html]]'
by Mr. Keisuke Kambralto show the album.
Thank you very much.
"
    }

    D_PluginAlbum_ja = {
      :dt => 'アルバム・プラグイン',
      :dd => '添付された画像ファイルを一度に見ることができます。',
      :dc => '* 例
 {{album}}
* 感謝
神原 啓介氏による「[[なめらかアルバム|http://sappari.org/na.html]]」機能を
使用しております。どうもありがとうございます。
'
    }

    # http://co/qwik/HelloQwik/ActAlbum.html
    def plg_album
      c_require_page_exist

      files = @site.files(@req.base)

      list = files.image_list
      return nil if list.empty?

      # Generate screen size jpeg files.
      files.generate_all_screen

      # Generate album.html
      movie = 'album.swf'
      object = [:object,
	{:classid=>'clsid:D27CDB6E-AE6D-11cf-96B8-444553540000',
	  :codebase=>'http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=6,0,0,0',
	  :width=>'100%',
	  :height=>'100%',
	  :id=>'album',
	  :align=>''},
	[:param, {:name=>'movie', :value=>movie}],
	[:param, {:name=>'quality', :value=>'high'}],
	[:param, {:name=>'bgcolor', :value=>'#000000'}],
	[:embed, {:src=>movie,
	    :quality=>'high',
	    :bgcolor=>'#000000',
	    :width=>'100%',
	    :height=>'100%',
	    :name=>'album',
	    :align=>'',
	    :type=>'application/x-shockwave-flash',
	    :pluginspage=>'http://www.macromedia.com/go/getflashplayer',
	    :value=>movie}]]

      album_html = [:html,
	[:head,
	  [:title, 'album'],
	  [:style, '
* {
  padding: 0;
  margin: 0;
}
body {
  background-color: #000;
  border: 0;
}
']],
	[:body, object]]
      html_str = album_html.format_xml
      files.overwrite('album.html', html_str)

      # Generate album.swf
      fname = 'album.swf'
      if ! files.exist?(fname)
	swf_path = @config.theme_dir.path+'swf'+fname
	swf = swf_path.read
	files.overwrite(fname, swf)
      end

      # Generate config.txt
      fname = 'config.txt'
      if ! files.exist?(fname)
	config_txt = album_generate_config_txt
	files.overwrite(fname, config_txt)
      end

      # Generate photo.txt
      use_thumb = true
      #use_thumb = false
      photo_txt = album_generate_photo_txt(use_thumb)
      files.put('photo.txt', photo_txt, true)

      h = "#{@req.base}.files/album.html"
      return [:div, {:class=>'album'},
	[:iframe, {:src=>h, :style=>'width:700px;height:400px;border:0;'}, ''],
	[:br],
	[:div, {:style=>'margin: 0 0 1em 0;'},
	  [:a, {:href=>h, :style=>'font-size:x-small;'},
	    _('Show album in fullscreen.')]]]
    end

    def album_generate_config_txt
      config = {				# original setting
	:ImageHeightPercent	=> 95,		# 80
	:BackgroundColor	=> '0x000000',	# '0x000000'
	:ImageBorderWidth	=> 0,		# 8
	:ImageBorderColor	=> '0xcccccc',	# '0xFFFFFF'
	:ArrowColor		=> '0x99ffff',	# '0xFFFFFF'
	:ScreenBorderColor	=> '0x999999',	# '0x666666'
	:ScrollbarColor		=> '0xccffff',	# '0xFFFFFF'
      }
      return config.to_query_string
    end

    def album_generate_photo_txt(use_screen=false)
      files = @site.files(@req.base)
      return '' if files.nil?
      str = ''
      files.each_image {|file|
	str += ".screen/#{file}|" if use_screen
	str += "#{file}\n"
      }
      return str
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActAlbum < Test::Unit::TestCase
    include TestSession

    def test_album
      t_add_user

      page = @site.create_new
      page.store('{{album}}')

      # Before attaching images, the plugin has no effect.
      ok_wi('', "{{album}}")

      files = @site.files('1')
      png = TEST_PNG_DATA
      files.put('1.jpg', png)	# content is PNG, but use extention .jpg
      files.put('2.jpg', png)

      res = session('/test/1.html')
      ok_xp([:div, {:class=>'album'},
	      [:iframe, {:src=>'1.files/album.html',
		  :style=>'width:700px;height:400px;border:0;'},''],
	      [:br],
	      [:div, {:style=>'margin: 0 0 1em 0;'},
		[:a, {:href=>'1.files/album.html',
		    :style=>'font-size:x-small;'},
		  'Show album in fullscreen.']]],
	    "//div[@class='album']")

      ok_eq(true, files.exist?('1.jpg'))
      ok_eq(true, files.exist?('album.html'))
      ok_eq(true, files.exist?('album.swf'))
      ok_eq(true, files.exist?('config.txt'))
      ok_eq(true, files.exist?('photo.txt'))
     #ok_eq("1.jpg\n2.jpg\n", files.get('photo.txt'))
      ok_eq(".screen/1.jpg|1.jpg\n.screen/2.jpg|2.jpg\n",
	    files.get('photo.txt'))
    end
  end
end
