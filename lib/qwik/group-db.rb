# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module QuickML
  class GroupDB
=begin
    FILENAME = {
      :Members		=> ',members',
      :Count		=> ',count',
      :Config		=> ',config',
      :Charset		=> ',charset',
      :Alerted		=> ',alerted',
      :Forward		=> ',forward',
      :Permanent	=> ',permanent',
      :Unlimited	=> ',unlimited',
      :WaitingMembers	=> ',waiting-members',
      :WaitingMessage	=> ',waiting-message',
    }
=end

    PAGENAME = {
      :Members		=> '_GroupMembers',
      :Count		=> '_GroupCount',
      :Config		=> '_GroupConfig',
      :Charset		=> '_GroupCharset',
      :Alerted		=> '_GroupAlerted',
      :Forward		=> '_GroupForward',
      :Permanent	=> '_GroupPermanent',
      :Unlimited	=> '_GroupUnlimited',
      :WaitingMembers	=> '_GroupWaitingMembers',
      :WaitingMessage	=> '_GroupWaitingMessage',
    }

    def initialize(sites_dir, group_name)
      @sites_dir = sites_dir
      @group_name = group_name
      @site = nil
      get_dirpath.mkpath	# Make a new directory here.
    end

    def set_site(site)
      @site = site
    end

=begin
    def update_files
      if false
	FILENAME.keys.each {|s|
	  sync(s)
	}
      end
    end
=end

    # read
    def exist?(s)
      #sync(s)

#      f = get_filpath(s)
#      return true if f.exist?

      pagename = get_pagename(s)
      page = @site[pagename]
      return true if page

      return false
    end

    def mtime(s)
#      return [file_mtime(s), page_mtime(s)].max
      return page_mtime(s)
    end

    def get(s)	# with sync.
      #sync(s)

#      file_content = nil
#      f = get_filepath(s)
#      file_content = f.read if f.exist?

      page_content = nil
      pagename = get_pagename(s)
      page = @site[pagename]
      page_content = page.get if page
      return page_content

      # Both is nil.
#      return nil if file_content.nil? && page_content.nil?	# Do nothing.

#      fmt = file_mtime(s)
#      pmt = page_mtime(s)

      # File is exist, but the page is not exist.
#      if file_content && page_content.nil?
#	page = @site.create(pagename)
#	page.put_with_time(file_content, fmt)
#	# FIXME: delete file?
#	return file_content
#      end

      # File is not exist, but page is exist.
#      if file_content.nil? && page_content
#	# Do not create file.
#	#f.put(page_content)
#	#f.utime(pmt, pmt)
#	return page_content
#      end

      # Both exist.
#      if file_content == page_content
#	return page_content
#      end

#      if fmt < pmt	# The page is new.
#	f.put(page_content)
#	begin
#	  f.utime(pmt, pmt)
#	rescue
#	  p 'error to set time'
#	end
#	return page_content
#      end

#      page.put_with_time(file_content, fmt)
#      return file_content
    end

    # write
    def put(s, content)
#      f = get_filepath(s)
#      f.put(content)

      pagename = get_pagename(s)
      page = @site[pagename]
      page = @site.create(pagename) if page.nil?
      page.put(content)
    end

    def add(s, content)
#      f = get_filepath(s)
#      f.add(content)

      pagename = get_pagename(s)
      page = @site[pagename]
      page = @site.create(pagename) if page.nil?
      page.add(content)
    end

    def delete(s)
      return if ! exist?(s)
#      f = get_filepath(s)
#      f.unlink

      pagename = get_pagename(s)
      page = @site[pagename]
      @site.delete(pagename) if page
    end

    # the mtime of the newest file in the directory
    def last_article_time
      max = nil
      dir = get_dirpath
      dir.each_entry {|f|
	fs = f.to_s

	next if /\A\./ =~ fs ||
#	  /,config/ =~ fs ||
	  /_GroupConfig.txt/ =~ fs ||
#	  /,charset/ =~ fs ||
	  /_GroupCharset.txt/ =~ fs

	file = dir+f
	mt = file.mtime
	if max.nil? || max < mt
	  max = mt 
	end
      }
      return max || Time.now
    end

    private

    def get_pagename(symbol)
      return PAGENAME[symbol]
    end

    def get_dirpath
      return "#{@sites_dir}/#{@group_name}".path
    end

=begin
    def get_filepath(symbol)
      dir = get_dirpath
      base = FILENAME[symbol]
      return nil if base.nil?
      return dir+base
    end

    def file_mtime(s)
      f = get_filepath(s)
      return f.mtime if f.exist?
      return Time.at(0)
    end
=end

    def page_mtime(s)
      pagename = get_pagename(s)
      page = @site[pagename]
      return page.mtime if page
      return Time.at(0)
    end

=begin
    def sync(s)
      file_content = nil
      f = get_filepath(s)
      file_content = f.read if f.exist?

      page_content = nil
      pagename = get_pagename(s)
      page = @site[pagename]
      page_content = page.get if page

      # Both is nil.
      return if file_content.nil? && page_content.nil?	# Do nothing.

      fmt = file_mtime(s)
      pmt = page_mtime(s)

      # File is exist, but the page is not exist.
      if file_content && page_content.nil?
	page = @site.create(pagename)
	page.put_with_time(file_content, fmt)
	# FIXME: delete file?
	return
      end

      # File is not exist, but page is exist.
      if file_content.nil? && page_content
	f.put(page_content)
	f.utime(pmt, pmt)
	return
      end

      # Both exist.
      if file_content == page_content
	return	# The two contents are already synced.
      end
      
      if fmt < pmt	# The page is new.
	f.put(page_content)
	f.utime(pmt, pmt)
	return
      end

      page.put_with_time(file_content, fmt)
      return
    end
=end
  end
end

if $0 == __FILE__
  require 'qwik/farm'
  require 'qwik/server-memory'
  require 'qwik/test-module-session'
  $test = true
end

if defined?($test) && $test
  class TestGroupDB < Test::Unit::TestCase
    include TestSession

    def test_db
      sites_dir = './.test/data'
      group_name = 'test'

      db = QuickML::GroupDB.new(sites_dir, group_name)

      ok_eq(true, './.test/data/test'.path.exist?)

      db.set_site(@site)

      t_make_public(QuickML::GroupDB, :get_dirpath)
      ok_eq('./.test/data/test', db.get_dirpath.to_s)

      # test_put
      db.put(:Count, 'v')

      # test_exist?
      ok_eq(true, db.exist?(:Count))

      # test_get
      ok_eq('v', db.get(:Count))

      # test_add
      db.add(:Count, 'w')
      #ok_eq('vw', db.get(:Count))
      ok_eq("v\nw\n", db.get(:Count))

      # test_last_article_time
      t = db.last_article_time
      assert_instance_of(Time, t)

      # test_delete
      db.delete(:Count)
      ok_eq(false, db.exist?(:Count))

      # test_use_site
      site = @site
      page = site['_GroupCount']
      ok_eq(nil, page)

      db.put(:Count, 'v2')
      page = site['_GroupCount']
      ok_eq('v2', page.get)

      page.put_with_time('v3', Time.at(Time.now.to_i+10))
      ok_eq('v3', db.get(:Count))

    end
  end
end
