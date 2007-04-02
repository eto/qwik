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
require 'qwik/group'

module QuickML
  class Group
    def need_alert?(now = Time.now)
      return false if forward? || @group_config.permanent? || alerted?
      return @db.last_article_time + @group_config[:ml_alert_time] <= now
    end

    def inactive?(now = Time.now)
      return false if forward? || @group_config.permanent?
      return @db.last_article_time + @group_config[:ml_life_time] < now
    end
  end
end

if $0 == __FILE__
  require 'qwik/group'
  require 'qwik/test-module-ml'
  $test = true
end

if defined?($test) && $test
  class TestGroupSweep < Test::Unit::TestCase
    include TestModuleML

    def setup_group
      return QuickML::Group.new(@ml_config, 'test@example.com')
    end

    def test_all
      group = setup_group

      ok_eq(false, group.forward?)

#      t_make_public(QuickML::Group, :permanent?)
#      ok_eq(false, group.permanent?)

      t_make_readable(QuickML::Group, :db)
      assert_instance_of(Time, group.db.last_article_time)

      t_make_readable(QuickML::Group, :group_config)
      ok_eq(2678400, group.group_config[:ml_life_time])

      t_make_public(QuickML::Group, :alerted?)
      ok_eq(false, group.alerted?)

      ok_eq(false, group.need_alert?(Time.at(0)))
      ok_eq(false, group.need_alert?(Time.at(1000000000)))
    end
  end
end
