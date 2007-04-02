# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    def plg_thissitename
      return @site.title
    end

    def plg_thislist
      return @site.ml_address
    end

    # Thanks to Mr. Shuhei Yamamoto.
    def plg_ml_submit_form
      href = "/formmail.php?user=#{@req.user}&site=#{@site.sitename}"
      return [:a, {:href=>href, :target=>'_new'}, _('Mlcommit')]
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActMLSubmitForm < Test::Unit::TestCase
    include TestSession

    def test_all
      res = session

      # test_plg_thissitename
      eq '', @action.plg_thissitename

      # test_plg_thislist
      eq 'test@q.example.com', @action.plg_thislist

      # test_plg_ml_submit_form
      eq [:a, {:href=>"/formmail.php?user=user@e.com&site=test",
	  :target=>'_new'}, 'Mlcommit'],
	@action.plg_ml_submit_form
    end
  end
end
