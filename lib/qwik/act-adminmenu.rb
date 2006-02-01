#
# Copyright (C) 2003-2006 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    def plg_menu(cmd, msg=nil)
      return if @req.user.nil?
      return if ! defined?(@req.base) || @req.base.nil?
      return plg_act('new', cmd) if cmd == 'newpage'
      return plg_ext(cmd) if cmd == 'edit' || cmd == 'wysiwyg'
      return nil
    end

    def plg_act(act, msg=act)
      return [:a, {:href=>'.'+act}, _(msg)]
    end

    def plg_ext(ext, msg=ext)
      return [:a, {:href=>@req.base+'.'+ext}, _(msg)]
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

    def test_admin_menu
      ok_wi([:a, {:href=>'.new'}, 'newpage'], "{{menu(newpage)}}")
      ok_wi([:a, {:href=>'1.edit'}, 'edit'], "{{menu(edit)}}")
      ok_wi([], "{{menu(nosuchmenu)}}")
      # test for not logined mode
      #ok_wi('', "{{menu(newpage)}}", nil)
      #ok_wi('', "{{menu(edit)}}", nil)
      #ok_wi('', "{{menu(nosuchmenu)}}", nil)
    end
  end
end
