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
    D_password = {
      :dt => 'Set password plugin',
      :dd => 'You can lock a page by a password.',
      :dc => "* Example
 {{password(\"a password string\")}}
You can lock your page by setting this password plugin.

'''Warning:''' There is no way to unlock the page.
If you forgot your password, you can not edit the page anymorre.
Be careful.
" }

    def plg_password(pass=nil)
      # password plugin is parsed in act-edit.rb
      return nil
    end
  end

  module SitePassword # has relation with cmd_save
    def password
      return SitePassword.get_pass(load)
    end

    def have_password?
      return (self.password != nil)
    end

    def embed_password(v)
      new_pass = SitePassword.get_pass(v)
      return v if new_pass.nil?
      return v.sub(/\{\{password\((.+)\)\}\}/) {
	"{{password(#{$1.md5hex})}}"
      }
    end

    def match_password?(v)
      return true if ! have_password?	# go on
      old_pass_md5 = self.password
      new_pass_md5 = SitePassword.get_pass(v)	# assume already become md5
      return false if ! new_pass_md5	# can not go if there is no pass
      return false if new_pass_md5 != old_pass_md5	# should be correct pass
      return true	# go on
    end

    def self.get_pass(str)
      return $1 if str && /\{\{password\((.+)\)\}\}/ =~ str
      return nil
    end
  end

  class Page
    include SitePassword
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActPassword < Test::Unit::TestCase
    include TestSession

    def test_password
      @pages = Qwik::Pages.new(@config, @dir)
      page = @pages.create('1')
      page.store('test2')
      ok_eq('test2', page.load)
      # The text is rewrite to the text with embeded password.
      text = page.embed_password('take1 {{password(testpassword)}}')
      assert_match(/\{\{password\(/, text)
      # There should be no original password.
      assert_no_match(/testpassword/, text)
      page.store(text)
      ok_eq(true, page.have_password?)

      take2 = page.embed_password('take2 {{password(notcorrectpassword)}}')
      ok_eq(false, page.match_password?(take2)) # NG

      take3 = page.embed_password('take3 {{password(testpassword)}}')
      ok_eq(true, page.match_password?(take3))
      page.store(take3) # OK
      assert_match(/take3/, page.load)

      ok_eq(true, page.have_password?)
      ok_eq(32, page.password.length)
      ok_eq('testpassword'.md5hex, page.password)
      @pages.erase_all
    end

    def test_usecase_password
      t_add_user

      page = @site.create_new
      page.store("test\n")
      res = session('/test/1.html')
      ok_in(['test'], "//div[@class='section']/p")

      res = session('/test/1.edit')
      assert_text("test\n", 'textarea')

      res = session('/test/1.save?contents=test%0A{{password(test)}}%0A')
      ok_title('Page is saved.')

      res = session('/test/1.edit')
      assert_text("test\n{{password(098f6bcd4621d373cade4e832627b4f6)}}\n",
		  'textarea')

      res = session('/test/1.save?contents=t2%0A{{password(test)}}%0A')
      ok_title('Page is saved.')

      res = session('/test/1.edit')
      assert_text("t2\n{{password(098f6bcd4621d373cade4e832627b4f6)}}\n",
		  'textarea')

      res = session('/test/1.save?contents=t3%0A{{password(nomatch)}}%0A')
      ok_in([[:tt, '{{password('], 'Password', [:tt, ')}}']],
	    "//div[@class='section']/p")
      assert_text("t3\n{{password(nomatch)}}\n", 'textarea')

      res = session('/test/1.save?contents=t3%0A{{password(test)}}%0A')
      ok_title('Page is saved.')
      ok_eq("t3\n{{password(098f6bcd4621d373cade4e832627b4f6)}}\n",
	    page.load)
    end
  end
end
