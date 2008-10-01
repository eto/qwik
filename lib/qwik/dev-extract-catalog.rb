#! /usr/bin/ruby
# Copyright (C) 2003-2008 AIST, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

# Description:
# Read catalog-ja.rb and catarog-ml-ja.rb, output flat text file.
#   argument: path to lib/qwik
#   output: "catalog-ja.txt", "catalog-ml.txt" (on current directory)

require 'pathname'
require 'stringio'
$KCODE = 'SJIS'

if ARGV.length < 1
  warn "ruby #{$0} path/to/lib/qwik"
  exit(1)
end

def die(msg)
  warn msg
  exit(1)
end

libpath = Pathname.new(ARGV[0])
catalog_ja = libpath + 'catalog-ja.rb'
catalog_ml_ja = libpath + 'catalog-ml-ja.rb'
die "#{catalog_ja} is not exist." unless catalog_ja.exist?
die "#{catalog_ml_ja} is not exist." unless catalog_ml_ja.exist?

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
end

def parse_file(input_path)
  out = ''
  input_path.open("r").each_line do |line|
    line.trim_line!
    case line
    when /^#/, /^:charset/, /^:codeconv_method/
      next
    when /^(.+)\s*=>$/
      k = $1
      k.trim_line!
      k.strip_metachar!
      out << k+"\n"
    when /^(.+)\s*=>\s+(.+)\s*,$/
      k = $1
      k.trim_line!
      k.strip_metachar!
      v = $2
      v.trim_line!
      v.strip_metachar!
      out << k+"\n"
      out << v+"\n"
      out << "\n"
    when /^(.+)\s*,$/
      v = $1
      v.trim_line!
      v.strip_metachar!
      out << v+"\n"
      out << "\n"
    end
  end
  return out
end

def process(output_path, input_path)
  input_path = Pathname.new input_path
  out = parse_file(input_path)

  output_path = Pathname.new output_path
  output_path.open("w") do |output|
    output.print out
  end
end

process("catalog-ja.txt", catalog_ja)
process("catalog-ml-ja.txt", catalog_ml_ja)
