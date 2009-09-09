# Copyright (C) 2003-2009 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require "qwik/act-status"

module Qwik
  class Action
    def nu_create_site_list
      cache_path = @config.sites_dir.path + ".cache"
      cache_path.mkdir if ! cache_path.exist?

      out = cache_path + "sitelist.txt"

      farm = @memory.farm
      str = ""
      farm.list.each {|sitename|
        str << "#{sitename}\n"
      }

      out.write(str)
    end

    def act_site
      c_require_login
      return c_nerror("You are not administrator.") if ! is_administrator?

      #create_site_list
      #sitelist_path = @config.sites_dir.path + ".cache/sitelist.txt"
      #str = sitelist_path.read

      farm = @memory.farm
      ul = [:ul]
      farm.list.each {|sitename|
        site = farm.get_site(sitename)
        li = [:li]
        li << "open " if site.is_open?
        li << "forward " if site.forward?
        li << "permanent " if site.permanent?
        #li << "inactive" if site.inactive?
        li << [:a, {:href=>"/#{sitename}/"}, "/#{sitename}/"]
        ul << li
      }

      div = [:div, {:class => 'day'},
	[:div, {:class => 'section'}, 
          [:h2, _("Site list.")], ul]]

      return c_plain(_("Site list.")) {
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
      ok_title("Site list.")
    end
  end
end
