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
      files2 = %w{
_GroupMembers.txt
_GroupCount.txt
_GroupConfig.txt
_GroupCharset.txt
_GroupAlerted.txt
_GroupForward.txt
_GroupPermanent.txt
_GroupUnlimited.txt
_GroupWaitingMembers.txt
_GroupWaitingMessage.txt
}

      farm = @memory.farm
      ul = [:ul]

      farm.list.each {|sitename|
#        next unless /\A[0-9]/ =~ sitename

        sitepath = "#{@config.sites_dir}/#{sitename}".path

        li = [:li]

        same = true
        notsamefilename = ""
        files1.each_with_index {|f1, i|
          f2 = files2[i]
          p1 = (sitepath + f1)
          p2 = (sitepath + f2)
          if p1.exist? and p2.exist?
            str1 = p1.read
            str2 = p2.read
            if str1 != str2
              same = false
              notsamefilename = f1
            end
          end
        }

        if same
#          li << "allsame "
        else
          li << "notsame! #{notsamefilename}"

        t1 = (sitepath + ",members").mtime.to_i
        t2 = (sitepath + "_GroupMembers.txt").mtime.to_i
        li << "samemtime " if t1 == t2
        li << "t1 is new " if t1 > t2
        li << "t2 is new " if t1 < t2
          li << "diff is #{t1 - t2} "

          li << [:a, {:href=>"/#{sitename}/"}, "/#{sitename}/"]
          ul << li
        end

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
      ok_title("Site list.")
    end
  end
end
