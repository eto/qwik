$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    D_plugin_theme_list = {
      :dt => 'Theme list',
      :dd => 'You can see theme list.',
      :dc => "* Example
 {{theme_list}}
{{theme_list}}
You can see the list of themes.

You can specify the theme of this site from [[_SiteConfig]].
"
    }

    Dja_plugin_theme_list = {
      :dt => 'テーマ一覧',
      :dd => '選択可能なテーマ一覧が表示されます。',
      :dc => '* 例
 {{theme_list}}
{{theme_list}}
選択可能なテーマ一覧です。

[[_SiteConfig]]ページにて、テーマを設定できます。
'
    }

    def plg_theme_list
      return [:ul, theme_list.map {|t| [:li, t] }]
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

    def pre_act_theme
      args = @req.path_args
      filename = args.join('/')
      path = @config.theme_dir.path+filename
      return c_simple_send(path)
    end

    # from act-archive.rb
    def theme_files(theme)
      dir = @config.theme_dir.path+theme
      return unless dir.directory?
      files = []
      dir.each_entry {|f|
	file = dir+f
	next if file.directory?
	s = f.to_s
	next if /\A\./ =~ s
	next if /\~\z/ =~ s
	next if s == 'CVS'
	files << f.to_s
      }
      return files
    end
  end

  class Site
    def theme
      return self.siteconfig['theme']
    end

    SITE_THEME = '_SiteTheme'
    THEME_FILE = 'theme.css'

    def theme_path
      files = self.files(SITE_THEME)
      if files && files.exist?(THEME_FILE)
	return '_SiteTheme.files/theme.css'
      end

      ac = "#{@sitename}.css"
      if self.files.exist?(ac)
	return "/#{@sitename}/.css/#{ac}"
      end

      t = self.theme
      if /\Ahttp:\/\// =~ t
	return '/.css/'+t
      end

      return ".theme/#{t}/#{t}.css"
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

    def test_act_theme
      res = session '/.theme/css/base.css'
      assert_match(/\A\/*/, res.body)
    end

    def test_all
      # test_plg_theme_list
      ok_wi(/<li>qwikborder<\/li>/, "{{theme_list}}")
      ok_wi(/<li>qwiksystem<\/li>/, "{{theme_list}}")

      # test_theme_list
      res = session
      list = @action.theme_list
      eq true, list.include?('qwiksystem')
      eq true, list.include?('qwikborder')
      eq true, 4 <= list.length		# at least 4 themes

      # test_theme_files
      list = @action.theme_files('qwikborder')
      eq ['qwikborder.css', 'qwikborder_ball.png',
	'qwikborder_h2.png', 'qwikborder_li.png'], list.sort
      eq true, 4 <= list.length		# at least 4 themes
    end
  end

  class TestSiteTheme < Test::Unit::TestCase
    include TestSession

    def test_all
      site = @memory.farm.get_top_site

      # test_theme
      eq 'qwikgreen', site.theme

      # test_theme_path
      eq '.theme/qwikgreen/qwikgreen.css', site.theme_path

      page = site['_SiteConfig']
      page.store(':theme:t')
      eq 't', site.theme
      eq '.theme/t/t.css', site.theme_path

      # test_site_theme
      page = site['_SiteTheme']
      page.store('t')
      files = site.files('_SiteTheme')
      files.put('theme.css', 't')
      eq "_SiteTheme.files/theme.css", site.theme_path
    end
  end
end
