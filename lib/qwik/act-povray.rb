$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    D_PluginPovray = {
      :dt => 'PovRay plugin',
      :dd => 'You can embed ray tracing rendered 3D CG.',
      :dc => "* Example
 {{povray
 union{sphere{z*9-1,2}plane{y,-3}finish{reflection{,1}}}background{1+z/9}
 }}
{{povray
union{sphere{z*9-1,2}plane{y,-3}finish{reflection{,1}}}background{1+z/9}
}}
This sample is excerpt from [[POVRay Short Code Contest, Round 3|http://astronomy.swin.edu.au/~pbourke/raytracing/scc3/final/]].
"
    }

    D_PluginPovray_ja = {
      :dt => 'PovRayプラグイン',
      :dd => 'レイトレーシングによる3D CGを埋め込めます。',
      :dc => '* 例
 {{povray
 union{sphere{z*9-1,2}plane{y,-3}finish{reflection{,1}}}background{1+z/9}
 }}
{{povray
union{sphere{z*9-1,2}plane{y,-3}finish{reflection{,1}}}background{1+z/9}
}}
このサンプルは、[[POVRay Short Code Contest, Round 3|http://astronomy.swin.edu.au/~pbourke/raytracing/scc3/final/]]からの引用です。
'
    }

    POVRAY_CMD = '/usr/bin/povray'
    MV_CMD = '/bin/mv'
    MIN_COLS = 50
    MIN_ROWS = 7
    MAX_COLS = 100
    MAX_ROWS = 50
    def plg_povray
      # Generate a povray file.
      content = ''
      content = yield if block_given?
      pngfilename = povray_generate(content)

      # @povray_num is global for an action.
      @povray_num = 0 if ! defined?(@povray_num)
      @povray_num += 1
      action = "#{@req.base}.#{@povray_num}.povray"

      cols = 0
      rows = 1
      content.each_line {|line|
	len = line.chomp.length
	cols = len if cols < len
	rows += 1
      }
      cols = MIN_COLS if cols < MIN_COLS
      rows = MIN_ROWS if rows < MIN_ROWS
      cols = MAX_COLS if MAX_COLS < cols
      rows = MAX_ROWS if MAX_ROWS < rows

      return [:div, {:class=>'povray'},
	[:img, {:src=>"#{@req.base}.files/#{pngfilename}"}],
	[:br],
	[:form, {:method=>'POST', :action=>action},
	  [:textarea, {:name=>'t', :cols=>cols, :rows=>rows}, content],
	  [:br],
	  [:input, {:type=>'submit', :value=>_('Update')}]]]
    end

    def povray_generate(content)
      files = @site.files(@req.base)
      base = content.md5hex
      filename = "#{base}.pov"
      pngfilename = "#{base}.png"
      return pngfilename if files.exist?(filename)

      files.overwrite(filename, content)
      # Render it background.
      t = Thread.new {
	path = files.path(filename)
	pngpath = files.path(pngfilename)
	pngtmppath = "/tmp/#{pngfilename}"
	system "#{POVRAY_CMD} #{path} -O#{pngtmppath}"
	system "#{MV_CMD} #{pngtmppath} #{pngpath}"
      }
      return pngfilename
    end

    def ext_povray
      c_require_post
      c_require_page_exist

      num = @req.ext_args[0].to_i
      return c_nerror(_('Error')) if num < 1

      text = @req.query['t']
      return c_nerror(_('No text')) if text.nil? || text.empty?
      text = text.normalize_newline

      begin
	plugin_edit(:povray, num) {|content|
	  text
	}
      rescue NoCorrespondingPlugin
	return c_nerror(_('Failed'))
      rescue PageCollisionError
	return mcomment_error(_('Page collision detected.'))
      end

      c_make_log('povray')	# TEXTAREA

      url = "#{@req.base}.html"
      return c_notice(_('Edit text done.'), url){
	[[:h2, _('Edit text done.')],
	  [:p, [:a, {:href=>url}, _('Go back')]]]
      }
    end

  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActPovray < Test::Unit::TestCase
    include TestSession

    def test_all
      t_add_user

      page = @site.create_new
      page.store('{{povray
union{sphere{z*9-1,2}plane{y,-3}finish{reflection{,1}}}background{1+z/9}
}}')

      res = session('/test/1.html')
      ok_xp [:div, {:class=>"takahashi"},
 [:iframe, {:src=>"1.files/takahashi.html",
   :style=>"width:700px;height:400px;border:0;"},
  ""],
 [:br],
 [:div, {:style=>"margin: 0 0 1em 0;"},
  [:a, {:href=>"1.files/takahashi.html", :style=>"font-size:x-small;"},
   "Show in fullscreen."]]],
	    "//div[@class='povray']"

      files = @site.files('1')
      ok_eq(true, files.exist?('T_method_module.swf'))
      ok_eq(true, files.exist?('textData.txt'))
      ok_eq("a", files.get('textData.txt'))
      ok_eq(true, files.exist?('takahashi.html'))
    end
  end
end
