# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

require 'optparse'
require 'time'
require 'fileutils'
include FileUtils

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/config'
require 'qwik/util-time'
require 'qwik/util-pathname'

module Qwik
  class MakeRelease
    LIBDIR = File.dirname(__FILE__)

    def self.main(argv)
      type = MakeRelease.parse_args(argv)

      config = Config.new
      libdir = LIBDIR
      date = Time.now.ymd_s
      version = VERSION
      ml_version = QuickML::VERSION
      base = "qwik-#{version}"
      targz = "#{base}.tar.gz"
      upload_dest = 'eto.com:/var/www/2004/qwikWeb/'

      case type
      when :generate_version
	GenerateVersion.generate(libdir, version, ml_version, date)
      when :generate_manifest
	GenerateManifest.generate('.')
      when :generate_dist
	GenerateDist.generate(base, targz)
      when :upload
	Upload.upload(targz, upload_dest)
      end
    end

    def self.parse_args(args)
      type = nil
      optionparser = OptionParser.new {|opts|
	opts.banner = 'Usage: dev-release.rb [options]'
	opts.separator ''
	opts.separator 'Specific options:'
	opts.on('--generate-vesrion', 'Generate version file.') {|a|
	  type = :generate_version
	}
	opts.on('--generate-manifest', 'Generate MANIFEST file.') {|a|
	  type = :generate_manifest
	}
	opts.on('--generate-dist', 'Generate dist archive.') {|a|
	  type = :generate_dist
	}
	opts.on('--upload', 'Upload dist file.') {|a|
	  type = :upload
	}
	opts.separator ''
	opts.separator 'Common options:'
	opts.on_tail('-h', '--help', 'Show this message') {
	  puts opts
	  exit
	}
      }
      optionparser.parse!(args)

      if type.nil?
	puts 'To show usage, type like this

  % ruby dev-release.rb -h

'
	exit
      end
      return type
    end
  end

  class GenerateVersion
    def self.generate(libdir, version, ml_version, date)
      version_str = "# Automatically generated.
# DO NOT EDIT!

module Qwik
  VERSION = '#{version}'
  RELEASE_DATE = '#{date}'
end

module QuickML
  VERSION =  '#{ml_version}'
end
"
      "#{libdir}/version.rb".path.write(version_str)
    end
  end

  class GenerateManifest
    def self.generate(cwd)
      ar = []
      cwd.path.find {|f|
	ar << f.to_s if public_file?(f)
      }
      ar += %w(etc/ log/)

      open('MANIFEST', 'wb'){|out|
	ar.sort.each {|f|
	  out.puts f
	}
      }
    end

    IGNORE_DIR = %w(backup cache data etc grave log work .svn)
    IGNORE_PATTERN = %w(
CVS sfcring memo.txt tar.gz .rm .MP4 .cvsignore
.stackdump
.o
.so
testlog.txt
.#
#
qwik-0.
charts.swf
charts_library
.config
lib/qwik/dev-
.bak
)

#album.swf
#lib/qwik/mock-
#lib/qwik/test-

    def self.public_file?(file)
      return false if file.directory?
      s = file.to_s
      IGNORE_DIR.each {|dir|		# ignore dir
	return false if /^#{dir}/ =~ s
	return false if /\/#{dir}\// =~ s
      }
      IGNORE_PATTERN.each {|pat|	# ignore pattern
	return false if s.include?(pat)
      }
      return false if /~$/ =~ s
      return true
    end
  end

  class GenerateDist
    def self.generate(base, targz)
      opt = {}		# dummy
      files = open('MANIFEST'){|f| f.read }.split
      rm_rf(base, opt)
      rm_f(targz, opt)
      mkdir(base, opt)
      cp_all(files, base, opt)
      make_default_siteconfig(base)
      make_default_password(base)
      system_p("tar zcf #{targz} #{base}", opt)
      rm_rf(base, opt)
    end

    def self.cp_all(src, dest, opt={})
      src.each {|file|
	dir = File.dirname(file)
	dir = file.chop if file =~ /\/$/
	destdir = dest+'/'+dir
	mkdir_p(destdir, opt) unless FileTest.directory? destdir
	cp_p(file, destdir, opt) unless file =~ /\/$/
      }
    end

    def self.cp_p(src, dest, options={})
      opt = options.dup
      opt[:preserve] = true
      cp(src, dest, opt)
    end

    def self.system_p(cmd, options={})
      print "#{cmd}\n" if options[:verbose]
      return if options[:noop]
      system cmd
    end

    def self.make_default_siteconfig(base)
      Dir.mkdir(base+'/data') unless File.exist?(base+'/data')
      Dir.mkdir(base+'/data/www') unless File.exist?(base+'/data/www')
      open(base+'/data/www/_GroupForward.txt', 'wb'){|out|
	out.print "\n"
      }
      open(base+'/data/www/_SiteMember.txt', 'wb'){|out|
	out.print ",guest@qwik\n"
      }
      open(base+'/share/super/_SiteConfig.txt', 'rb'){|f|
	open(base+'/data/www/_SiteConfig.txt', 'wb'){|out|
	  while line = f.gets
	    line = line.sub(/:open:false/, ':open:true')
	    out.print line
	  end
	}
      }
    end

    def self.make_default_password(base)
      etc_copy_file(base, 'etc/config.txt')
      etc_copy_file(base, 'etc/config-debug.txt')
    end

    def self.etc_copy_file(base, file)
      str = read_file(file)
      write_file(base+'/'+file, str)
    end

    def self.read_file(file)
      open(file){|f| f.read }
    end

    def self.write_file(file, str)
      open(file, 'wb'){|f| f.print str }
    end
  end

  class Upload
    def self.upload(targz, upload_dest)
      opt = {}		# dummy
      GenerateDist.system_p("scp #{targz} #{upload_dest}", opt)
    end
  end
end

if $0 == __FILE__
  Qwik::MakeRelease.main(ARGV)
end
