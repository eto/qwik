# -*- coding: shift_jis -*-
# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

require 'open3'

module Qwik
  class Action
    D_PluginPovray = {
      :dt => 'PovRay plugin',
      :dd => 'You can embed ray tracing rendered 3D CG.',
      :dc => "* Example
 {{povray
 sphere { <0, 0, 9>, 3
 finish { ambient 0.2 diffuse 0.8 phong 1 }
 pigment { red 1 }
 }
 light_source { <-9, 9, 0> rgb 1 }
 }}
{{povray
sphere { <0, 0, 9>, 3
finish { ambient 0.2 diffuse 0.8 phong 1 }
pigment { red 1 }
}
light_source { <-9, 9, 0> rgb 1 }
}}
- I recommend [[POVRay Short Code Contest, Round 3|http://astronomy.swin.edu.au/~pbourke/raytracing/scc3/final/]] for samples of POV-Ray source code.
"
    }

    D_PluginPovray_ja = {
      :dt => 'PovRayプラグイン',
      :dd => 'レイトレーシングによる3D CGを埋め込めます。',
      :dc => '* 例
 {{povray
 sphere { <0, 0, 9>, 3
 finish { ambient 0.2 diffuse 0.8 phong 1 }
 pigment { red 1 }
 }
 light_source { <-9, 9, 0> rgb 1 }
 }}
{{povray
sphere { <0, 0, 9>, 3
finish { ambient 0.2 diffuse 0.8 phong 1 }
pigment { red 1 }
}
light_source { <-9, 9, 0> rgb 1 }
}}
- [[POVRay Short Code Contest, Round 3|http://astronomy.swin.edu.au/~pbourke/raytracing/scc3/final/]]などのサンプルを見てみると面白いかもしれません。
'
    }

    MIN_COLS = 50
    MIN_ROWS = 7
    MAX_COLS = 100
    MAX_ROWS = 50
    def plg_povray
      if ! povray_exist?
	return [:div, {:class=>'povray'},
	  [:p, 'No povray command.']
	]
      end

      # Generate a povray file.
      content = ''
      content = yield if block_given?

      pngfilename, stapath = povray_generate(content)

      # @povray_num is global for an action.
      @povray_num = 0 if ! defined?(@povray_num)
      @povray_num += 1
      action = "#{@req.base}.#{@povray_num}.povray"

      cols = 0
      rows = 1	# Add an empty line.
      content.each_line {|line|
	len = line.chomp.length
	cols = len if cols < len
	rows += 1
      }
      cols = MIN_COLS if cols < MIN_COLS
      rows = MIN_ROWS if rows < MIN_ROWS
      cols = MAX_COLS if MAX_COLS < cols
      rows = MAX_ROWS if MAX_ROWS < rows

      status = [:div, {:class=>'status'}]
      begin
	sta = stapath.read
	st, et = sta.to_a
	status << [:p, 'Start : ', Time.at(st.to_i).ymdax] if st
	status << [:p, 'End : ', Time.at(et.to_i).ymdax] if et
	status << [:p, 'Past : ', Time.at(et.to_i).ymdax] if et
      rescue
	status << [:p, 'The rendering is started.']
      end

      div = [:div, {:class=>'povray'},
	[:img, {:src=>"#{@req.base}.files/#{pngfilename}"}],
	[:br],
	[:form, {:method=>'POST', :action=>action},
	  [:textarea, {:name=>'t', :cols=>cols, :rows=>rows}, content],
	  [:br],
	  [:input, {:type=>'submit', :value=>_('Update')}]],
	[:br],
	status]

      return div
    end

    POVRAY_CMD = '/usr/bin/povray'
#   POVRAY_CMD = '/usr/local/bin/povray'
    MV_CMD = '/bin/mv'
    def povray_exist?
      return POVRAY_CMD.path.exist?
    end

    def povray_generate(content)
      files = @site.files(@req.base)
      base = content.md5hex
      povfilename = "#{base}.pov"
      pngfilename = "#{base}.png"

      povpath = files.path(povfilename)
      pngpath = files.path(pngfilename)
      pngtmppath = "/tmp/#{pngfilename}"

      msgpath = files.path("#{base}.povmsg").path
      stapath = files.path("#{base}.povsta").path

      return pngfilename, stapath if stapath.exist?	# Already started.

      files.overwrite(povfilename, content)

      # Render it background.
      t = Thread.new {
	cmd = "#{POVRAY_CMD} #{povpath} -O#{pngtmppath}"
	#system cmd
	stapath.open('wb') {|sta|
	  sta.puts Time.now.to_i.to_s
	  msgpath.open('wb') {|msg|
	    Open3.popen3(cmd) {|stdin, stdout, stderr|
	      while line = stderr.gets
		msg.print line
	      end
	    }
	  }
	  sta.puts Time.now.to_i.to_s
	}
	system "#{MV_CMD} #{pngtmppath} #{pngpath}"
      }
      return pngfilename, stapath
    end

    def ext_povray
      c_require_post
      c_require_page_exist

      num = @req.ext_args[0].to_i
      return c_nerror(_('Error')) if num < 1

      text = @req.query['t']
      return c_nerror(_('No text.')) if text.nil? || text.empty?
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
      page.store '{{povray
sphere { <0, 0, 9>, 3
finish { ambient 0.2 diffuse 0.8 phong 1 }
pigment { red 1 }
}
light_source { <-9, 9, 0> rgb 1 }
}}'

      res = session

      return if ! @action.povray_exist?

      res = session '/test/1.html'
      ok_xp [:div, {:class=>"povray"},
 [:img, {:src=>"1.files/4c5c412765d503e22d83bd5fdd4a1c80.png"}], [:br],
 [:form, {:method=>"POST", :action=>"1.1.povray"},
  [:textarea, {:name=>"t", :cols=>50, :rows=>7},
   "sphere { <0, 0, 9>, 3\nfinish { ambient 0.2 diffuse 0.8 phong 1 }\npigment { red 1 }\n}\nlight_source { <-9, 9, 0> rgb 1 }\n"], [:br],
  [:input, {:type=>"submit", :value=>"Update"}]], [:br],
 [:div, {:class=>"status"}]],
	"//div[@class='povray']"

      files = @site.files('1')
      ok files.exist?('4c5c412765d503e22d83bd5fdd4a1c80.pov')
    end
  end
end
