# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Site
    def member
      @member = SiteMember.new(@config, self) if ! defined?(@member)
      return @member
    end
  end

  class SiteMember
    include Enumerable

    def initialize(config, site)
      @config = config
      @site = site
      @quickml_member = QuickMLMember.new(@config, @site)
    end

    def update_group_files
      @quickml_member.update_group_files
    end

    def exist?(user)
      return true if exist_qwik_members?(user)
      return true if @quickml_member.exist?(user)
      false
    end

#act-ring-invite.rb:125: next if @site.member.exist_qwik_members?(guest_mail)
#act-ring-new.rb:60: return 'exist' if @site.member.exist_qwik_members?(guest_mail)
    def exist_qwik_members?(user)
      return false if db_page.nil?
      db.exist?(user)
    end

    def add(user, invite=nil)
      db.add(user, invite)
    end

    def remove(user)
      db.remove(user) if db_page
    end

    def list(obf=true)
      ar = []
      ar += db.hash.keys.to_a if db_page
      ar += @quickml_member.list
      ar = ar.uniq
      if obf && @site.is_open?
	ar = ar.map {|u|
	  MailAddress.obfuscate(u)
	}
      end
      return ar
    end

    def each
      list.each {|u|
	yield u
      }
    end

    private

    def db_page
      k = 'SiteMember'
      return @site[k] if @site.exist?(k)
      k = '_'+k
      return @site[k] if @site.exist?(k)
      return @site.create(k)
    end

    def db
      page = db_page
      return page.wikidb
    end
  end

  class QuickMLMember	# QuickML compatible
    include Enumerable

    def initialize(config, site)
      @config = config
      @site = site
      @str = nil
      @ar = []

      check_new
    end

    def update_group_files
      # @group_db.update_files
    end

    def list
      check_new
      @ar
    end

    def exist?(user)
      list.include?(user)
    end

    private

    def check_new
      str = get_content
      return if str == @str
      @str = str
      @ar = QuickMLMember.check_new_internal(@str)
    end

    def get_content
      f = @site.path+'_GroupMembers.txt'
      return f.read if f.exist?

      f = @site.path+',members'
      return f.read if f.exist?

      return nil
    end

    def self.check_new_internal(str)
      ar = []
      return ar if str.nil?
      str.each {|line|
	firstchar = line[0, 1]
	next if firstchar == '#' || firstchar == ';'
	k, v = line.chomp.split
	next if k.nil?
	ar << k
      }
      return ar
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestSiteMember < Test::Unit::TestCase
    include TestSession

    alias ok assert

    def test_all
      user = 'user@e.com'
      member = @site.member

      # test_exist?
      page = @site.create('_SiteMember')
      ok_eq(false, member.exist?(user))
      page.store(user)
      ok_eq(false, member.exist?(user))
      page.store(',user@e.com')
      ok_eq(true,  member.exist?(user))
      page.store(',user@e.com,')
      ok_eq(true,  member.exist?(user))
      page.store(',user@e.com,a')
      ok_eq(true,  member.exist?(user))
      page.store(',user@e.com,a,')
      ok_eq(true,  member.exist?(user))

      # test_remove
      member.remove(user)
      ok_eq(false, member.exist?(user))
      ok_eq('', page.load)

      # test_add
      member.add(user)
      ok_eq(true,  member.exist?(user))

      # test_invite
      guest = 'guest@example.com'
      member.add(guest, user)
      ok_eq(true,  member.exist?(guest))

      ok_eq(",user@e.com,\n,guest@example.com,user@e.com\n", page.load)
      assert(member.list.include?(user))
      assert(member.list.include?(guest))
      member.remove(guest)
      ok_eq(true, !member.exist?(guest))

      @site.delete('_SiteMember')
      ok_eq(true, !member.exist?(user))
      ok_eq([], member.list)

      # test_quickml_member
      ok_eq(true, !member.exist?(user))
      store(user)
      ok_eq(true, member.exist?(user))

      ok_eq([user], member.list)
      store('# user@e.com')
      ok_eq(true, !member.exist?(user))

      store('; user@e.com')
      ok_eq(true, !member.exist?(user))

      store('')
      ok_eq(true, !member.exist?(user))
      ok_eq([], member.list)

      # test_obfuscate
      page = @site['_SiteConfig']
      assert_match(/:open:false/, page.load)
      ok_eq(false, @site.is_open?)
      page.store(':open:true')
      ok_eq(':open:true', page.load)
      ok_eq(true, @site.is_open?)

      member.add(user)
      member.add(guest)
      assert(member.list.include?('user@e...'))
      assert(member.list.include?('guest@e...'))
    end

    def store(content)	# quickml_member
      (@dir+'_GroupMembers.txt').put(content)
    end
  end
end
