# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/tokenizer'
require 'qwik/act-media'
require 'qwik/smil-time'

module Qwik
  class Action
    D_PluginSmil = {
      :dt => 'Video editing plugin',
      :dd => 'You can control the timeline of the video.',
      :dc => "* Example
** Tokyo Setagaya ward Congress
{{smil
:url:rtsp://realgi.city.setagaya.tokyo.jp/20030918-2.rm
|3:12:15|3:12:20|
|3:19:58|3:21:12|
}}
 {{smil
 :url:rtsp://realgi.city.setagaya.tokyo.jp/20030918-2.rm
 |3:12:15|3:12:20|
 |3:19:58|3:21:12|
 }}
This is just an example to use smil plugin.
"
    }

    def plg_smil(title=nil)
      @smil_num = 0 if !defined?(@smil_num)
      @smil_num += 1
      file = "#{@req.base}.#{@smil_num}.smil"
      str = yield
      title = file if title.nil?

      gen = SmilGenerator.new
      gen.parse(str)
      smil = gen.generate_smil
      smil_str = smil.format_xml.page_to_xml	# make it to utf8
      @site.files(@req.base).put(file, smil_str, true)	# override

      table = gen.generate_html

      div = [:div, {:class=>'smil'},
	table,
	[:p, [:a, {:href=>file}, file]]]

      return div
    end

    def plg_video(*args)
      name = @req.base
      name = args.shift if 0 < args.length
      msg = yield
      v = Video.new(@site, name)
      v.parse(msg)
      v.generate_file
      return v.to_xml
    end

    def ext_smil
    # $smil_debug = true
      $smil_debug = false
      ar = []
      ar << @req.base
      ar += @req.ext_args
      ar << @req.ext
      filename = ar.join('.')
      file = @site.files(@req.base).path(filename)
      if $smil_debug
	return c_notice(1) { "filename is #{filename}" }
      end

      return c_simple_send(file.to_s, 'application/smil')
    end
  end

  class SmilGenerator
    def initialize
      @width, @height = 320, 240
      @time_table = []
    end

    def parse(str)
      url = nil
      @width, @height = 320, 240
      @time_table = []
      tokens = tokenize(str)
      tokens.each {|token|
	case token[0]
	when :dl
	  case token[1]
	  when 'url'    then url     = token[2]
	  when 'width'  then @width  = token[2]
	  when 'height' then @height = token[2]
	  else
	    raise 'unknown param type'
	  end
	when :table
	  time_begin = SmilTime.at_smil(token[1])
	  time_end   = SmilTime.at_smil(token[2])
	  title = token[3]
	  @time_table << [url, time_begin, time_end, title]
	else
	  raise 'unknown type'
	end
      }
      return [@width, @height, @time_table] # only for test
    end

    def tokenize(str)
      return TextTokenizer.tokenize(str)
    end

    def generate_smil
      time = 0.0
      par = []
      @time_table.each {|url, time_begin, time_end, title|
	duration = time_end.to_f - time_begin.to_f
	par << [:video, {:region=>'v', :begin=>"#{time}s",
	    :src=>url, :'clip-begin'=>time_begin.to_smil,
	    :'clip-end'=>time_end.to_smil}]
	time += duration
      }
      smil = [:smil, {:xmlns=>'http://www.w3.org/2001/SMIL20/Language',
	  :'xmlns:rn'=>'http://features.real.com/2001/SMIL20/Extensions'},
	[:head,
	  [:layout,
	    [:'root-layout', {:width=>@width, :height=>@height}],
	    [:region, {:id=>'v', :fit=>'meet'}]]],
	[:body, [:par, *par]]]
      return smil
    end

    def generate_html
      table = [:table]
      table << [:tr,
	[:th, 'IN'],
	[:th, 'OUT'],
	[:th, 'MSG']
      ]
      @time_table.each {|url, time_begin, time_end, title|
	table << [:tr, 
	  [:td, time_begin.to_smil],
	  [:td, time_end.to_smil],
	  [:td, title]]
      }
      return table
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  require 'qwik/testunit'
  $test = true
end

if defined?($test) && $test
  class TestActSmil < Test::Unit::TestCase
    include TestSession

    def test_plg_video
      t_add_user
      page = @site.create_new
      page.put('{{smil
:url:rtsp://example.com/test/1.files/t.rm
,00,05.05,msg1
,12:10,12:15.15,msg2
}}')
      res = session('/test/1.html')
      ok_in([:div, {:class=>'smil'},
	      [:table,
		[:tr, [:th, 'IN'], [:th, 'OUT'], [:th, 'MSG']],
		[:tr, [:td, '00:00:00'], [:td, '00:00:05.05'],
		  [:td, 'msg1']],
		[:tr, [:td, '00:12:10'], [:td, '00:12:15.15'],
		  [:td, 'msg2']]],
	      [:p, [:a, {:href=>'1.1.smil'}, '1.1.smil']]],
	    '//div[@class="section"]')

      path = @site.files('1').path('1.1.smil')
      str = path.read
      assert(str.include?('http://www.w3.org/2001/SMIL20/Language'))

      res = session('/test/1.1.smil') # get the file
      str = res.body
      assert(str.include?('http://www.w3.org/2001/SMIL20/Language'))
      ok_eq('application/smil', res['Content-Type'])
    end

    def test_media_plugin
      ok_wi([:div, {:class=>'box'},
	      [:table, [:tr, [:td, 'IN'], [:td, 'OUT'], [:td, 'MSG']]],
	      [:p, [:a, {:href=>'.attach/1.smil'}, '1']]],
	    "{{video\n,k,v\n}}")

      t_add_user
      res = session('/test/.attach/1.smil') # get a file
      str = res.body
      ok_eq('application/smil', res['Content-Type'])

      # test real situation
      ok_wi([:div, {:class=>'box'},
	      [:table,
		[:tr, [:td, 'IN'], [:td, 'OUT'], [:td, 'MSG']],
		[:tr, [:td, '00:03'], [:td, '00:13']],
		[:tr, [:td, '00:20'], [:td, '00:28']]],
	      [:p, [:a, {:href=>'.attach/TestSmil.smil'}, 'TestSmil']]],
	    '{{video(TestSmil)
:width:160
:height:120
:url:rtsp://stream.nhk.or.jp/news/20030914000046002.rm
,00:03,00:13,
,00:20,00:28,
}}')
      res = session('/test/.attach/TestSmil.smil')

      # test real situation
      ok_wi([:div, {:class=>'box'},
	      [:table,
		[:tr, [:td, 'IN'], [:td, 'OUT'], [:td, 'MSG']],
		[:tr, [:td, '00:03'], [:td, '00:13'], [:td, '‚ ']],
		[:tr, [:td, '00:20'], [:td, '00:28']]],
	      [:p, [:a, {:href=>'.attach/TestSmil.smil'}, 'TestSmil']]],
	    '{{video(TestSmil)
:width:160
:height:120
:url:rtsp://stream.nhk.or.jp/news/20030914000046002.rm
,00:03,00:13,‚ 
,00:20,00:28,
}}')
      res = session('/test/.attach/TestSmil.smil')
      str = res.body
      assert(str.include?('http://www.w3.org/2001/SMIL20/Language'))
    end
  end

  class TestSmil < Test::Unit::TestCase
    def test_smil_generator
      gen = Qwik::SmilGenerator.new

      str = ':url:rtsp://example.com/test/1.files/t.rm
,00,05.05,msg1
,12:10,12:15.15,msg2'

      # test_tokenize
      tokens = gen.tokenize(str)
      ok_eq([[:dl, 'url', 'rtsp://example.com/test/1.files/t.rm'],
	      [:table, '00', '05.05', 'msg1'],
	      [:table, '12:10', '12:15.15', 'msg2']], tokens)

      # test parse
      width, height, time_table = gen.parse(str)
      ok_eq(320, width)
      ok_eq(240, height)
      ok_eq([['rtsp://example.com/test/1.files/t.rm',
		Qwik::SmilTime.at_smil('00'),
		Qwik::SmilTime.at_smil('05.05'), 'msg1'],
	      ['rtsp://example.com/test/1.files/t.rm',
		Qwik::SmilTime.at_smil('12:10'),
		Qwik::SmilTime.at_smil('12:15.15'),'msg2']],
	    time_table)

      # test generate_smil
      w = gen.generate_smil
      ok_eq([:head, [:layout,
		[:'root-layout', {:height=>240, :width=>320}],
		[:region, {:id=>'v', :fit=>'meet'}]]],
	    w.get_path('//head'))
      ok_eq([:video,
	      {:'clip-end'=>'00:00:05.05',
		:begin=>'0.0s',
		:region=>'v',
		:src=>'rtsp://example.com/test/1.files/t.rm',
		:'clip-begin'=>'00:00:00'}],
	    w.get_path('//video'))
      ok_eq([:video,
	      {:'clip-end'=>'00:12:15.15',
		:begin=>'5.166666s',
		:region=>'v',
		:src=>'rtsp://example.com/test/1.files/t.rm',
		:'clip-begin'=>'00:12:10'}],
	    w.get_path('//video[2]'))

      # test generate_html
      w = gen.generate_html
      ok_eq([:table,
	      [:tr, [:th, 'IN'], [:th, 'OUT'], [:th, 'MSG']],
	      [:tr, [:td, '00:00:00'], [:td, '00:00:05.05'],
		[:td, 'msg1']],
	      [:tr, [:td, '00:12:10'], [:td, '00:12:15.15'],
		[:td, 'msg2']]],
	    w)
    end
  end
end
