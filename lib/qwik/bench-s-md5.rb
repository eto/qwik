# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/test-common'
require 'qwik/act-md5'

class BenchMD5Session < Test::Unit::TestCase
  include TestSession

  def test_all
    repeat = 10
    repeat = 100
    repeat = 1000
    repeat = 10000
    repeat = 1

    t_add_user

    repeat.times {
      res = session('/test/TextFormat.md5')
      #body = res.body.format_xml
      #ok_title("‘Ž®ˆê——Ú×”Å")
      ok_eq('2ee66272e916d3c21c151920c94334aa', res.body)
    }
  end
end
