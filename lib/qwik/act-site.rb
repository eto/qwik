# Copyright (C) 2003-2009 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require "qwik/act-status"

module Qwik
  class Action
    def site_delete_unused_config_files
      files1 = %w{
,members
,count
,config
,charset
,alerted
,forward
,permanent
,unlimited
,waiting-members
,waiting-message
}

        files1.each {|f1, i|
          p1 = (sitepath + f1)
          if p1.exist?
            p1.unlink
            li << "deleted. "
            li << [:a, {:href=>"/#{sitename}/"}, "/#{sitename}/"]
            ul << li
          end
        }
    end

    def act_site
      c_require_login
      return c_nerror("You are not administrator.") if ! is_administrator?

      farm = @memory.farm
      ul = [:ul]

      farm.list.each {|sitename|
#        next unless /\A[0-9]/ =~ sitename

#        site = farm.get_site(sitename)
        sitepath = "#{@config.sites_dir}/#{sitename}".path

        li = [:li]
        li << [:a, {:href=>"/#{sitename}/"}, "/#{sitename}/"]
        ul << li
      }

      div = [:div, {:class => 'day'},
	[:div, {:class => 'section'}, 
          [:h2, _("Site list.")], ul]]

      return c_plain(_("Site list. __qwik_page_generate_time__ sec. past.")) {
	div
      }
    end
  end
end

if $0 == __FILE__
  require "pp"
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActSite < Test::Unit::TestCase
    include TestSession

    def test_all
      t_add_user

      file = @config.etc_dir.path + "administrator.txt"
      file.write("")

      res = session("/test/.site")
      ok_title("You are not administrator.")

      file.write("user@e.com\n")

      res = session("/test/.site")
      ok_title "Site list. __qwik_page_generate_time__ sec. past."
    end
  end
end
