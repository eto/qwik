#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '..' unless $LOAD_PATH.include?('..')
require 'qwik/db-filesystem'
require 'qwik/db-backup'
require 'qwik/db-indexer'
require 'qwik/page'

module Qwik
  class PageExistError < StandardError; end
  class PageCollisionError < StandardError; end

  class Pages
    FIRST_PAGE_ID = '1'

    def initialize(config, dir)
      @config = nil	# Not use.

      dir = dir.path if dir.is_a? String
      spath = config.super_dir.path

      if config.db == 'fsdb'
	@db = FileSystemDB.new(dir, spath)
      elsif config.db == 'bdb'
	require 'qwik/db-berkeley'
	@db = BerkeleyDB.new(dir, spath)
      else
	raise 'Unknown data base type.'
      end

      @backupdb = BackupDB.new(dir)
      @db.register_observer(@backupdb)

#      @index = DBIndexer.new(dir)
#      @db.register_observer(@index)

      @pages = {}
    end
    attr_reader :db
    attr_reader :backupdb
    attr_reader :index

    def close
      @db.close
    end

    def create(k)	# Create a new page.
      raise PageExistError if baseexist?(k)
      return @pages[k] = Page.new(@config, self, k)
    end

    def create_new
      return create(get_new_id)
    end

    def baseexist?(k)
      return @db.baseexist?(k)
    end

    def exist?(k)
      return true if @pages[k]
      return @db.exist?(k)
    end

    def [](k)
      return @pages[k] if @pages[k]
      return @pages[k] = Page.new(@config, self, k) if @db.exist?(k)
      return nil	# No page.
    end

    def delete(k)
      self[k].delete
      @pages[k] = nil
    end

    def to_a(all=nil)
      ar = []
      each(all) {|page|
	ar << page
      }
      return ar
    end

    def each(all=false, with_super=false)
      # @db.each {|key|
      @db.each(with_super) {|key|
	next if ! all && /\A_/ =~ key
	page = self[key]
	next if page.nil? # what?
	yield(page)
      }
    end

    def each_all(&b)
      each(true, &b)
    end

    def nu_keys
      return map {|page| page.key }
    end

    def keys
      keys = []
      self.each {|page|
	keys << page.key
      }
      return keys
    end

    def nu_title_list
      return self.sort_by {|page|
	page.get_title.downcase
      }
    end

    def nu_date_list
      return self.sort_by {|page|
	page.mtime
      }
    end

    def title_list
#      get_titles.sort_by {|title|
#	title.downcase
#      }
#      return get_pages.sort_by {|page|
      return to_a.sort_by {|page|
	page.get_title.downcase
      }
    end

    def date_list
#      return get_pages.sort_by {|page|
      return to_a.sort_by {|page|
	page.mtime
      }
    end

    def find_title(title)
      self.each(true, true) {|page|
	if page.get_title == title
	  return page
	end
      }
      return nil
    end

    def get_new_id
      numkeys = keys.map {|k| /\A\d+\z/ =~ k ? k.to_i : 0 }
      return (numkeys.max + 1).to_s if numkeys.max
      return FIRST_PAGE_ID
    end

    def last_page_time
      return @db.last_page_time
    end

    # QuickML support
    def last_article_time
      return @db.last_article_time
    end

    # FIXME: Should make this obsolete.
    # page title support
    def pagetitle
      @pagetitle = PageTitle.new(@config, self) unless defined? @pagetitle
      return @pagetitle
    end

    def get_by_title(title)
      page = self[title] rescue nil
      return page if page

      # FIXME: This is obsolete.
      hash = pagetitle.hash
      if hash
	key = hash[title]
	return self[key[0]] if key
      end

      page = self.find_title(title)
      return page if page

      return nil
    end

    private

    def get_titles
      titles = []
      self.each {|page|
	titles << page.get_title
      }
      return titles
    end

#    def get_pages
#      pages = []
#      self.each {|page|
#	pages << page
#      }
#      return pages
#    end

  end
end

if $0 == __FILE__
  require 'qwik/farm'
  require 'qwik/server-memory'
  require 'qwik/test-module-session'
  $test = true
end

if defined?($test) && $test
=begin
  module Qwik
    class Site
      # Only for test.
      def get_pages
	return @pages
      end
    end
  end
=end

  class TestPages < Test::Unit::TestCase
    include TestSession

    def test_pages
      pages = @site.get_pages

      # test_create
      page = pages.create('1')

      # test_last_page_time
      page.put_with_time('test1', 0)
      ok_eq(0, pages.last_page_time.to_i)

      # test_each
      pages.each {|page|
	assert_instance_of(Qwik::Page, page)
	assert_instance_of(String, page.key)
      }

      # test_get_page
      page = pages['1']
      page.put('test2')
      ok_eq('test2', page.get)

      # test_page_exist_error
      assert_raises(Qwik::PageExistError) {
	pages.create('1')
      }

      # test_exist?
      ok_eq(true, pages.exist?('1'))

      # test_[]
      ok_eq('1', pages['1'].key)

      # test_delete
      pages.delete('1')
      ok_eq(false, pages.exist?('1'))
      ok_eq(nil, pages['1'])

      # test_get_new_id
      page = pages.create('0')
      page.store('t')
      ok_eq('1', pages.get_new_id)

      page = pages.create(pages.get_new_id)
      page.store('t')
      ok_eq(true, pages.exist?('1'))
      ok_eq('2', pages.get_new_id)

      page = pages.create('t')
      page.store('t')
      ok_eq('2', pages.get_new_id)
      ok_eq('2', pages.get_new_id)

      page = pages.create('4')
      page.store('t')
      ok_eq('5', pages.get_new_id)
    end

    def test_compare
      pages = @site.get_pages
      pages.erase_all
      a = pages.create('a')
      b = pages.create('b')
#      pages = pages.sort
#      ok_eq('a', pages[0].get_title)
#      ok_eq('b', pages[1].get_title)
    end

    def test_list
      pages = @site.get_pages

      pages.create('t1').store('')
      pages.create('t2').store('')
      pages.create('1').store('t3')
      pages.create('2').store('t4')

      pages.each {|page|
	assert_instance_of(Qwik::Page, page)
      }

      tlist = pages.title_list
      ok_eq('1', tlist[0].key)
      ok_eq('2', tlist[1].key)
      ok_eq('t1', tlist[2].key)
      ok_eq('t2', tlist[3].key)
      tlist.each {|page|
	assert_instance_of(String, page.get_title)
      }
    end

    def test_last_article_time
      pages = @site.get_pages
      a = pages.last_article_time
      ok_eq(nil, a)
      page = pages.create_new
      a = pages.last_article_time
      assert_instance_of(Time, a)
    end

    def test_enumerable
      pages = @site.get_pages

      #test_find_title
      pages.create_new.store("* ��")
      pages.create_new.store("* ��")
      pages.create_new.store("* ��")

      #page = pages.find_title("��")
      page = pages.get_by_title("��")
      ok_eq('2', page.key)
      ok_eq(['1', '2', '3'], pages.keys)
    end

    def test_recent_list
      pages = @site

      pages.create('t1').put_with_time('t', Time.at(0))
      pages.create('t2').put_with_time('t', Time.at(1))
      pages.create('1').put_with_time('t3', Time.at(2))
      pages.create('2').put_with_time('t4', Time.at(3))

      dlist = pages.date_list
      ok_eq('t1', dlist[0].key)
      ok_eq('t2', dlist[1].key)
      ok_eq('1',  dlist[2].key)
      ok_eq('2',  dlist[3].key)
      dlist.each {|page|
	assert_instance_of(Time, page.mtime)
      }
    end

    def nutest_cache
      pages = @site

      # Since this test takes long time, ignore this if under test suite.
      return if $0 != __FILE__	# just only for unit test.

      length, repeat = 100, 100

      page = pages.create_new
      page.store('a' * length)
      sleep 1
      repeat.times {
	str = page.load
      }
    end

    def test_backup
      pages = @site.get_pages

      page = pages.create('1')
      page.put_with_time('t', Time.at(0))
      ok_eq('t', page.load)

      bdb = pages.backupdb
      ar = bdb.map {|key, v, time| v }
      ok_eq('t', ar[0])
      ok_eq('', ar[1])

      page.put_with_time('t2', Time.at(1))

      ar = bdb.map {|key, v, time| v }
      ok_eq('t', ar[0])
      ok_eq('t2', ar[1])
      ok_eq('', ar[2])
    end

    def test_touch
      pages = @site

      # touch does not affect the content.
      page = pages['FrontPage']
      org = page.load
      assert_match(/FrontPage/, page.load)

      page.touch
      assert_match(/FrontPage/, page.load)
      ok_eq(org, page.load)
    end

    def test_with_underbar
      pages = @site.get_pages

      page3 = pages.create('_t')
      page3.store('t')
      found = false
      pages.each {|page|
	found = true if page.key[0] == ?_
      }
      ok_eq(false, found)

      pages.each(true) {|page|
	found = true if page.key[0] == ?_
      }
      ok_eq(true, found)

      found = false
      pages.each_all {|page|
	#qp page.key
	found = true if page.key[0] == ?_
      }
      ok_eq(true, found)
    end

    def test_super_pages
      pages = @site.get_pages

      # test_super_exist?
      ok_eq(true, pages.exist?('_SideMenu'))

      # test_baseexist?
      ok_eq(false, pages.baseexist?('_SideMenu'))

      # test_get_superpage
      page = pages['_SideMenu']
      ok_eq('Menu', page.get_title)

      # test_super_find_title
      page = pages.find_title('Menu')
      ok_eq('_SideMenu', page.key)

      # test_override_superpage
      page.store('* New menu')
      ok_eq('New menu', page.get_title)
      ok_eq(true, pages.baseexist?('_SideMenu'))
      page.delete
      ok_eq(false, pages.baseexist?('_SideMenu'))

      # test_override_create
      page = pages.create('_SideMenu')
      ok_eq(false, pages.baseexist?('_SideMenu')) # not yet
      page.store('t')
      ok_eq(true, pages.baseexist?('_SideMenu')) # become true here
    end
  end
end