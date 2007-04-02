# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

require 'benchmark'
require 'optparse'
require 'fileutils'

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/bench-module-session'
require 'qwik/test-common'

$test = true

class QwikBench
  include TestSession

  DefaultConfig = {
    :sitename	=> 'www',
    :path	=> nil,
    :repeat	=> 1,
  }

  def nu_copy_all(sitename)
    src  = @org_sites_dir.path + sitename
    return nil unless src.exist?
    dest = @dir

    pages = []
    src.each_entry {|file|
      if /\A.+\.txt\z/ =~ file.to_s
	srcfile = src+file
	str = srcfile.read
	mtime = srcfile.mtime

	destfile = dest+file
	destfile.put(str)
	destfile.utime(mtime, mtime)

	pages << file.to_s.sub(/\.txt\z/, "")
      end
    }
    return pages
  end

  def get_pages(src)
    pages = []
    src.each_entry {|file|
      if /\A(.+)\.txt\z/ =~ file.to_s
	#pages << file.to_s.sub(/\.txt\z/, "")
	pages << $1
      end
    }
    return pages
  end

  def copy_all(sitename)
    src  = @org_sites_dir.path + sitename
    return nil unless src.exist?

    dest = @dir
    dest.rmtree if dest.exist?
    dest.rmdir if dest.exist?

    puts 'start copy.'
    if File.exist?('/bin/cp')
      system "/bin/cp -a #{src} #{dest}"
    else
      FileUtils.cp_r(src.to_s, dest.to_s)
    end
    puts 'copy done.'

    return get_pages(src)
  end

  def bench(config)
    sitename = config[:sitename]
    path = config[:path]
    repeat = config[:repeat]
    pages = copy_all(sitename)

    if pages.nil?
      puts 'Error: No such site.'
      return 
    end

    puts "=" * 70
    puts "sitename: #{sitename}"
    puts "pagenum: #{pages.length}"
    puts "path: #{path}" if path
    puts "repeat: #{repeat}"
    puts

    bench_result = Benchmark.measure {
      t_add_user
      repeat.times {
	if path
	  res = session(path)
	  dummy = res.body.format_xml
	else
	  pages.each {|base|
	    res = session("/test/#{base}.html")
	    dummy = res.body.format_xml
	  }
	end
      }
    }

    puts Benchmark::CAPTION
    puts bench_result
    puts "=" * 70
  end

  def run(config)
    setup
    bench(config)
    #teardown
  end

  def self.main(argv)
    config = {}
    config.update(DefaultConfig)
    config.update(parse_args(argv))
    qb = QwikBench.new
    qb.run(config)
  end

  def self.parse_args(argv)
    config = {}
    optionparser = OptionParser.new {|opts|
      opts.banner = "Usage: qwik-bench [options]"
      opts.separator ''
      opts.separator 'Specific options:'
      opts.on('-c', '--copy',
	      'Copy directory first.') {|a|
	config[:copy] = a
      }
      opts.on('-s', '--sitename sitename', 'Specify your sitename.') {|a|
	config[:sitename] = a
      }
      opts.on('-p', '--path path', 'Specify path.') {|a|
	config[:path] = a
      }
      opts.on('-r', '--repeat 100', OptionParser::DecimalInteger,
	      'Repeat times.') {|a|
	config[:repeat] = a
      }
      opts.separator ''
      opts.separator 'Common options:'
      opts.on_tail('-h', '--help', 'Show this message') {
	puts opts
	exit
      }
    }
    optionparser.parse!(argv)
    return config
  end
end

if $0 == __FILE__
  if ARGV[0] == '-b'
    AB_PATH = "/usr/sbin/ab"
    def main
      url = "http://127.0.0.1:9190/"
      requests = 1000
      concurrency = 100
      cmd = "#{AB_PATH} -n #{requests} -c #{concurrency} #{url}"
      puts cmd
      system cmd
    end
    main
  else
    QwikBench.main(ARGV)
  end
end
