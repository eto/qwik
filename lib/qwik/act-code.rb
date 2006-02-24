begin
  require 'GD'
  $have_gd = true
rescue LoadError
  $have_gd = false
end

module Qwik
  class Action
    D_plugin_code = {
      :dt => 'Code input plugin',
      :dd => 'You can input code on the page.',
      :dc => "* Examples
 {{code
 puts \"hello, world!\"
 puts \"hello, qwik users!\"
 }}
{{code
puts \"hello, world!\"
puts \"hello, qwik users!\"
}}
{{code
\#include <stdio.h>

void main(){
  printf(\"hello, world!\\n\");
}
}}
"
    }

    Dja_plugin_code = {
      :dt => 'コード・プラグイン',
      :dd => 'ページ中にコードをうめこむときに使えます。',
      :dc => "* 例
 {{code
 puts \"hello, world!\"
 puts \"hello, qwik users!\"
 }}
{{code
puts \"hello, world!\"
puts \"hello, qwik users!\"
}}
{{code
\#include <stdio.h>

void main(){
  printf(\"hello, world!\\n\");
}
}}
"
    }

    def plg_code(filename=nil)
      content = ''
      content = yield if block_given?
      pre = [:pre]
      content.each_with_index {|line, index|
	line.chomp!
	linenum = index + 1
	klass = 'line '
	klass += if linenum % 2 == 0 then 'even' else 'odd' end
	style = "background-image: url(.num/#{linenum}.png);"
	pre << [:span, {:class=>klass, :style=>style}, line]
	pre << "\n"
      }
      return [:div, {:class=>'code'}, pre]
    end

    def act_num
      return c_nerror(_('Error')) if ! $have_gd
      args = @req.path_args
      return c_nerror(_('Error')) if args.nil? || args.empty?
      filename = args.first
      return c_nerror(_('Error')) unless /\A([0-9]+)\.png\z/ =~ filename
      str = $1
      return c_nerror(_('Error')) if 10 < str.length
      files = @site.files('FrontPage')
      if ! files.exist?(filename)
	png = Action.generate_png(str)
	files.put(filename, png)
      end
      path = files.path(filename)
      return c_simple_send(path, 'image/png')
    end

    def self.generate_png(str)
      return nil if ! $have_gd
      font, fw, fh = GD::Font::TinyFont, 5, 8
      str = str.to_s
      width = fw * str.length
      height = fh
      img = GD::Image.new(width, height)
      white = img.colorAllocate(255, 255, 255)
      color = img.colorAllocate(127, 127, 127)
      img.transparent(white)
      img.string(font, 0, 0, str, color)
      return img.pngStr
    end
  end
end

if $0 == __FILE__
  $LOAD_PATH << '..' unless $LOAD_PATH.include? '..'
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActCode < Test::Unit::TestCase
    include TestSession

    def test_code
      res = session
      ok_wi [:div, {:class=>"code"},
	[:pre, [:span,
	    {:style=>"background-image: url(.num/1.png);", :class=>"line odd"},
	    "t"],
	  "\n"]],
	"{{code\nt\n}}"
    end

    def test_num
      t_add_user

      res = session('/test/.num/1.png')
      eq 'image/png', res['Content-Type']
      str = res.body
      eq "\211PNG\r\n\032\n\000\000\000\rIHDR\000\000\000\005\000\000\000\010\001\003\000\000\000\v?\247x\000\000\000\006PLTE\377\377\377\177\177\177br\365\207\000\000\000\001tRNS\000@\346\330f\000\000\000\024IDAT\010\231c``P`H\000b\020,``\000\000\t\300\001Q2\2179L\000\000\000\000IEND\256B`\202", str

      res = session('/test/.num/1234567890.png')
      str = res.body
      eq "\211PNG\r\n\032\n\000\000\000\rIHDR\000\000\0002\000\000\000\010\001\003\000\000\000\201\020>9\000\000\000\006PLTE\377\377\377\177\177\177br\365\207\000\000\000\001tRNS\000@\346\330f\000\000\000=IDAT\010\231c`\200\002e\t\177\3433\211\f\f)KN8\004Mj`P\350\364\v\350\331\324\300\240\310\3720cRP\003\203\222\212\247\247\220P\003C\371\f7C\236D\230.\006\000\352y\016\246.\260\314\346\000\000\000\000IEND\256B`\202", str
    end

    def test_generate_png
      return if $0 != __FILE__		# Only for separated test.
      png = Qwik::Action.generate_png(1234567890)
      # 'tmp.png'.path.write(png)
      eq "\211PNG\r\n\032\n\000\000\000\rIHDR\000\000\0002\000\000\000\010\001\003\000\000\000\201\020>9\000\000\000\006PLTE\377\377\377\177\177\177br\365\207\000\000\000\001tRNS\000@\346\330f\000\000\000=IDAT\010\231c`\200\002e\t\177\3433\211\f\f)KN8\004Mj`P\350\364\v\350\331\324\300\240\310\3720cRP\003\203\222\212\247\247\220P\003C\371\f7C\236D\230.\006\000\352y\016\246.\260\314\346\000\000\000\000IEND\256B`\202", png
    end
  end
end
