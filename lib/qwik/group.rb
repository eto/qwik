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
require 'qwik/mail'
require 'qwik/config'
require 'qwik/ml-gettext'
require 'qwik/ml-exception'
require 'qwik/ml-generator'
require 'qwik/mailaddress'

require 'qwik/util-basic'
require 'qwik/util-safe'

require 'qwik/group-config'
require 'qwik/group-cond'
require 'qwik/group-member'

require 'qwik/group-site'
require 'qwik/group-sweep'
require 'qwik/group-mail'
require 'qwik/group-sendmail'
require 'qwik/group-confirm'

module QuickML
  class Group
    include GetText

    # ============================== initialize
    def initialize (config, address, creator = nil, message_charset = nil)
      @config = config
      @address = address
      @name, domain = Group.get_name(@address)
      @return_address = Group.generate_return_address(@address,
						      @config.use_qmail_verp)

      # init_db
      @db = GroupDB.new(@config.sites_dir, @name)
      init_site		# initialize for GroupSite
      @db.set_site(@site)

      @added_members = []

      @logger = @config.logger
      @catalog = @config.catalog

      init_group_config
      init_members
      init_count
      init_charset

      @message_charset = message_charset || @charset
      @logger.log "[#{@name}]: New ML by #{creator}" if newly_created?
    end

    attr_reader :name
    attr_reader :address
    attr_reader :return_address
    attr_reader :count
    attr_reader :charset

    def close_dummy
      @logger.log("[#{@name}]: ML will be closed")
    end

    def close
      @db.delete(:Members)
      @db.delete(:Count)
      @db.delete(:Alerted)
      @db.delete(:Charset)
      @db.delete(:Config)
      @db.delete(:WaitingMembers)
      @db.delete(:WaitingMessage)
      @logger.log("[#{@name}]: ML Closed")
    end

    private

    def self.get_name(address)
      raise InvalidMLName if /@.*@/ =~ address
      name, host = address.split('@')
      raise InvalidMLName if ! valid_name?(name)
      return name, host
    end

    def self.valid_name? (name)
      # Do not allow '_' and '.' for the name.
      return /\A[0-9a-zA-Z-]+\z/ =~ name
    end

    def self.generate_return_address(address, use_qmail_verp = false)
      name, domain = Group.get_name(address)

      # e.g. <foo=return=@quickml.com-@[]>
      return "#{name}=return=@#{domain}-@[]" if use_qmail_verp

      # e.g. <foo=return@quickml.com>
      return "#{name}=return@#{domain}"
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-module-ml'
  $test = true
end

if defined?($test) && $test
  class TestGroup < Test::Unit::TestCase
    include TestModuleML

    def setup_group
      return QuickML::Group.new(@ml_config, 'test@example.com')
    end

    def test_class_method
      c = QuickML::Group

      # test_get_name
      ok_eq(["test", "example.com"], c.get_name('test@example.com'))

      # test_vaild_name
      ok_eq(true,  !!c.valid_name?('t'))
      ok_eq(true,  !!c.valid_name?('t-t'))
      ok_eq(false, !!c.valid_name?('t_t'))
      ok_eq(false, !!c.valid_name?('t.t'))
      ok_eq(false, !!c.valid_name?('test@example.com'))
      ok_eq(false, !!c.valid_name?('test@qwik@jp'))
      ok_eq(true,  !!c.valid_name?('test'))
      ok_eq(false, !!c.valid_name?('te.st'))

      # test_generate_return_address
      ok_eq("test=return@example.com",
	    c.generate_return_address('test@example.com'))
      ok_eq("test=return=@example.com-@[]",
	    c.generate_return_address('test@example.com', true))
    end

    def test_all
      group = setup_group

      # test_attr
      ok_eq('test', group.name)
      ok_eq('test@example.com', group.address)
      ok_eq("test=return@example.com", group.return_address)
      ok_eq(0, group.count)
      ok_eq(nil, group.charset)
    end
  end
end
