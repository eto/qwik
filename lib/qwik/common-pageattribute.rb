#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '..' unless $LOAD_PATH.include?('..')

module Qwik
  class Action
    def page_attribute(ext, msg, base=@req.base)
      return [:span, {:class=>'attribute'},
	  [:a, {:href=>base+'.'+ext}, msg]]
    end

    def plg_last_modified
      return if ! defined?(@req.base) || @req.base.nil?
      page = @site[@req.base]
      return if page.nil?
      date = page.mtime
      return [:span, {:class=>'attribute'}, _('Last modified'), ': ',
	[:em, date.ymd]]
    end

    def plg_generate_time
      return '' if @req.user.nil?
      diff = Time.now - @req.start_time
      diffsec = sprintf('%.2f', diff)
      return [:span, {:class=>'attribute'}, _('Generate time'), ': ',
	[:em, diffsec, _('sec.')]]
    end

    def plg_only_guest
      return nil if @req.user
      s = yield
      return if s.nil?
      return c_res(s)
    end

    def plg_only_member
      return nil if @req.user.nil?
      s = yield
      return if s.nil?
      return c_res(s)
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActAdminMenu < Test::Unit::TestCase
    include TestSession

    def test_all
      # test_last_modified
      ok_wi(/Last modified: /, '{{last_modified}}')

      # test_generate_time
      ok_wi(/Generate time: /, '{{generate_time}}')

      # test_only_member_or_guest
      t_site_open
      ok_wi([:p, 'm'], "{{only_member\nm\n}}")
      assert_path([], "{{only_member\nm\n}}", nil, "//div[@class='section']")
      ok_wi([], "{{only_guest\ng\n}}")
      assert_path([:p, 'g'], "{{only_guest\ng\n}}",
		  nil, "//div[@class='section']")
    end
  end
end
