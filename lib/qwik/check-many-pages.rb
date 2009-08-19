# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class CheckManyPages < Test::Unit::TestCase
    include TestSession

    def test_all
      t_add_user

#      page = @site.create_new
#      page.store("* t")
#      res = session('/test/1.html')
#      ok_title('t')
#      page = @site['1']

#      num = 200
      num = 10
      (1..num).each {|n|
	page = @site.create_new
	page.store("* t#{n}")
      }
      (1..num).each {|n|
	res = session("/test/#{n}.html")
	ok_title("t#{n}")
      }

#100 Finished in 28.170425 seconds.

#100  Finished in 9.680146 seconds.
#200  Finished in 28.170425 seconds.
#1000 Finished in 603.93911 seconds.

#100 Finished in 4.67007 seconds.
#200 Finished in 9.030136 seconds.
#1000 Finished in 47.230712 seconds.
    end
  end
end
