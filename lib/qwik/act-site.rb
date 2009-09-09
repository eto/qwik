# Copyright (C) 2003-2009 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require "qwik/act-status"

module Qwik
  class Action
    def act_site
      c_require_login
      return c_nerror("You are not administrator.") if ! is_administrator?

      farm = @memory.farm
      ul = [:ul]
      farm.list.each {|sitename|
	site = farm.get_site(sitename)
        ul << [:li, sitename]
      }

      return c_plain(_("Site list.")) {
	[[:h2, _("Site list.")],
	  [:div, ul]]
      }
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActSite < Test::Unit::TestCase
    include TestSession

    def test_all
      res = session
      #ok_title("Site list..")
    end
  end
end
