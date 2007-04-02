# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/resolve-tdiary'
require 'qwik/act-basic'
require 'qwik/common-resolve'
require 'qwik/site-resolve'

module Qwik
  class Resolver
    def self.resolve(site, action, wabisabi)
      wabisabi ||= []
      wabisabi = wabisabi.deep_copy
      wabisabi.make_index
      wabisabi = site.resolve_all_ref(wabisabi)
      wabisabi = action.resolve_all_plugin(wabisabi)
      return wabisabi
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  require 'qwik/test-module-public'

  class TestResolveEtc < Test::Unit::TestCase
    include TestSession

    def test_all
      # test_br
      ok_wi [:p, 't', [:br], 's'], "t~\ns\n"
      eq "\342\200\276", '~'.set_sourcecode_charset.to_utf8	# test bug

      # test_resolve_ref
      ok_wi [:p, [:a, {:href=>'FrontPage.html'}, 'FrontPage']],
	    '[[FrontPage]]'
      ok_wi [:p, [:a, {:href=>'FrontPage.html'}, 't']], '[[t|FrontPage]]'
      page = @site.create_new
      page.store '*‚ '
      ok_wi [:p, [:a, {:href=>'2.html'}, '‚ ']], "[[2]]"
      ok_wi [:p, [:a, {:href=>'2.html'}, '‚ ']], '[[‚ ]]'

      # test_resolve_plugin
      ok_wi [:p, [:em, 't']], "''t''"
      ok_wi [:p, [:em, '']], "''{{qwik_null}}''"
      ok_wi [:p, [:strong, 't']], "'''t'''"
      ok_wi [:p, [:strong, '']], "'''{{qwik_null}}'''"
      ok_wi [:span, {:class=>"plg_error"}, "nosuch plugin | ",
	[:strong, "nosuchplugin"]], '{{nosuchplugin}}'

      ok_wi [:p, 'a ', ''], 'a {{qwik_null}}'
      ok_wi [:p, 'a ', '', ' b'], 'a {{qwik_null}} b'
    end
  end

  class TestFormatter < Test::Unit::TestCase
    include TestSession


    def test_all1b
      res = session

      # test_plugin_link
      ok_wi [:p, [:a, {:href=>".recent"}, ".recent"]], '[[.recent]]'
      ok_wi "<p><a href=\".recent\">RecentList</a></p>",
	    '[[RecentList|.recent]]'
      ok_wi "<p><a href=\".rss\">.rss</a></p>", '[[.rss]]' # not use for now
      ok_wi "<p><a href=\".attach\">.attach</a></p>", '[[.attach]]'
      ok_wi "<p><a href=\".attach/t.txt\">.attach/t.txt</a></p>",
	    '[[.attach/t.txt]]'
      ok_wi "<p><a href=\".attach/s t.txt\">.attach/s t.txt</a></p>",
	    '[[.attach/s t.txt]]'
    end

    def test_all2
      res = session

      # test_block
      ok_wi '<dl><dt>t</dt><dd>s</dd></dl>', ':t:s'
      ok_wi '<dl><dt>t</dt></dl>', ':t:'
      ok_wi '<dl><dt>t</dt></dl>', ':t'
      ok_wi '<blockquote><p>t</p></blockquote>', '> t'
      ok_wi '<blockquote><p>t</p></blockquote>', '>t'
      ok_wi '<table><tr><td>t</td><td>s</td></tr></table>', '|t|s|'

      # test_name
      #ok_wi "<h2><span class='date'/><span class='title'><a name='l0'> </a> t</span></h2>", '* t'

      # test_inline
      ok_wi '<p><em>t</em></p>', "''t''"
      ok_wi '<p><strong>t</strong></p>', "'''t'''"
    end

    def test_all3
      res = session

      # test_link
      ok_wi '<p>t</p>', 't'
      page = @site['FrontPage']
      page.store '*title'
      ok_wi "<p><a href=\"FrontPage.html\">title</a></p>", '[[FrontPage]]'
      page = @site.create('t')
      page.store 't2'
      ok_wi "<p><a href=\"t.html\">t</a></p>", '[[t]]'
      ok_wi "<p><a href=\"FrontPage.html\">t</a></p>", '[[t|FrontPage]]'
      ok_wi "<p><a href=\"t.html\">s</a></p>", '[[s|t]]'
      page = @site.create_new
      page.store '*‚ '
      ok_wi "<p><a href=\"2.html\">‚ </a></p>", "[[2]]"

      # test_find_title
      ok_wi "<p><a href=\"2.html\">‚ </a></p>", '[[‚ ]]'
    end
  end
end
