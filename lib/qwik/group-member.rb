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
    def active_members_include?(address)
      return @members.active_include?(address)
    end

    def former_members_include?(address)
      return @members.former_include?(address)
    end

    def add_member (address)
      if Group.exclude?(address, @config.ml_domain)
	@logger.vlog "Excluded: #{address}"
	return
      end
      return if @members.active_include?(address)	# Already included.
      @members.add_member(address)
      @added_members.push(address)
      @logger.log "[#{@name}]: Add: #{address}"
    end

    def self.exclude?(address, config_domain)
      name, domain = address.split('@')
      return true if domain.nil?
      return Mail.address_of_domain?(address, config_domain)
    end

    def remove_member (address)
      return if ! @members.active_include?(address)
      @members.remove_member(address)
      @logger.log "[#{@name}]: Remove: #{address}"
      close if @members.active_empty?
    end

    def add_error_member (address)
      return if ! @members.active_include?(address)
      prev_count = @members.error_count(address)
      count = @members.inc_error_count(address)
      if prev_count == count
	@logger.log "[#{@name}]: AddError: #{address} (not counted)"
      else
	@logger.log "[#{@name}]: AddError: #{address} #{count}"
      end
      @members.save

      if @group_config[:auto_unsubscribe_count] <= @members.error_count(address)
	remove_member(address)
	report_removed_member(address)
      end
    end

    private

    def reset_error_member (address)
      return unless @members.error_include?(address)
      @members.error_delete(address)
      @logger.log "[#{@name}]: ResetError: #{address}"
      @members.save
    end

    def init_members
      @members = GroupMembers.new(@config, self, @db, @group_config)
    end

    def member_added?
      return ! @added_members.empty?
    end

    def get_active_members
      return @members.get_active
    end
  end

  class GroupMembers
    def initialize(config, group, db, group_config)
      @config = config
      @group = group
      @db = db
      @group_config = group_config

      @active = IcaseArray.new
      @former = IcaseArray.new
      @error  = IcaseHash.new

      load
    end

    def save
      str = GroupMembers.generate(@active, @former, @error)
      @db.put(:Members, str)
    end

    def add_member(address)
      raise TooManyMembers if too_many?
      former_delete(address)
      active_push(address)
      save
    end

    def remove_member(address)
      active_delete(address)
      former_push(address)
      error_delete(address)
      save
    end

    # active
    def get_active
      return @active
    end
    def active_empty?
      return @active.empty?
    end
    def active_include?(address)
      return @active.include?(address)
    end
    def active_push(address)
      @active.push(address)
    end
    def active_delete(address)
      @active.delete(address)
    end

    # former
    def former_include?(address)
      return @former.include?(address)
    end
    def former_push(address)
      @former.push(address)
    end
    def former_delete(address)
      @former.delete(address)
    end

    # error
    def error_include?(address)
      return @error.include?(address)
    end
    def error_delete(address)
      @error.delete(address)
    end

    # Old methods.
    def too_many?
      return false if @group_config.unlimited?
      return @group_config[:max_members] <= @active.length
    end

    def list
      return @active.map {|x| MailAddress.obfuscate(x) }.join("\n")
    end

    def inc_error_count (address)
      if ! @error.include?(address)
	@error[address] = ErrorInfo.new
      end
      if ! allowable_error_interval?(@error[address].last_error_time)
	@error[address].inc_count
      end
      @error[address].count
    end

    def error_count (address)
      return @error[address].count if @error.include?(address)
      return 0
    end

    private

    def load
      content = @db.get(:Members) || ''
      GroupMembers.parse(@active, @former, @error, content)
    end

    def self.parse(active, former, error, content)
      content.each {|line| 
	line.chomp!
	next if line.empty?
	if /^# (.*)/ =~ line	# removed address
	  former.push($1) if ! former.include?($1)
	elsif /^; (.*?) (\d+)(?: (\d+))?/ =~ line
	  address = $1
	  count= $2.to_i
	  last_error_time = if $3 then Time.at($3.to_i) else Time.at(0) end
	  error[address]= ErrorInfo.new(count, last_error_time)
	else
	  active.push(line) if ! active.include?(line)
	end
      }
    end

    def self.generate(active, former, error)
      c = ''
      active.each {|address| c << address+"\n" }
      former.each {|address| c << "# "+address+"\n" }
      error.each {|address, error_info|
	t = error_info.last_error_time.to_i
	c << "; #{address} #{error_info.count} #{t}\n"
      }
      return c
    end

    def allowable_error_interval? (time)
      now  = Time.now
      past = now - @config.allowable_error_interval
      return past < time && time <= now
    end
  end

  class ErrorInfo
    def initialize (count = 0, last_error_time = Time.at(0))
      @count = count
      @last_error_time = last_error_time
    end
    attr_reader :count
    attr_reader :last_error_time

    def inc_count
      @count += 1
      t = Time.now
      t = Time.at(0) if defined?($test) && $test
      @last_error_time = t
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-module-ml'
  $test = true
end

if defined?($test) && $test
  class TestGroup_members < Test::Unit::TestCase
    include TestModuleML

    def setup_group
      return QuickML::Group.new(@ml_config, 'test@example.com')
    end

    def test_class_method
      c = QuickML::Group

      # test_exclude?
      ok_eq(true, c.exclude?('user', 'example.net'))
      ok_eq(true,  c.exclude?('user@example.net', 'example.net'))
      ok_eq(false, c.exclude?('user@example.com', 'example.net'))
    end

  end

  class TestGroupMembers < Test::Unit::TestCase
    include TestModuleML

    def setup_group
      return QuickML::Group.new(@ml_config, 'test@example.com')
    end

    def test_class_method
      c = QuickML::GroupMembers

      # test_generate
      ok_eq('', c.generate([], [], []))

      # test_parse
      active, former, error = [], [], []
      c.parse(active, former, error, "\n")
      eq([[], [], []], [active, former, error])
    end

    def test_all
      group = setup_group	# init_members is already called here.

      t_make_readable(QuickML::Group, :members)
      members = group.members

      members.save

      t_make_readable(QuickML::Group, :db)
      ok_eq(true, group.db.exist?(:Members))
      ok_eq('', group.db.get(:Members))

      group.add_member('user@e.com')
      str = group.db.get(:Members)
      ok_eq("user@e.com\n", str)

      group.add_error_member('user@e.com')
      str = group.db.get(:Members)
      ok_eq("user@e.com\n; user@e.com 1 0\n", str)

      ok_eq(true, group.db.exist?(:Members))
      group.remove_member('user@e.com')
    end
  end
end
