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
require 'qwik/group-db'

module QuickML
  class Group
    # ml-processor.rb:115:        ml.prepare_confirmation(@mail)
    def prepare_confirmation (mail)
      # Create empty ML files.
      @members.save

      waiting_message_put(mail.bare)
      str = waiting_message_get		# FIXME: Why?

      add_waiting_member(mail.from)
      mail.collect_cc.each {|address| 
        add_waiting_member(address)
      }
      send_confirmation(mail.from)
    end

    def validate_confirmation(time)
      return waiting_message_exist? && waiting_message_mtime.to_i == time.to_i
    end

    # ml-processor.rb:98:        ml.accept_confirmation
    def accept_confirmation
      # Add suspended members.
      waiting_members = (waiting_members_get || '').to_a.map {|line|
        line.chomp
      }
      waiting_members.each {|address|
        begin
          add_member(address)
        rescue TooManyMembers
        end
      }

      # Read suspended message.
      waiting_message = waiting_message_get || ''
      mail = Mail.create { waiting_message }

      submit(mail)	# Send it.

      waiting_members_delete
      waiting_message_delete
      @logger.log "[#{@name}]: Accept confirmation:  #{@address}"
    end

    private

    def confirmation_address
      t = waiting_message_mtime.to_i
      return "confirm+#{t}+#{@address}"
    end

    # waiting_message
    def waiting_message_exist?
      return @db.exist?(:WaitingMessage)
    end
    def waiting_message_mtime
      return @db.mtime(:WaitingMessage)
    end
    def waiting_message_put(content)
      @db.put(:WaitingMessage, content)
    end
    def waiting_message_get
      return @db.get(:WaitingMessage)
    end
    def waiting_message_delete
      @db.delete(:WaitingMessage)
    end

    # waiting_member
    def add_waiting_member (address)
      waiting_members_add(address+"\n")
    end
    def waiting_members_exist?
      return @db.exist?(:WaitingMembers)
    end
    def waiting_members_get
      return @db.get(:WaitingMembers)
    end
    def waiting_members_add(content)
      @db.add(:WaitingMembers, content)
    end
    def waiting_members_delete
      @db.delete(:WaitingMembers)
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-module-ml'
  $test = true
end

if defined?($test) && $test
  class TestGroupConfirmation < Test::Unit::TestCase
    include TestModuleML

    def setup_group
      return QuickML::Group.new(@ml_config, 'test@example.com')
    end

    def test_all
      group = setup_group

      t_make_readable(QuickML::Group, :db)

      # test_prepare_confirmation
      message =
'Date: Mon, 3 Feb 2001 12:34:56 +0900
From: user@e.com
To: test@example.com
Subject: create

Create a new mailing list.
'
      mail = QuickML::Mail.generate { message }
      group.prepare_confirmation(mail)
      ok_eq(message, group.db.get(:WaitingMessage))
      ok_eq("user@e.com\n", group.db.get(:WaitingMembers))

      # test_validate_confirmation
      t_make_public(QuickML::Group, :waiting_message_mtime)
      time = group.waiting_message_mtime
      ok_eq(true, group.validate_confirmation(time))

      # test_accept_confirmation
      t_make_public(QuickML::Group, :get_active_members)
      ok_eq([], group.get_active_members)
      group.accept_confirmation
      ok_eq(['user@e.com'], group.get_active_members)
    end
  end
end
