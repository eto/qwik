begin
  require 'GD'
  $have_gd = true
rescue LoadError
  $have_gd = false
end

module Qwik
  class Action
    D_code = {
      :dt => 'Code input plugin',
      :dd => 'You can input code on the page.',
      :dc => "* Examples
** CSS
{{code
puts \"hello, world!\"
puts \"hello, qwik users!\"
}}
" }

    # http://co/qwik/code.describe
    def plg_code(lang=nil)
      content = ''
      content = yield if block_given?
      pre = [:pre]
      content.each_with_index {|line, num|
	line.chomp!
	linenum = num + 1
	klass = 'line '
	klass += if linenum % 2 == 0 then 'even' else 'odd' end
	pre << [:span, {:class=>klass, :style=>"background-image: url(.num/#{linenum}.png);"}, line]
	pre << "\n"
      }
      div = [:div, {:class=>'code'}, pre]
      return div
    end

    # http://co/qwik/.num/1.png
    # http://co/qwik/.num/1234567890.png
    def act_num
      args = @req.path_args
      return c_nerror(_('Error')) if args.nil? || args.empty?
      filename = args.first
      return c_nerror(_('Error')) unless /\A([0-9]+)\.png\z/ =~ filename
      num = $1
      return c_nerror(_('Error')) if 10 < num.length
      files = @site.files('FrontPage')
      if ! files.exist?(filename)
	png = Action.generate_number_png(num)
	files.put(filename, png)
      end
      path = files.path(filename)
      return c_simple_send(path.to_s, 'image/png')
    end

    def self.generate_number_png(num)
      font, fw, fh = GD::Font::TinyFont, 5, 8
      #font, fw, fh = GD::Font::SmallFont, 6, 12
      #font, fw, fh = GD::Font::MediumFont, 7, 14
      #font, fw, fh = GD::Font::LargeFont, 8, 16
      #font, fw, fh = GD::Font::GiantFont, 8, 16
      num = num.to_s
      width = fw * num.length
      height = fh
      img = GD::Image.new(width, height)
      white = img.colorAllocate(255, 255, 255)
      color = img.colorAllocate(127, 127, 127)
      img.transparent(white)
      img.string(font, 0, 0, num, color)
      return img.pngStr
    end
  end
end

if $0 == __FILE__
  $LOAD_PATH << '..' unless $LOAD_PATH.include? '..'
  require 'qwik/test-common'
  require 'qwik/util-pathname'
  $test = true
end

if defined?($test) && $test
  class TestActCode < Test::Unit::TestCase
    include TestSession

    def test_code
      res = session
      ok_wi [:div,
 {:class=>"code"},
 [:pre,
  [:span,
   {:style=>"background-image: url(.num/1.png);", :class=>"line"},
   "t\n"]]],
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

    def test_generate_number_png
      return if $0 != __FILE__		# Only for separated test.
      png = Qwik::Action.generate_number_png(1234567890)
      # 'tmp.png'.path.write(png)
      eq "\211PNG\r\n\032\n\000\000\000\rIHDR\000\000\0002\000\000\000\010\001\003\000\000\000\201\020>9\000\000\000\006PLTE\377\377\377\177\177\177br\365\207\000\000\000\001tRNS\000@\346\330f\000\000\000=IDAT\010\231c`\200\002e\t\177\3433\211\f\f)KN8\004Mj`P\350\364\v\350\331\324\300\240\310\3720cRP\003\203\222\212\247\247\220P\003C\371\f7C\236D\230.\006\000\352y\016\246.\260\314\346\000\000\000\000IEND\256B`\202", png
    end
  end
end
