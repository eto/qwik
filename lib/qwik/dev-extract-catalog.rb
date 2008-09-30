#! /usr/bin/ruby
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

libpath = Pathname.new(ARGV[0])
catalog_ja = libpath + 'catalog-ja.rb'
catalog_ml_ja = libpath + 'catalog-ml-ja.rb'
unless catalog_ja.exist?
  warn "#{catalog_ja} is not exist."
  exit(1)
end
unless catalog_ml_ja.exist?
  warn "#{catalog_ml_ja} is not exist."
  exit(1)
end

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

def process(output_path, input_path)
  File.open(output_path, "w") do |output|
    File.open(input_path, "r").each_line do |line|
      line.trim_line!
      case line
      when /^#/, /^:charset/, /^:codeconv_method/
	next
      when /^(.+)\s*=>$/
	k = $1
	k.trim_line!
	k.strip_metachar!
	output.puts k
      when /^(.+)\s*=>\s+(.+)\s*,$/
	k = $1
	k.trim_line!
	k.strip_metachar!
	v = $2
	v.trim_line!
	v.strip_metachar!
	output.puts k, v, ''
      when /^(.+)\s*,$/
	v = $1
	v.trim_line!
	v.strip_metachar!
	output.puts v, ''
      end
    end
  end
end

process("catalog-ja.txt", catalog_ja)
process("catalog-ml-ja.txt", catalog_ml_ja)
