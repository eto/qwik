# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

require 'uri'
require 'net/http'

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    D_SiteTheme = {
      :dt => 'Site Theme',
      :dd => 'You can choose your favorite page design.',
      :dc => '* How to
** Choose from themes of qwikWeb
{{theme_list}}
You can choose a theme from this list.
Go to [[_SiteConfig]] page, replace
 :theme:qwikgreen
line. The page design will be changed.

\'\'\'Caution:\'\'\' Some themes, such as qwiksystem, are for system pages.
If you choose to use such themes, the page design will be strange.

** Use your own CSS file
Go to [[_SiteTheme]] page, attach your css file with the filename
"\'\'\'theme.css\'\'\'".

\'\'\'Caution:\'\'\' There are several inhibited elements in CSS.
Please see [[PluginStyle.describe]].

{{warning_for_css}}

** Use CSS file on external Web site
Goto [[_SiteConfig]] page,
replace
 :theme:qwikgreen
line to something like
 :theme:http://d.hatena.ne.jp/theme/clover/clover.css
to specify the css file. The page design will be changed.

\'\'\'Caution:\'\'\' Even if you are using an external CSS file,
there are several inhibited pattern. Please see [[PluginStyle.describe]].
'
    }

    D_SiteTheme_ja = {
      :dt => 'サイト・テーマ',
      :dd => 'サイト毎にページ・デザインを指定できます。',
      :dc => '* 使い方
** qwikWebが提供するテーマから選ぶ
{{theme_list}}
この選択可能なテーマ一覧の中から一つを選び、[[_SiteConfig]]ページにて
 :theme:qwikgreen
という一行を書換えてください。ページ・デザインが変更されます。

\'\'\'注意:\'\'\' qwiksystemなどの一部のページは、システム表示のための
ものです。通常のページ表示に使うと、表示が変になります。

** 自分で作ったCSSファイルを使う
[[_SiteTheme]]というページに行き、そのページに添付ファイルとして
「\'\'\'theme.css\'\'\'」というファイル名で自分の好きなCSSファイルを
添付してください。

\'\'\'注意:\'\'\' CSS中には使えない要素があります。
詳しくは[[PluginStyle.describe]]をご覧ください。

{{warning_for_css}}

** 外部のWebサイトに置いてあるCSSファイルを使う
[[_SiteConfig]]ページの
 :theme:qwikgreen
という一行を書換えて、
 :theme:http://d.hatena.ne.jp/theme/clover/clover.css
という感じにURLを指定してください。ページ・デザインが変更されます。

\'\'\'注意:\'\'\' 外部CSSファイルを使う場合にも、そのCSSファイル中に
使用禁止要素が含まれている場合には使えません。
詳しくは[[PluginStyle.describe]]をご覧ください。

'
    }

    # ============================== site theme
    SITE_THEME = '_SiteTheme'
    THEME_FILE = 'theme.css'

    def site_theme
      return @site.siteconfig['theme']
    end

    def site_theme_path
      files = @site.files(SITE_THEME)
      if files && files.exist?(THEME_FILE)
	#return "/#{@site.sitename}/.css/theme.css"
	#return c_relative_to_root(".css/theme.css")
	return ".css/theme.css"
      end

      t = site_theme
      if /\Ahttp:\/\// =~ t
	#return "/#{@site.sitename}/.css/#{t}"
	#return c_relative_to_root(".css/#{t}")
	return ".css/#{t}"
      end

      return ".theme/#{t}/#{t}.css"
    end

    # ============================== theme_list
    def plg_theme_list
      return [:ul, *theme_list.map {|t| [:li, t] }]
    end

    THEME_IGNORE_DIR = %(css i js s5 swf)

    def theme_list
      themes = []
      theme_path = @config.theme_dir.path
      theme_path.each_entry {|d|
	s = d.to_s
	next if /\A\./ =~ s
	next if THEME_IGNORE_DIR.include?(s)
	dir = theme_path+d
	next unless dir.directory?
	themes << d.to_s
      }
      return themes.sort
    end

    # ============================== theme
    def pre_act_theme
      args = @req.path_args
      filename = args.join('/')
      path = @config.theme_dir.path+filename
      return c_simple_send(path)
    end

    # from act-archive.rb.  Used for archive.
    def theme_files(theme)
      dir = @config.theme_dir.path+theme
      return unless dir.directory?
      files = []
      dir.each_entry {|f|
	file = dir+f
	next if file.directory?
	s = f.to_s
	next if /\A\./ =~ s || /\~\z/ =~ s || s == 'CVS'
	files << f.to_s
      }
      return files
    end

    # ============================== CSS
    def pre_act_css
      str = ''
      return nil if @req.path_args.empty?

      if @req.path_args.length == 1
	filename = @req.path_args[0]
	content, type = css_get_from_site_theme(filename)
	return c_notfound if content.nil?

	@res['Content-Type'] = type
	@res.body = content
	return
      end

      url = @req.path_args.join('/')
      content = css_get_by_url(url)
      return c_notfound if content.nil?
      @res['Content-Type'] = 'text/css'
      @res.body = content
      return
    end

    INVALID_CSS_INDICATOR = '/* invalid css */'
    def css_get_from_site_theme(filename)
      files = @site.files(SITE_THEME)
      return nil if files.nil? || ! files.exist?(filename)
      str = files.get(filename)
      return nil if str.nil?
      ext = filename.path.ext
      type = @res.get_mimetypes ext
      if type == 'text/css'
	str = INVALID_CSS_INDICATOR if ! CSS.valid?(str)
	return str, type
      elsif /\Aimage\// =~ type
	return str, type
      else
	return nil
      end
    end

    def css_get_by_url(url)
      # Add one more slash.
      url = url.sub(/\Ahttp:\//, 'http://') if /\Ahttp:\/[^\/]/ =~ url
      content = c_fetch_by_url(url)
      return nil if content.nil?
      return '/* invalid css */' if ! CSS.valid?(content)
      return content
    end

    def c_fetch_by_url(url)
      uri = URI(url)
      return nil if uri.scheme != 'http'
      res = nil
      begin
	Net::HTTP.start(uri.host, uri.port) {|http|
	  res = http.get(uri.path)
	}
      rescue
	return nil
      end
      return res.body
    end

    # ============================== warning for CSS
    def plg_warning_for_css
      content, type = css_get_from_site_theme('theme.css')
      return nil if content.nil?
      if content != INVALID_CSS_INDICATOR
	return [:span, 'Attached CSS content is safe.']
      else
	return [:strong, 'Invalid elements are used in your CSS file.']
      end
    end

    # ============================== favicon.ico
    def pre_ext_ico
      #p @req.base
      if ! @req.base == "favicon"
        #p "Error"
        return c_nerror(_('Error'))
      end
      path = @config.theme_dir.path + "i/favicon.ico"
      return c_simple_send(path, "image/vnd.microsoft.icon")
    end

  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActTheme < Test::Unit::TestCase
    include TestSession

    def test_site_theme
      res = session

      # test_theme
      eq 'qwikgreen', @action.site_theme

      # test_theme_path
      eq '.theme/qwikgreen/qwikgreen.css', @action.site_theme_path

      page = @site['_SiteConfig']
      page.store(':theme:t')	# No such theme, but this is just a test.
      eq 't', @action.site_theme
      eq '.theme/t/t.css', @action.site_theme_path

      # test_site_theme
      page = @site['_SiteTheme']
      page.store 't'
      files = @site.files('_SiteTheme')
      files.put 'theme.css', 't'
      eq '.css/theme.css', @action.site_theme_path

      t_with_path {
	eq '.css/theme.css', @action.site_theme_path
      }

      t_with_siteurl {
	eq '.css/theme.css', @action.site_theme_path
      }
    end

    def test_act_theme
      res = session '/.theme/css/base.css'
      assert_match(/\A\/*/, res.body)
    end

    def test_theme_all
      # test_theme_list
      res = session
      list = @action.theme_list
      eq true, list.include?('qwiksystem')
      eq true, list.include?('qwikborder')
      eq true, 4 <= list.length		# At least 4 themes.

      # test_plg_theme_list
      ok_wi(/<li>qwikborder<\/li>/, '{{theme_list}}')
      ok_wi(/<li>qwiksystem<\/li>/, '{{theme_list}}')

      # test_theme_files
      list = @action.theme_files('qwikborder')
      eq ['qwikborder.css', 'qwikborder_ball.png',
	'qwikborder_h2.png', 'qwikborder_li.png'], list.sort	# It depends.
      eq true, 4 <= list.length		# At least 4 files.
    end

    # Please see check-act-theme.rb for external CSS.
    def test_act_css
      page = @site['_SiteTheme']
      page.store 't'

      files = @site.files('_SiteTheme')
      files.put 'theme.css', '/* test */'

      res = session '/test/.css/theme.css'
      eq '/* test */', res.body
      eq 'text/css', res['Content-Type']
      files.delete 'theme.css'

      # test_invalid_css
      files.put 'theme.css', '@i'
      res = session '/test/.css/theme.css'
      eq '/* invalid css */', res.body
      files.delete 'theme.css'

      # test_image
      files.put 't.png', 't'
      res = session '/test/.css/t.png'
      eq 't', res.body
      eq 'image/png', res['Content-Type']
      files.delete 't.png'
    end

    def test_ext_ico
      # FIXME: This test case is broken.
      res = session("/nosuch.ico")
      #is "text/html; charset=Shift_JIS", res['Content-Type']
      #is 894, res.body

      res = session("/favicon.ico")
      is "image/vnd.microsoft.icon", res['Content-Type']
      is 894, res.body.size	# This size may vary.
    end

  end
end
