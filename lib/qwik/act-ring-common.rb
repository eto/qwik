#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '../../lib' unless $LOAD_PATH.include?('../../lib')
require 'qwik/act-ring-catalog'

module Qwik
  class Action
    RING_MEMBER = 'RingMember'
    RING_INVITE_MEMBER = 'RingInvitedMember'
    RING_INVITE_MAIL_TEMPLATE = 'RingInviteMailTemplate'
    RING_PAGE_TEMPLATE = 'RingPageTemplate'
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActRingCommon < Test::Unit::TestCase
    include TestSession

    def test_all
      # not yet
    end
  end
end
