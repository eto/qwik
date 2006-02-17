$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    D_theme_list = {
      :dt => 'Theme list',
      :dd => 'You can see theme list.',
      :dc => "* Example
 {{theme_list}}
{{theme_list}}
You can see the list of themes.

You can specify the theme of this site from [[_SiteConfig]].
" }

    def plg_theme_list
      return [:ul, theme_list.map {|t| [:li, t] }]
    end

    THEME_IGNORE_DIR = %(CVS icons s5 i ap js css swf sfcring)

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
      return theme_send_file(filename)
    end

    def theme_send_file(filename)
      path = @config.theme_dir.path+filename
      ext = path.ext
      type = @res.mimetypes[ext]
      return c_simple_send(path, type)
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
end
