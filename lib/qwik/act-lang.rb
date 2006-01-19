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
    def plg_lang(lang)
      # lang should be only two letters length.
      return 'error' unless /\A[a-z][a-z]\z/ =~ lang

      alang = @req.accept_language[0]

      return '' unless alang && alang == lang

      s = yield
      return c_res(s)
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActLang < Test::Unit::TestCase
    include TestSession

    def test_lang
      ok_wi('error', "{{lang(nosuchlang)\na\n}}")
      ok_wi([""], "{{lang(ja)\nj\n}}")
     #ok_wi([], "{{lang(ja)\nj\n}}")
      ok_wi([:p, 'e'], "{{lang(en)\ne\n}}")

      ok_wi([:p, 'j'], "{{lang(ja)\nj\n}}") {|req|
	req.accept_language = ['ja']
      }
      ok_wi("", "{{lang(en)\ne\n}}") {|req|
	req.accept_language = ['ja']
      }
    end
  end
end
