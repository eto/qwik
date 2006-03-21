$LOAD_PATH << 'compat' unless $LOAD_PATH.include? 'compat'
begin
  require 'zip/zip'
  $have_zip = true
rescue LoadError
  $have_zip = false
end

$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'
require 'qwik/act-presen'
require 'qwik/act-theme'

module Qwik
  class Action
    D_ExtArchive = {
      :dt => 'Site archive',
      :dd => 'You can obtain a zip archive ot the site content.',
      :dc => "* Example
{{zip}}

You can get a zip archive of all text data of this Wiki site.

The archive also contains static HTML files of the site.
You can place the static HTML files on your web site
as the static representation of the Wiki site.
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
      return page_attribute('zip', _('site archive'), @site.sitename)
    end

    def ext_zip
      c_require_member
      c_require_base_is_sitename
      path = SiteArchive.generate(@config, @site, self)
      return c_simple_send(path, 'application/zip')
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
      add_entry(zos, "#{base}.txt", page.load)

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

    def self.add_entry(zos, filename, content)
      e = Zip::ZipEntry.new('', filename)
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
	      [:a, {:href=>'test.zip'}, 'site archive']], '{{zip}}'
    end
  end

  class TestActArchive < Test::Unit::TestCase
    include TestSession

    def ok_nx(zis, f)
      e = zis.get_next_entry
      assert_equal_or_match(f, e.name)
    end

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

      page = @site.create('PresenTest')
      page.store '* A presentation test page'

      res = session '/test/test.zip'
      ok_eq 'application/zip', res['Content-Type']
      str = res.body
      assert_match(/\APK/, str)

      'testtemp.zip'.path.open('wb') {|f| f.print str }

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
      Zip::ZipOutputStream.open(file) {|zos|
	zos.put_next_entry('test/test.txt')
	zos.print('test')

	e = Zip::ZipEntry.new(file, 'test2.txt')
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

	e = zis.get_next_entry
	ok_eq(nil, e)
      }

      file.path.unlink
    end
  end
end
