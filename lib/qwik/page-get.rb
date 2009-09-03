# -*- coding: shift_jis -*-
# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Page
    def get
      return @db.get(@key)
    end
    alias load get

    def size
      return @db.size(@key)
    end

    def mtime
      return @db.mtime(@key)
    end

    def get_title
      title, tags = Page.get_title(self.get)
      return title if title

      # Abandon to get title and return the page key.
      return @key
    end

    def self.get_title(str)
      first_line = get_first_line(str)
      return parse_title_line(first_line)
    end

    def self.get_first_line(str)
      return nil if str.nil?

      while true
	# If the str has only one line, return it.
	i = str.index(?\n)
	return str if i.nil?

	# Get the first line.
	line = str[0..i]
	line.chop!	# The end of line is newline.
	if line[0] == ?#
	  str = str[(i+1)..-1]	# Store rest and try again.
	  next
	end
	return line
      end
      raise	# Do not come here.
    end

    def self.parse_title_line(line)
      return nil unless /\A\*/s =~ line		# must begin with '*'.
      title = $'	# the rest of the line.
      return nil if title[0] == ?*	# must be h2 level.
      return parse_title(title)
    end

    def self.parse_title(title, tags=[])
      return nil if title.nil?

      title = title.strip	# Remove start and end spaces.

      return nil if title.empty?	# The title should not be empty.

      # If the title has a tag,
      if /\A\[(.+?)\]/s =~ title
	tag = $1
	return [title, tags] if $'.empty?

	title = $'
	tags << tag
	return parse_title(title, tags)		# Resursive.
      end

      return [title, tags]
    end

    def get_body
      return Page.get_body(self.get)
    end

    def self.get_body(str)
      ar = []
      first_line = true
      start_body = true
      str.each_line {|line|
	if first_line
	  first_line = false
	  if line[0] == ?* && line[1] != ?*
	    # this is title
	  else
	    ar << line
	  end
	else
	  if start_body
	    if /\A$/ =~ line	# Skip empty line.
	      next
	    else
	      start_body = false
	    end
	  end

	  if ! start_body
	    ar << line
	  end
	end
      }
      return ar.join
    end

    def get_tags
      title, tags = Page.get_title(self.get)
      return tags if tags
      return nil
    end

    # ============================== class method
    def self.valid_as_pagekey?(t)
      return /\A[A-Za-z_0-9]+\z/ =~ t
    end

  end
end

if $0 == __FILE__
  require 'qwik/farm'
  require 'qwik/server-memory'
  require 'qwik/test-module-session'
  $test = true
end

if defined?($test) && $test
  module Qwik
    class Site
      # Only for test.
      def get_pages
	return @pages
      end
    end
  end

  class TestPageGet < Test::Unit::TestCase
    include TestSession

    def test_all
      pages = @site.get_pages
      page = pages.create_new

      # test_get
      ok_eq('', page.get)
      ok_eq('', page.load)

      # test_mtime
      assert_instance_of(Time, page.mtime)

      # test_size
      is 0, page.size
      page.store('t')
      is 1, page.size
    end

    def test_destructive
      pages = @site.get_pages
      page = pages.create('1')

      page.store('t')
      str = page.get
      ok_eq('t', str)
      str.sub!(/t/, 's')	# Destructive method.
      ok_eq('s', str)
      ok_eq('t', page.get)
    end
  end

  class TestPageClassMethod < Test::Unit::TestCase
    def test_valid_as_pagekey?
      c = Qwik::Page
      ok_eq(true,  !!c.valid_as_pagekey?('t'))
      ok_eq(false, !!c.valid_as_pagekey?('t t'))
    end

    def ok_title(e, s)
      title, tags = Qwik::Page.get_title(s)      
      ok_eq(e, title)
    end

    def ok_get_title(e, s)
      res = Qwik::Page.get_title(s)      
      ok_eq(e, res)
    end

    def test_get_title
      c = Qwik::Page

      ok_title(nil, nil)
      ok_title(nil, '')
      ok_title(nil, 't')	# must begin with *
      ok_title(nil, '-t')
      ok_title(nil, "b1\nb2")
      ok_title(nil, '** t')	# must be h2 level header.
      ok_title(nil, '**t')
      ok_title(nil, "** t\nb")
      ok_title(nil, '*')	# empty
      ok_title(nil, '* ')
      ok_title(nil, '*  ')

      ok_title('t', '*t')	# normal
      ok_title('t', '* t')
      ok_title('t', '*t ')
      ok_title('t', '* t ')
      ok_title('a b', '*a b')
      ok_title('a b', '* a b')
      ok_title('*t', '* *t')	# uum...
      ok_title('- t', '*- t')	# uum...
      ok_title('t', "* t\nb")
      ok_title('t', "# c\n* t\nb")
      ok_title('字', '*字')
      ok_title('あ', '*あ')
      ok_title('コ', '* コ')
      ok_title('コ', "* コ\n{{mail(user@e.com)\nあ\n\n}}\n")

      # The title line can contain tag data.
      ok_get_title(['t', ['tag']],	'* [tag] t')
      ok_get_title(['t', ['t1', 't2']],	'* [t1][t2] t')
      ok_get_title(['[tag]', []],	'* [tag]')
      ok_get_title(['[t2]', ['t1']],	'* [t1][t2]')
      ok_get_title(['t', ['2001-02-03']],	'* [2001-02-03] t')
    end

    def test_get_first_line
      c = Qwik::Page
      ok_eq('',		c.get_first_line(''))
      ok_eq('',		c.get_first_line("\n"))
      ok_eq('line1',	c.get_first_line('line1'))
      ok_eq('l1',	c.get_first_line("l1\nl2\n"))
      ok_eq('',		c.get_first_line("\nline2\n"))
      ok_eq('l1',	c.get_first_line("# c\nl1\nl2\n"))
    end

    def test_get_body
      c = Qwik::Page
      ok_eq('b',	c.get_body("* t\nb"))
      ok_eq('b',	c.get_body("* t\n\nb"))
#      ok_eq('b',	c.get_body("# c\n* t\nb"))
      ok_eq("b1\nb2",	c.get_body("b1\nb2"))
      ok_eq("** t\nb",	c.get_body("** t\nb"))
      ok_eq('* t2',	c.get_body("* t\n* t2"))
      ok_eq('* t2',	c.get_body("* t\n\n* t2"))
    end

    def test_get_body_sharp
      c = Qwik::Page
      ok_eq("a\n#b\nc",	c.get_body("a\n#b\nc"))
    end

  end
end
