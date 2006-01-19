#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '..' unless $LOAD_PATH.include?('..')
require 'qwik/test-common'

class BenchSession < Test::Unit::TestCase
  include TestSession

  def test_bench_session
    repeat = 10
    repeat = 100
    #repeat = 1000
    repeat = 1

    t_add_user

    repeat.times {
      res = session('/test/TextFormat.html')
      body = res.body.format_xml
     #ok_title("‘Ž®ˆê——Ú×”Å")
    }
  end
end
