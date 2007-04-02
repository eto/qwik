# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/util-path'

def die(msg)
  puts msg
  exit 1
end

def main
  #log = 'log'.path
  log = ARGV.shift
  die('Usage: dev-calctime log') if log.nil?
  
  log = log.path
  die('log not found.') if ! log.exist?

  content = log.open {|f| f.read }

  ar = []
  content.each_line {|line|
    line.chomp!
    if /(\([0-9\.]+\))\z/ =~ line
      time = $1
      time = time.sub(/\A\(/, '').sub(/\)\z/, '').to_f

      line = line.sub(/(\([0-9\.]+\))\z/, '')
      method, klass = line.split(/[\(\)]/)
      ar << [time, klass, method]
    end
  }

  newstr = ''
  ar.sort.reverse.each {|time, klass, method|
    if 0.1 < time
      line = "#{time}\t#{klass}\t#{method}\n"
      newstr << line
    end
  }

  if false
    'out'.path.open('wb') {|out|
      out.print newstr
    }
  else
    print newstr
  end
end
main
