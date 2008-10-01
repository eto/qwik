#! /usr/bin/ruby
# Copyright (C) 2003-2008 AIST, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

require 'pathname'
require 'pp'
require 'stringio'
$KCODE = 'SJIS'

class String
  def trim_line!
    self.chomp!
    self.gsub!(/\A\s*/, '')
    self.gsub!(/\s*\z/, '')
  end

  def strip_metachar!
    self.gsub!(/\\n/, '')
    self.gsub!(/\\"/, '"')
    self.sub!(/\A['"]/, '')
    self.sub!(/['"]\Z/, '')
  end

  def del!(regexp)
    self.gsub!(regexp) { '' }
  end
end

class ExtractCatalog
  def main
    mypath = Pathname.new(__FILE__)

    catalog_ja = mypath.parent + 'catalog-ja.rb'
    ar = parse(catalog_ja)
    outpath = Pathname.new '../../interfaces-web.txt'
    output(outpath, ar)

    catalog_ml_ja = mypath.parent + 'catalog-ml-ja.rb'
    ar = parse(catalog_ml_ja)
    outpath = Pathname.new '../../interfaces-ml.txt'
    output(outpath, ar)
  end

  def parse(path)
    str = path.read

    str2 = ''
    str.each_line {|line|
      line.trim_line!

      next if line.empty?

      case line
      when /^#/, /^module /, /^class /, /^def /, /^\{/, /^\}/, /^end$/,
	  /^:charset/, /^:codeconv/
	next
      end

      str2 << line
    }

    ar = []
    lines = str2.split(/['"],['"]/)
    lines.each {|line|
      e, j = line.split(/['"]\s*=>\s*['"]/)
      ar << [e, j]
    }

    return ar
  end

  def output(outpath, ar)
    outpath.open('w') {|out|
      ar.each {|e, j|
	next if e.nil?
	next if j.nil?

	e.del!(/\A'/)
	j.del!(/['"],\z/)
	e.del!(/\\n/)
	j.del!(/\\n/)

	e.gsub!(/\\\"/) { '"' }

	next if e.empty?
	next if j.empty?

	next if e == '->'
	next if e == '<-'
	next if j == '¨'
	next if j == '©'

	out.puts j
	out.puts e
	out.puts
      }
    }
  end
end

ExtractCatalog.new.main
