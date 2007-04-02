# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    D_PluginPassword = {
      :dt => 'Set password plugin',
      :dd => 'You can lock a page by a password.',
      :dc => "* Example
 {{password(\"a password string\")}}
You can lock your page by setting this password plugin.

'''Warning:''' There is no way to unlock the page.
If you forgot your password, you can not edit the page.
Please be careful.
"
    }

    D_PluginPassword_ja = {
      :dt => 'パスワード保護プラグイン',
      :dd => 'ページをパスワードで保護することができます。',
      :dc => "* 例
 {{password(\"a password string\")}}
このようなプラグインをページに埋込むと、
そのページはパスワードで保護されます。

'''注意:''' 現在はまだパスワードを解除する方法を提供してません。
もしパスワードを忘れた場合は、ページを編集できなくなりますので、
気をつけてください。
"
    }

    def plg_password(pass=nil)
      # password plugin is parsed in act-edit.rb
      return nil
    end
  end

  # These methods will be used in ext_save
  class Page
    def get_password
      return Page.get_password(self.load)
    end

    def self.get_password(str)
      return $1 if str && /\{\{password\((.+)\)\}\}/ =~ str
      return nil
    end

    def self.embed_password(content)
      new_pass = get_password(content)
      return content if new_pass.nil?		# Nothing to embed.
      new_content = content.sub(/\{\{password\((.+)\)\}\}/) {
	"{{password(#{$1.md5hex})}}"
      }
      return new_content
    end

    def match_password?(v)
      old_pass_md5 = self.get_password
      return true if old_pass_md5.nil?		# No password.  Go on.
      new_pass_md5 = Page.get_password(v)	# assume already become md5
      return false if new_pass_md5.nil?		# Can not go if there is no pass
      return false if new_pass_md5 != old_pass_md5	# should be correct pass
      return true	# Go on.
    end
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

      eq 'test2', page.load
      # The text is rewrite to the text with embeded password.
      text = Qwik::Page.embed_password('take1 {{password(testpassword)}}')
      eq "take1 {{password(e16b2ab8d12314bf4efbd6203906ea6c)}}", text
      page.store(text)

      eq "e16b2ab8d12314bf4efbd6203906ea6c", page.get_password

      take2 = Qwik::Page.embed_password('take2 {{password(notcorrectpassword)}}')
      eq false, page.match_password?(take2)	# NG

      take3 = Qwik::Page.embed_password('take3 {{password(testpassword)}}')
      eq true, page.match_password?(take3)
      page.store(take3) # OK
      assert_match(/take3/, page.load)
      eq "take3 {{password(e16b2ab8d12314bf4efbd6203906ea6c)}}", page.load

      eq "e16b2ab8d12314bf4efbd6203906ea6c", page.get_password
      eq 'testpassword'.md5hex, page.get_password
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
      eq "t3\n{{password(098f6bcd4621d373cade4e832627b4f6)}}\n",
	page.load
    end
  end
end
