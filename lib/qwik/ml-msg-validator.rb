#
# Copyright (C) 2002-2004 Satoru Takabayashi <satoru@namazu.org> 
# Copyright (C) 2003-2006 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/ml-gettext'

module QuickML
  module GetText
    class MessageValidator
      def self.main(argv)
	if argv.length < 2
	  puts "Usage: ruby ml-msg-validator.rb <catalog> <source...>"
	  exit
	end

	catalog_file = argv.shift
	catalog = Catalog.new(catalog_file)

	ok = true
	argv.each {|source_file|
	  validator = MessageValidator.new(catalog, source_file)
	  validator.validate
	  ok = (ok and validator.ok?)
	}
	if ok then exit else exit(1) end
      end

      def initialize (catalog, source_filename)
	@catalog = catalog
	@source_filename  = source_filename
	@has_error = false
      end

      def read_file_with_numbering (filename)
	content = ''
	File.open(filename).each_with_index {|line, idx|
	  lineno = idx + 1
	  content << line.gsub(/\b_\(/, "_[#{lineno}](")
	}
	content
      end

      def collect_messages (content)
	messages = []
	while content.sub!(/\b_\[(\d+)\]\((".*?").*?\)/m, "")
	  lineno  = $1.to_i
	  message = eval($2)
	  messages.push([lineno, message]) 
	end
	messages
      end

      def validate
	@catalog or return
	content = read_file_with_numbering(@source_filename)
	messages = collect_messages(content)
	messages.each {|lineno, message|
	  translated_message = @catalog.messages[message]
	  if not translated_message
	    printf "%s:%d: %s\n", @source_filename, lineno, message.inspect
	    @has_error = true
	  elsif message.count('%') != translated_message.count('%')
	    printf "%s:%d: %s => # of %% mismatch.\n", 
	      @source_filename, lineno, message.inspect, translated_message
	    @has_error = true
	  end
	}
      end

      def ok?
	not @has_error
      end
    end
  end
end

if $0 == __FILE__
  QuickML::GetText::MessageValidator.main(ARGV)
end
