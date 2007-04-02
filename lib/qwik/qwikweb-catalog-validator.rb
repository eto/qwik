# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/gettext'
include Qwik
include Qwik::GetText

module Qwik
  class CatalogValidator
    def self.main(argv)
      if argv.length < 2
	puts "usage: ruby catalog-validator.rb <catalog> <source...>"
	exit
      end

      catalog_file = argv.shift
      catalog = load_catalog(catalog_file)
      set_catalog(catalog)

      ok = true
      argv.each {|source_file|
	validator = self.new(source_file, catalog)
	validator.validate
	validator.error_messages.each {|message|
	  puts message
	}
	ok = (ok and validator.ok?)
      }
      if ok then exit else exit(1) end
    end

    def initialize (source_file_name, messages)
      @source_file_name  = source_file_name
      @gettext_catalog = messages
      @error_messages = []
    end
    attr_reader :error_messages

    def read_file_with_numbering (file_name)
      content = ''
      File.open(file_name).each_with_index {|line, idx|
        lineno = idx + 1
        content << line.gsub(/\b_\(/, "_[#{lineno}](")
      }
      content
    end

    def collect_messages (content)
      messages = []
      while content.sub!(/\b_\[(\d+)\]\(("(?:\\"|.)*?").*?\)/m, "")
        lineno  = $1.to_i
        message = eval($2)
        messages.push([lineno, message])
      end
      messages
    end

    def validate
      @gettext_catalog or return
      content = read_file_with_numbering(@source_file_name)
      messages = collect_messages(content)
      messages.each {|lineno, message|
        translated_message = @gettext_catalog[message]
        if not translated_message
          message = 
            sprintf('%s:%d: %s', @source_file_name, lineno, message.inspect)
          @error_messages.push(message)
        elsif message.count('%') != translated_message.count('%')
          message = sprintf("%s:%d: %s => # of %% mismatch.",
                            @source_file_name, 
                            lineno, message.inspect, translated_message)
          @error_messages.push(message)
        end
      }
    end

    def ok?
      @error_messages.empty?
    end
  end
end

if $0 == __FILE__
  Qwik::CatalogValidator.main(ARGV)
end

if defined?($test) && $test
  require 'qwik/testunit'

  class TestCatalogValidator < Test::Unit::TestCase
    include Qwik::GetText

    def test_dummy
    end

    def nutest_validator
     #validator = CatalogValidator.new($0, CATALOG)
      validator = Qwik::CatalogValidator.new($0, CATALOG)
      validator.validate
      ok_eq(true, validator.ok?)

     #validator = CatalogValidator.new($0, {})
      validator = Qwik::CatalogValidator.new($0, {})
      validator.validate
      ok_eq(false, validator.ok?)
    end
  end
end
