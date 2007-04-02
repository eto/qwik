# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

require 'stringio'

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/wabisabi-generator'
require 'qwik/act-smil'

module Qwik
  class Action
    def act_media_server
      ms = MediaServer.new(@config)

      if 0 < @req.path_args.length	# has target file
	filename = @req.path_args.shift
	file = filename.path

	if @req.query['delete'] == 'yes'
	  output = ms.output_file(@site, file)
	  return c_nerror("already deleted: #{file.to_s}") unless output.exist?
	  output.unlink
	  return c_notice("delete content: #{file.to_s}"){}
	end

	if filename == 'all'
	  each_media_entry {|f|
	    file = f.basename
	    f = @site.attach.path(file)
	    next unless f.exist?
	    ms.publish_file(@site, f)
	  }
	  return c_notice('publish all')
	end

	f = @site.attach.path(filename)
	return c_notfound('File not found.') unless f.exist?
	ms.publish_file(@site, f)
	return c_notice("pulish the content: #{file.to_s}")
      end

      ul = []
      each_media_entry {|f|
	file = f.basename
	ar = []
	ar << [:a, {:href=>c_relative_to_root(".media_server/#{file}")},
	  file.to_s]
	output = ms.output_file(@site, file)
	if output.exist?
	  outbase = output.basename.to_s
	  uri = URI(@config.public_url)
	  url = "rtsp://#{uri.host}:554/#{uri.path}#{@site.sitename}/#{outbase}"
	  ar << ' [' << [:a, {:href=>url}, outbase] << '] '
	  url = [:a, {:href=>c_relative_to_root(".media_server/#{file}?delete=yes")}, 'delete']
	  ar << url
	end
	ul << [:li, ar]
      }

      if 0 < ul.length
	ul << [:li, [:a, {:href=>c_relative_to_root('.media_server/all')},
	    'publish all']]
      end

      return c_notice('media server') {[:ul, ul]}
    end

    def each_media_entry
      path = @site.attach.path('')
      path.each_entry {|file|
	base = file.to_s
	next unless /\A(.+)\.rm\z/i =~ base
	yield(path+file)
      }
    end

    def each_movie_entry
      path = @site.attach.path
      path.each_entry {|file|
	base = file.to_s
	next unless /\A(.+)\.avi\z/i =~ base || /\A(.+)\.mp4\z/i =~ base
	yield(path+file)
      }
    end

    def act_encode
      rp = RealProducer.new(@config, @site)
      if 0 < @req.path_args.length	# has target file
	filename = @req.path_args.shift

	if filename == 'all'
	  t = Thread.new {
	    each_movie_entry {|f|
	      file = f.basename
	      f = @site.attach.path(file)
	      next unless f.exist?
	      output = rp.output_file(file)
	      output.dirname.check_directory
	      next if output.exist?
	      msg = StringIO.new
	      rp.encode_file(f, output, msg)
	      puts 'done', msg.string
	    }
	  }
	  return c_notice('start encoding all')
	end

	file = filename.path
	f = @site.attach.path(filename)
	return c_notfound('File not found.') unless f.exist?
	output = rp.output_file(file)
	msg = StringIO.new
	t = Thread.new {
	  rp.encode_file(f, output, msg)
	}
	return c_notice("start encoding: #{file.to_s}")
      end

      ul = []
      each_movie_entry {|f|
	file = f.basename
	ar = []
	ar << [:a, {:href=>c_relative_to_root(".encode/#{file}")},
	  file.to_s]
	output = rp.output_file(file)
	if output.exist?
	  outbase = output.basename.to_s
	  uri = URI(@config.public_url)
	  url = "rtsp://#{uri.host}:554/#{rpath}#{@site.sitename}/#{outbase}"
	  ar += [' [', [:a, {:href=>url}, outbase], ']']
	end
	ul << [:li, ar]
      }

      if 0 < ul.length
	ul << [:li, [:a, {:href=>c_relative_to_root('.encode/all')},
	    'encode all']]
      end

      return c_notice('movie file list') { [:ul, ul] }
    end
  end

  class MediaServer
    def initialize(config)
      @config = config
    end

    def output_file(site, input)
      path = @config.real_server_content.path+site.sitename
      base = input.basename.to_s
      base = base.sub(%r!\A(.+)\.(\w+)!){|a| $1 }
      outbase = base+'.rm'
      output = path+outbase
      output
    end

    def windows?
      r = RUBY_PLATFORM
      return (r.index('cygwin') || r.index('mswin32') || r.index('mingw32'))
    end

    def publish_file(site, input)
      output = output_file(site, input)
      output.dirname.check_directory
      if windows?
	FileUtils.cp(input, output)
      else
	FileUtils.ln(input, output)
      end
    end
  end

  class RealProducer
    def initialize(config, site)
      @config = config
      @site = site
      @cmd = @config.real_producer
      @audience = '768k'
      @real_server_content_dir = @config.real_server_content
      @o = ($VERBOSE) ? $stdout : StringIO.new
    end
    attr_reader :real_server_content_dir

    def output_file(input)
      path = @real_server_content_dir.path+@site.sitename
      base = input.basename.to_s
      base = base.sub(%r!\A(.+)\.(\w+)!){|a| $1 }
      outbase = "#{base}.rm"
      output = path+outbase
      output
    end

    def encode_all
      path = @site.attach.path
      path.each_entry {|file|
	base = file.basename.to_s
	next unless /\A(.+)\.avi\z/i =~ base || /\A(.+)\.mp4\z/i =~ base
	output_base = $1+'.rm'
	output = path+output_base
	if output.exist?
	  puts "already exist: #{output.to_s}"
	  next
	end
	encode_file(path+file)
      }
    end

    def encode_file(input, output, msg=nil)
      m = msg ? msg : @o
      inf  =  input.to_win_dir
      outf = output.to_win_dir
      m.puts "start encode #{inf}"
      open("|#{@cmd} -i #{inf} -o #{outf} -ad #{@audience}"){|f|
	while line = f.gets
	  m.print line.normalize_eol
	end
      }
      m.puts
    end

    def show_version
      @o.puts(open("|#{@cmd} -pa"){|f| f.read })
    end

    def show_help
      @o.puts(open("|#{@cmd} -h"){|f| f.read })
    end

    def show_more_help
      @o.puts(open("|#{@cmd} -m"){|f| f.read })
    end

    def show_audience_list
      @o.puts(open("|#{@cmd} -pa"){|f| f.read })
    end
  end

  class Media
    def initialize(site, name)
      @site = site
      @table = []
      @msg = nil
      @name = name
      @param = {}
      @param[:url] = nil
      @param[:width]  = 320 # default
      @param[:height] = 240
      @hash_delim = [':']
      @table_delim = ['|', ',']
    end

    def parse(msg)
      @msg = msg
      lines = msg.split(/\n/)
      lines.each {|line|
	firstchar = line[0, 1]
	if @table_delim.include?(firstchar)
	  ar = line.split(firstchar)
	  ar.shift # null
	  cbegin = cend = msg = nil
	  cbegin = VideoTime.new(ar.shift) if ! ar.empty?
	  cend   = VideoTime.new(ar.shift) if ! ar.empty?
	  msg = ar.shift if ! ar.empty?
	  if @param[:url] && cbegin && cend
	    @table << {:url=>@param[:url],
	      :cbegin=>cbegin, :cend=>cend, :msg=>msg}
	  end
	  next
	end
	if @hash_delim.include?(firstchar)
	  ar = line.split(firstchar, 3)
	  ar.shift # null
	  name = ar.shift if ! ar.empty?
	  @param[name.intern] = ar.shift if ! ar.empty?
	end
      }
    end

    def generate_file
      smil = make_smil.format_xml.page_to_xml
      @site.attach.put(@name+'.smil', smil, true)
    end

    def make_smil
      g = Generator.new
      time = 0
      par = []
      @table.each {|tab|
	dur = (tab[:cend] - tab[:cbegin]).to_i
	
	ar = [{'region'=>'v'}, {'begin'=>"#{time}s"}, {'src'=>tab[:url]}]
	ar << {'clip-begin'=>tab[:cbegin]} if tab[:cbegin]
	ar << {'clip-end'=>tab[:cend]} if tab[:cend]
	par << g.video(ar)
	time += dur
      }

      g.smil(:xmlns=>'http://www.w3.org/2001/SMIL20/Language',
	     'xmlns:rn'=>'http://features.real.com/2001/SMIL20/Extensions'){[
	  g.head{
	    g.layout{[
		g.make('root-layout',
		       {'width'=>@param[:width]}, {'height'=>@param[:height]}),
		g.region({'id'=>'v'}, {'fit'=>'meet'}),
	      ]}
	  },
	  g.body{
	    g.par{par}
	  }
	]}
    end

    def to_xml
      table = []
      table << [:tr,
	[:td, 'IN'],
	[:td, 'OUT'],
	[:td, 'MSG']
      ]
      @table.each {|tab|
	tr = []
	tr << [:td, tab[:cbegin].to_s]
	tr << [:td, tab[:cend].to_s]
	tr << [:td, tab[:msg].to_s] if tab[:msg]
	table << [:tr, *tr]
      }
      [:div, {:class=>'box'},
	[:table, *table],
	[:p, [:a, {:href=>".attach/#{@name}.smil"}, @name]]]
    end
  end

  class Video < Media
  end

  class VideoTime
    def initialize(arg=0)
      @sec = @min = @hour = 0
      @str = nil
      if arg.kind_of? String
	@str = arg
	ar = @str.split(/:/)
	@sec = ar.pop
	@min = ar.pop
	@hour = ar.empty? ? 0 : ar.pop
      end
      # start 2000/01/01 00:00
      @t = Time.gm(2000, 1, 1, @hour, @min, @sec, 0)
    end
    attr_reader :t

    def -(v)
      @t-v.t
    end

    def +(v)
      return @t+v if v.kind_of? Numeric
      @t+v.t
    end

    def to_s
      return @str if @str
    end
    alias inspect to_s
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActMedia < Test::Unit::TestCase
    include TestSession

    def test_act_media_server
      t_add_user
      res = session('/test/.media_server')
      ok_title('media server')
    end

    def copy_sample_file
      path = @org_sites_dir.path+'eto/.attach'
      f = path+'sample.avi'
      FileUtils.cp(f.to_s, @site.attach.path)
    end

    def nutest_act_encode
      copy_sample_file

      t_add_user
      res = session('/test/.encode')
      ok_title('movie file list')

      res = session('/test/.encode/nosuchfile.avi')
      ok_title('File not found.')

      res = session('/test/.encode/sample.avi')
      ok_title('start encoding: sample.avi')
    end

    def nutest_encode
      copy_sample_file
      rp = Qwik::RealProducer.new(@site)
      rp.encode_all
    end
  end

  class TestMedia < Test::Unit::TestCase
    def test_all
    end
  end
end
