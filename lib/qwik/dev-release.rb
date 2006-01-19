#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

require 'optparse'
require 'time'
require 'fileutils'
include FileUtils

$LOAD_PATH << '..' unless $LOAD_PATH.include?('..')
require 'qwik/config'
require 'qwik/util-time'
require 'qwik/util-pathname'

module Qwik
  class MakeRelease
    def self.main(argv)
      type = MakeRelease.parse_args(argv)

      config = Config.new
      libdir = config.qwiklib_dir
      date = Time.now.ymd_s
      version = VERSION
      ml_version = QuickML::VERSION
      base = "qwik-#{version}"
      targz = "#{base}.tar.gz"
      upload_dest = 'eto.com:/var/www/2004/qwikWeb/'

      case type
      when :generate_version
	MakeRelease.generate_version_file(libdir, version, ml_version, date)
      when :generate_manifest
	MakeRelease.generate_manifest_file('.')
      when :generate_dist
	MakeRelease.generate_dist_file(base, targz)
      when :upload
	MakeRelease.upload_tarball(targz, upload_dest)
      end
    end

    def self.parse_args(args)
      type = nil
      optionparser = OptionParser.new {|opts|
	opts.banner = 'Usage: dev-release.rb [options]'
	opts.separator ''
	opts.separator 'Specific options:'
	opts.on('-v', '--generate-vesrion', 'Generate version file.') {|a|
	  type = :generate_version
	}
	opts.on('-m', '--generate-manifest', 'Generate MANIFEST file.') {|a|
	  type = :generate_manifest
	}
	opts.on('-d', '--generate-dist', 'Generate dist archive.') {|a|
	  type = :generate_dist
	}
	opts.on('-u', '--upload', 'Upload dist file.') {|a|
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

    # ============================== version
    def self.generate_version_file(libdir, version, ml_version, date)
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
      (libdir+'/version.rb').path.write(version_str)
    end

    # ==============================
    def self.generate_manifest_file(cwd)
      ar = []
      cwd.path.find {|f|
	ar << f.to_s if MakeRelease.public_file?(f)
      }
      ar += %w(etc/ log/)

      open('MANIFEST', 'wb'){|out|
	ar.sort.each {|f|
	  out.puts f
	}
      }
    end

    IGNORE_DIR = %w(backup cache data etc grave log work)
    IGNORE_PATTERN = %w(
CVS sfcring memo.txt tar.gz .rm .MP4 .cvsignore
.stackdump
.o
.so
testlog.txt
.#
#
qwik-0.
album.swf
charts.swf
charts_library
)
    def self.public_file?(f)
      return false if f.directory?
      s = f.to_s
      IGNORE_DIR.each {|dir|		# ignore dir
	return false if s =~ /^#{dir}/
      }
      IGNORE_PATTERN.each {|pat|	# ignore pattern
	return false if s.include?(pat)
	return false if s.include?(pat)
      }
      return false if s =~ /~$/
      return true
    end

    # ==============================
    def self.generate_dist_file(base, targz)
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
     #etc_copy_file(base, 'etc/config-dist.txt')
      etc_copy_file(base, 'etc/config.txt')
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

    # ==============================
    def self.upload_tarball(targz, upload_dest)
      opt = {}		# dummy
      system_p("scp #{targz} #{upload_dest}", opt)
    end
  end
end

if $0 == __FILE__
  Qwik::MakeRelease.main(ARGV)
end
