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
    def pre_act_redirect
      url = @req.query['url']
      if url
	return c_notice('redirect', url) {
	  [:p, 'redirect', [:br], [:strong, url]]
	}
      end
      return old_redirect
    end

    def old_redirect
      if @req.unparsed_uri
	url = @req.unparsed_uri
      else
	url = '/'+@req.path_args[0]
      end

      if /\A\/((?:http|https|ftp|file)):\// =~ url
	scheme = $1
	url = url.sub(/\A\/#{scheme}:\//, "#{scheme}:/")
      end

      c_notice('redirect', url) {
	[:p, 'redirect', [:br], [:strong, url]]
      }
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActRedirect < Test::Unit::TestCase
    include TestSession

    def test_redirect
      res = session("/test/.redirect?url=http://e.com/")
      ok_title('redirect')
      ok_xp([:p, 'redirect', [:br], [:strong, 'http://e.com/']], '//p')
    end

    def test_old_redirect
      res = session('/http://e.com/')
      ok_title('redirect')
      ok_in(['http://e.com/'], '//p/strong')

      res = session('/http://e.com')
      ok_in(['http://e.com'], '//p/strong')

      res = session('/https://e.com/')
      ok_in(['https://e.com/'], '//p/strong')

      res = session('/ftp://e.com/')
      ok_in(['ftp://e.com/'], '//p/strong')
    end

    def test_normal_external_links
      ok_wi([:p, [:a, {:class=>'external', :href=>'http://example.com/'},
		'http://example.com/']], "[[http://example.com/]]")
      ok_wi([:p, [:a, {:href=>'http://example.com/', :class=>'external'},
		'http://example.com/']], 'http://example.com/')
      ok_wi([:p,[:a, {:href=>'http://example.com/', :class=>'external'}, 't']],
	    "[[t|http://example.com/]]")
    end

    def ok_res(e, w, site=@site)
      res = session
      w = Qwik::Resolver.resolve(site, @action, w)
      ok_eq(e, w)
    end

    def test_redirect_config
      ok_res([[:a, {:href=>'http://e.com/', :class=>'external'}, 'e']],
	     [[:a, {:href=>'http://e.com/'}, 'e']])

      page = @site['_SiteConfig']
      page.store(':redirect:true')
      ok_res([[:a, {:href=>".redirect?url=http://e.com/", :class=>'external'},
		 'e']],
	     [[:a, {:href=>'http://e.com/'}, 'e']])
    end

    # can not test this for now...
    def nu_test_with_query
      res = session("/http://e.com/?q=a&p=b")
      assert_text("redirect : http://e.com/?q=a&p=b", 'title')
    end

    #def test_redirect
    #  @req.parse_path('/http://e.com/')
    #  ok_eq(['redirect', ['http://e.com/']], [@req.plugin, @req.path_args])
    #end
  end
end