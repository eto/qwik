# -*- coding: shift_jis -*-
# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH << 'compat' unless $LOAD_PATH.include? 'compat'
begin
  require 'zip/zip'
  $have_zip = true
rescue LoadError
  $have_zip = false
end

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/act-presen'
require 'qwik/act-theme'

module Qwik
  class Action
    D_ExtArchive = {
      :dt => 'Site archive',
      :dd => 'You can get a zip archive of the site.',
      :dc => "* Example
{{zip}}

You can get a zip archive with all text data of the Wiki site.

The archive also contains static HTML files of the site.
Thus, you can unzip the package and place them on your web site
as the static Web pages.
"
    }

    D_ExtArchive_ja = {
      :dt => 'サイト・アーカイブ',
      :dd => 'サイト・アーカイブを取得できます。',
      :dc => '* 使い方
{{zip}}

このリンクから、サイトの内容まるごと全部を一つのアーカイブにして
ダウンロードできます。

ファイルには、元となるテキストファイルと共に、静的なHTMLページも含まれ
ており、解凍してWebサイトに置けば、そのまま普通のWebページとして公開で
きます。
'
    }

    def plg_zip
      return page_attribute('zip', _('Site archive'), @site.sitename)
    end

    def archive_path
      return  @site.cache_path + "#{@site.sitename}.zip"
    end

    def archive_running_path
      return  @site.cache_path + "#{@site.sitename}.zip.running"
    end

    def archive_clear_cache
      path = archive_path
      path.unlink if path.exist?
      path = archive_running_path
      path.unlink if path.exist?
    end

    def ext_zip
      c_require_member
      c_require_base_is_sitename

      if archive_running_path.exist?
        return c_notice(_('Running.')) {
          [:div,
           [:p, _("The process is working now.")],
           [:p, _("Pleae wait for a while.")],
           [:p, [:a, {:href=>"#{@req.base}.zip"}, _('Again')]]]
        }
      end

      if archive_path.exist?
        return c_simple_send(archive_path, 'application/zip')
      end

      # Start New thread.
      Thread.new {
        archive_running_path.write("running")
        SiteArchive.generate(@config, @site, self)
        archive_running_path.unlink
      }

      return c_notice(_('Start.')) {
        [:div,
         [:p, _("The archive process sgtarted.")],
         [:p, _("Pleae wait for a while.")],
         [:p, [:a, {:href=>"#{@req.base}.zip"}, _('Again')]]]
      }
    end
  end

  class SiteArchive
    def self.generate(config, site, action)
      sitename = site.sitename
      site_cache_path = site.cache_path
      site_cache_path.check_directory

      zip_filename = "#{sitename}.zip"
      zip_file = site_cache_path + zip_filename

      Zip::ZipOutputStream.open(zip_file.to_s) {|zos|
	site.each_all {|page|
	  add_page(site, action, zos, site_cache_path, page)
	}
	add_theme(site, action, zos, config.theme_dir)
      }

      return zip_file
    end

    private

    def self.add_page(site, action, zos, site_cache_path, page)
      base = "#{site.sitename}/#{page.key}"

      # Add original txt file.
      add_entry(zos, "#{base}.txt", page.load, page.mtime)

      # Generate a html file.
      html_path = site_cache_path+"#{page.key}.html"
      # Call act-html.
      #action.view_page_cache_generate(page.key) if ! html_path.exist?
      # Force create static HTML file.
      action.view_page_cache_generate(page.key)
      raise "Unknown error for '#{page.key}'" if ! html_path.exist?	# What?
      filename = "#{base}.html"
      add_entry(zos, filename, html_path.read)

      # Generate a presen file if the page is related to presen.
      if /\Apresen/i =~ page.key || /\{\{presen/ =~ page.load
	html_path = site_cache_path+"#{page.key}-presen.html"
	wabisabi = action.c_page_res(page.key)
	w = PresenGenerator.generate(site, page.key, wabisabi)
	add_entry(zos, "#{base}-presen.html", w.format_xml)
      end
    end

    def self.add_entry(zos, filename, content, mtime = Time.new)
      e = Zip::ZipEntry.new('', filename, '', '', 0,0,
                            Zip::ZipEntry::DEFLATED, 0, mtime)
      zos.put_next_entry(e)
      zos.write(content)
    end

    def self.add_theme(site, action, zos, theme_dir)
      ar = []

      # FIXME: Collect this file list from the directory.
      ar << 'css/base.css'
      ar << 'css/wema.css'
      ar << 'js/base.js'
      ar << 'js/debugwindow.js'
      ar << 'js/niftypp.js'
      ar << 'js/wema.js'
      ar << 'i/external.png'
      ar << 'i/new.png'

      t = action.site_theme
      list = action.theme_files(t)
      list.each {|f|
	ar << "#{t}/#{f}"
      }

      ar << 's5/qwikworld/slides.css'
      ar << 's5/qwikworld/s5-core.css'
      ar << 's5/qwikworld/framing.css'
      ar << 's5/qwikworld/pretty.css'
      ar << 's5/qwikworld/bg-shade.png'
      ar << 's5/qwikworld/bg-slide.jpg'

      ar << 's5/default/opera.css'
      ar << 's5/default/outline.css'
      ar << 's5/default/print.css'
      ar << 's5/default/slides.js'

      ar.each {|b|
	add_entry(zos, "#{site.sitename}/.theme/#{b}",
		  "#{theme_dir}/#{b}".path.read)
      }
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  require 'qwik/util-pathname'
  $test = true
end

if defined?($test) && $test
  class TestActArchive < Test::Unit::TestCase
    include TestSession

    def test_plg_zip
      ok_wi [:p, [:a, {:href=>'test.zip'}, 'test.zip']], '[[test.zip]]'
      ok_wi [:span, {:class=>'attribute'},
	      [:a, {:href=>'test.zip'}, 'Site archive']], '{{zip}}'
    end
  end

  class TestActArchive < Test::Unit::TestCase
    include TestSession

    def test_act_zip
      t_add_user

      page = @site['_SiteConfig']
      page.store ':theme:qwikborder'

      page = @site.create_new
      page.store '* あ'

      page = @site.create_new
      page.store '* A Presentation Page
{{presen}}
* Header 2
'
      mtime = {}
      mtime[page.key] = page.mtime

      sleep(1)			# let mtime be odd value

      page = @site.create('PresenTest')
      page.store '* A presentation test page'
      mtime[page.key] = page.mtime

      res = session '/test/test.zip'
      ok_title "Start."

      res = session '/test/test.zip'
      ok_title "Running."

      sleep(1)		# I hope this might work...

      res = session '/test/test.zip'
      ok_eq 'application/zip', res['Content-Type']
      str = res.body
      assert_match(/\APK/, str)

      'testtemp.zip'.path.write(str)

      list = []
      Zip::ZipInputStream.open('testtemp.zip') {|zis|
	while e = zis.get_next_entry
	  list << e.name
	end
      }

      files = %w(
test/1.txt
test/1.html
test/2.txt
test/2.html
test/2-presen.html
test/PresenTest.txt
test/PresenTest.html
test/PresenTest-presen.html
test/_SiteConfig.txt
test/_SiteConfig.html
test/_SiteMember.txt
test/_SiteMember.html
test/.theme/css/base.css
test/.theme/css/wema.css
test/.theme/js/base.js
test/.theme/js/debugwindow.js
test/.theme/js/niftypp.js
test/.theme/js/wema.js
test/.theme/i/external.png
test/.theme/i/new.png
test/.theme/qwikborder/qwikborder_h2.png
test/.theme/qwikborder/qwikborder_li.png
test/.theme/qwikborder/qwikborder_ball.png
test/.theme/qwikborder/qwikborder.css
test/.theme/s5/qwikworld/slides.css
test/.theme/s5/qwikworld/s5-core.css
test/.theme/s5/qwikworld/framing.css
test/.theme/s5/qwikworld/pretty.css
test/.theme/s5/qwikworld/bg-shade.png
test/.theme/s5/qwikworld/bg-slide.jpg
test/.theme/s5/default/opera.css
test/.theme/s5/default/outline.css
test/.theme/s5/default/print.css
test/.theme/s5/default/slides.js
)

      not_included_files = %w(
test/1-presen.html
)

      files.each {|file|
	eq true, list.include?(file)
      }

      not_included_files.each {|file|
	eq false, list.include?(file)
      }

      Zip::ZipInputStream.open('testtemp.zip') {|zis|
	while e = zis.get_next_entry
	  e_name = File.basename(e.name,'.txt')
	  if mtime.has_key? e_name
	    expected = mtime[e_name].to_i / 2 * 2
	    actual = e.time.to_i / 2 * 2
	    ok_eq(expected, actual)
	  end
	end
      }

      'testtemp.zip'.path.unlink
    end
  end

  class TestSiteArchive < Test::Unit::TestCase
    include TestSession

    def test_zip
      res = session

      page = @site.create_new
      page.store('* あ')

      zip = Qwik::SiteArchive.generate(@config, @site, @action)
      assert_match(/test.zip\Z/, zip.to_s)
    end
  end

  class CheckZip < Test::Unit::TestCase
    def test_all
      return if $0 != __FILE__		# Only for separated test.

      file = 'test.zip'
      time = Time.now - (60*60*24) # yesterday
      Zip::ZipOutputStream.open(file) {|zos|
	zos.put_next_entry('test/test.txt')
	zos.print('test')

#     Signature of Zip::ZipEntry.new()
# 	new(zipfile = "", name = "", comment = "", extra = "",
# 	    compressed_size = 0, crc = 0,
# 	    compression_method = ZipEntry::DEFLATED, size = 0,
# 	    time = Time.now)   

	e = Zip::ZipEntry.new('', 'test2.txt', '', '',
			      0, 0, 
			      Zip::ZipEntry::DEFLATED, 0, time)
	zos.put_next_entry(e)
	zos.print('test2')
      }

      zip = file.path.open {|f| f.read }
      assert_match(/\APK/, zip)
      assert_match(/test.txt/, zip)

      Zip::ZipInputStream.open(file) {|zis|
	e = zis.get_next_entry
	ok_eq('test/test.txt', e.name)
	ok_eq('test', zis.read)

	e = zis.get_next_entry
	ok_eq('test2.txt', e.name)
	ok_eq('test2', zis.read)

	# at parse_binary_dos_format() in zip/stdrubyext.rb,
	# 'second' should not be odd value
	# 86:     second = 2 * (       0b11111 & binaryDosTime)
	time_i = time.to_i / 2 * 2
	e_time_i = e.time.to_i / 2 * 2
	ok_eq(time_i, e_time_i)

	e = zis.get_next_entry
	ok_eq(nil, e)
      }

      file.path.unlink
    end
  end
end
