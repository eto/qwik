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
require 'qwik/group-db'

module QuickML
  class Group
    def newly_created?
      return ! @db.exist?(:Members)
    end

    private

    # ==================== Count
    def init_count
      @count = Group.load_count(@db)
    end

    def self.load_count(db)
      return 0 if ! db.exist?(:Count)
      content = db.get(:Count)
      return (content.to_a.first || '1').chomp.to_i
    end

    def inc_count
      @count += 1
      @db.put(:Count, @count)
    end

    # ==================== Charset
    def init_charset
      @charset = Group.load_charset(@db)
    end

    def self.load_charset(db)
      return nil if ! db.exist?(:Charset)
      return parse_charset(db.get(:Charset))
    end

    def self.parse_charset(content)
      return (content.to_a.first || '').chomp
    end

    def save_charset(charset)
      return if charset.nil?
      @db.put(:Charset, charset+"\n")
    end

    # ==================== Alertedp
    def alerted?
      return @db.exist?(:Alerted)
    end

    def close_alertedp_file
      @db.put(:Alerted, '')
    end

    def remove_alertedp_file
      @db.delete(:Alerted)
    end
  end
end

if $0 == __FILE__
  require 'qwik/group'
  require 'qwik/test-module-ml'
  $test = true
end

if defined?($test) && $test
  class TestGroupConditions < Test::Unit::TestCase
    include TestModuleML

    def setup_group
      return QuickML::Group.new(@ml_config, 'test@example.com')
    end

    def test_all
      c = QuickML::Group

      group = setup_group

      t_make_readable(QuickML::Group, :db)

      # ==================== Conditions.
      # test_newly_created?
      ok_eq(true, group.newly_created?)

      # ==================== Count
      # test_init_count
      t_make_public(QuickML::Group, :init_count)
      group.init_count

      t_make_readable(QuickML::Group, :count)
      ok_eq(0, group.count)
      ok_eq(nil, group.db.get(:Count))

      # test_inc_count
      t_make_public(QuickML::Group, :inc_count)
      group.inc_count
      ok_eq(1, group.count)
      ok_eq('1', group.db.get(:Count))

      # test_load_count
      ok_eq(1, c.load_count(group.db))
      group.inc_count
      ok_eq(2, c.load_count(group.db))

      # ==================== Charset
      # test_init_charset
      t_make_public(QuickML::Group, :init_charset)
      group.init_charset

      t_make_readable(QuickML::Group, :charset)
      ok_eq(nil, group.charset)

      # test_parse_charset
      ok_eq('', c.parse_charset(''))
      ok_eq('t', c.parse_charset("t\n"))
      ok_eq('t', c.parse_charset("t\ns\n"))
      ok_eq('iso-2022-jp', c.parse_charset("iso-2022-jp\n"))

      # test_save_charset
      t_make_public(QuickML::Group, :save_charset)
      group.save_charset('iso-2022-jp')
      ok_eq("iso-2022-jp\n", group.db.get(:Charset))
      group.init_charset
      ok_eq('iso-2022-jp', group.charset)

      # test_load_charset
      ok_eq('iso-2022-jp', c.load_charset(group.db))

      # ==================== Alertedp
      # test_alerted?
      t_make_public(QuickML::Group, :alerted?)
      ok_eq(false, group.alerted?)

      # test_close_alertedp_file
      t_make_public(QuickML::Group, :close_alertedp_file)
      group.close_alertedp_file
      ok_eq(true, group.alerted?)

      # test_remove_alertedp_file
      t_make_public(QuickML::Group, :remove_alertedp_file)
      group.remove_alertedp_file
      ok_eq(false, group.alerted?)
    end
  end
end
