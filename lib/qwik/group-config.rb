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
    def forward?
      return @group_config.forward?
    end

    def group_config_check_exist
      @group_config.check_exist
    end

    def get_max_members
      return @group_config[:max_members]
    end

    private

    def init_group_config
      @group_config = GroupConfig.new(@db)
      group_config = GroupConfig.get_group_config(@config)
      @group_config.set_default(group_config)
      @group_config.write
    end
  end

  class GroupConfig
    DefaultConfig = {
      :auto_unsubscribe_count	=> nil,
      :max_mail_length		=> nil,
      :max_members		=> nil,
      :ml_alert_time		=> nil,
      :ml_life_time		=> nil,
      :forward			=> false,
      :permanent		=> false,
      :unlimited		=> false,
    }

    KEYS = DefaultConfig.keys.map {|s| s.to_s }.sort.map {|k| k.intern }

    def initialize(db)
      @db = db
      @default = nil
      @group_config = {}
      @group_config.update(DefaultConfig)
      @content = nil
      read
    end

    def set_default(default)
      @default = default
    end

    def check_exist
      write if ! exist?
    end

    def exist?
      return @db.exist?(:Config)
    end

    def [](key)
      read
      return @group_config[key]
    end

    def forward?
      return true if @db.exist?(:Forward)
      return true if self[:forward]
      return false
    end

    def permanent?
      return true if @db.exist?(:Permanent)
      return true if self[:permanent]
      return false
    end

    def unlimited?
      return true if @db.exist?(:Unlimited)
      return true if self[:unlimited]
      return false
    end

    def write
      raise 'must have default' if @default.nil?
      GroupConfig.set_default(@default, @group_config)
      content = GroupConfig.generate(@group_config)
      return if content == @content	# Do nothing.
      @db.put(:Config, content)
      @content = content
    end

    private

    def read
      content = @db.get(:Config)
      return if content && content == @content	# Do nothing.
      @content = content
      config = GroupConfig.parse_hash(@content)
      @group_config.update(config)
      return
    end

    def self.parse_hash(str)
      config = {}
      return config if str.nil?
      str.each {|line|
	k = v = nil
	line.chomp!
	if /\A\s+:([a-z_]+) => (\d+),\z/ =~ line
	  k = $1.intern
	  v = $2.to_i
	  config[k] = v
	elsif /\A:([a-z_]+):(\d+)\z/ =~ line
	  k = $1.intern
	  v = $2.to_i
	  config[k] = v
	elsif /\A:([a-z_]+):([a-z]+)\z/ =~ line
	  k = $1.intern
	  v = $2
	  v = true  if v == 'true'
	  v = false if v == 'false'
	  config[k] = v
	end
      }
      return config
    end

    def self.set_default(default, group_config)
      default.each {|k, v|
	group_config[k] ||= v
      }
    end

    def self.generate(config)
      return KEYS.map {|k|
	":#{k}:#{config[k]}\n"
      }.join
    end

    def self.get_group_config(config)
      return {
	:auto_unsubscribe_count	=> config[:auto_unsubscribe_count],
	:max_mail_length	=> config[:max_ml_mail_length] ||
				   config[:max_mail_length],
	:max_members		=> config[:max_members],
	:ml_alert_time		=> config[:ml_alert_time],
	:ml_life_time		=> config[:ml_life_time],
      }
    end

  end
end

if $0 == __FILE__
  require 'qwik/farm'
  require 'qwik/server-memory'
  require 'qwik/test-module-session'
  require 'qwik/config'
  $test = true
end

if defined?($test) && $test
  class TestGroupConfig < Test::Unit::TestCase
    include TestSession

    def test_class_method
      c = QuickML::GroupConfig

      # test_parse_hash
      ok_eq({}, c.parse_hash(''))
      ok_eq({:max_members=>20}, c.parse_hash('{
  :max_members => 20,
}'))
      m = c.parse_hash(':max_members:20')
      ok_eq({:max_members=>20}, m)
      m = c.parse_hash(':forward:true')
      ok_eq({:forward=>true}, m)

      # test_generate
      ok_eq(":auto_unsubscribe_count:\n:forward:\n:max_mail_length:\n:max_members:\n:ml_alert_time:\n:ml_life_time:\n:permanent:\n:unlimited:\n", c.generate({}))
    end

    def test_all
      sites_dir = '.test/data/'
      group_name = 'test'
      db = QuickML::GroupDB.new(sites_dir, group_name)
      db.set_site(@site)

      config = Qwik::Config.new
      group_config = QuickML::GroupConfig.new(db)
      default = QuickML::GroupConfig.get_group_config(config)
      group_config.set_default(default)
      group_config.write

      # ==================== GroupConfig
      # test_exist?
      ok_eq(true, group_config.exist?)

      # test_[]
      ok_eq(100, group_config[:max_members])

      # test_forward?
      ok_eq(false, group_config.forward?)

      # test_permanent?
      ok_eq(false, group_config.permanent?)

      # test_unlimited?
      ok_eq(false, group_config.unlimited?)

      # test_write
      group_config.instance_eval {
	@group_config[:max_members] = 10
      }
      ok_eq(10, group_config[:max_members])
      group_config.write

      # test_read
      t_make_public(QuickML::GroupConfig, :read)
      group_config.read
      ok_eq(10, group_config[:max_members])
      
      str = db.get(:Config)
      ok_eq(":auto_unsubscribe_count:5\n:forward:false\n:max_mail_length:102400\n:max_members:10\n:ml_alert_time:2073600\n:ml_life_time:2678400\n:permanent:false\n:unlimited:false\n", str)

      # test_forward?
      ok_eq(false, group_config.forward?)

      page = @site['_GroupConfig']
      page.put_with_time(':forward:true', Time.at(Time.now.to_i+10))
      ok_eq(true, group_config.forward?)
    end
  end
end
