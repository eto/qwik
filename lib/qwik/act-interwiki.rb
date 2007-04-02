# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    D_PluginInterWiki = {
      :dt => 'InterWiki plugin',
      :dd => 'Make a link for another Wiki.',
      :dc => "* Example
You can create a link to another Wiki easily.
 [[qwikjp:InstallOnDebian]]
[[qwikjp:InstallOnDebian]]
You'll see the link to InstallOnDebian page on qwik.jp.

 [[google:qwikWeb]]
[[google:qwikWeb]]
You can also create a link to search qwikWeb on Google.

You can edit the links on the Page [[_InterWikiName]].
"
    }

    D_PluginInterWiki_ja = {
      :dt => 'InterWikiプラグイン',
      :dd => 'Wiki間の相互接続をします。',
      :dc => "* 例
Wiki間の相互接続を行うための仕組みです。
 [[qwikjp:InstallOnDebian]]
[[qwikjp:InstallOnDebian]]
とすると、qwik.jp上のInstallOnDebianというページにリンクします。

 [[google:qwikWeb]]
[[google:qwikWeb]]
同様に、googleでqwikWebを検索するリンクを作れます。

リンク先は[[_InterWikiName]]を編集して変えられます。
"
    }

    def plg_interwiki(arg, *d)
      wiki, pagename = arg.split(':')
      return if pagename.nil?
      text = "#{wiki}:#{pagename}"
      text = yield if block_given?
      iw = @site.interwiki
      href = iw.href(wiki, pagename)

      return [:span, {:class=>'interwiki'}, text] if href.nil?
      [:a, {:href=>href, :class=>'interwiki'}, text]
    end
  end

  class Site
    def interwiki
      @interwiki = InterWiki.new(@config, self) unless defined? @interwiki
      @interwiki
    end
  end

  class InterWiki
    def initialize(config, site)
      @site = site
      @db = nil
    end

    def href(wiki, pagename)
      iw = db[wiki]
      return nil if iw.nil?
      url, encoding = iw

      pagename.set_page_charset

      case encoding
      when 'sjis' then pagename = pagename.to_sjis.escape
      when 'euc'  then pagename = pagename.to_euc.escape
      when 'utf8' then pagename = pagename.to_utf8.escape
      end
      return url.sub(/\$1/, pagename) if url.index("$1")
      url+pagename
    end

    private

    def db
      return @db if @db
      page = get_page
      @db = page.wikidb
      @db
    end

    def get_page
      k = 'InterWikiName'
      return @site[k] if @site.exist?(k)
      k = "_#{k}"
      return @site[k] if @site.exist?(k)
      return @site.create(k)
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActInterWiki < Test::Unit::TestCase
    include TestSession

    def test_all
      page = @site.create('_InterWikiName')

      # test_interwiki
      page.store(',Test,http://example.com/?q=,sjis')
      ok_wi([:p, [:a, {:href=>'http://example.com/?q=t',
		  :class=>'interwiki'}, 'Test:t']], '[[Test:t]]')
      ok_eq([:a, {:href=>'http://example.com/?q=t',
		:class=>'interwiki'}, 'Test:t'],
	    @action.plg_interwiki('Test:t'))
      ok_eq([:a, {:href=>'http://example.com/?q=t',
		:class=>'interwiki'}, 'content\n'],
	    @action.plg_interwiki('Test:t') { 'content\n' })
      ok_wi([:p, [:a, {:href=>'http://example.com/?q=t',
		  :class=>'interwiki'}, 'text']], '[[text|Test:t]]')
      ok_wi([:p, [:span, {:class=>'interwiki'}, 'nosuchwiki:t']],
	    '[[nosuchwiki:t]]')

      # test_interwiki_kanji
      page.store(<<'EOM')
,SJIS,http://example.com/?q=,sjis
,EUC,http://example.com/?q=,euc
,UTF8,http://example.com/?q=,utf8
EOM
      ok_wi([:p, [:a, {:href=>'http://example.com/?q=%8E%9A',
            :class=>'interwiki'}, 'SJIS:字']], '[[SJIS:字]]')
      ok_wi([:p, [:a, {:href=>'http://example.com/?q=%BB%FA',
            :class=>'interwiki'}, 'EUC:字']], '[[EUC:字]]')
      ok_wi([:p, [:a, {:href=>'http://example.com/?q=%E5%AD%97',
            :class=>'interwiki'},  'UTF8:字']], '[[UTF8:字]]')

      # test_interwiki_realuse
      page.store(<<'EOM')
,google,http://www.google.com/search?num=50&lr=lang_ja&q=,utf8
,isbn,http://www.amazon.co.jp/exec/obidos/ASIN/$1/ref=nosim/q02-22,raw
,amazon,http://www.amazon.co.jp/exec/obidos/external-search?tag=q02-22&keyword=$1&mode=blended,utf8
,hiki,http://www.namaraii.com/hiki/hiki.cgi?,euc
,yukiwiki,http://www.hyuki.com/yukiwiki/wiki.cgi?,euc
EOM
      ok_wi([:p, [:a, {:href=>"http://www.google.com/search?num=50&lr=lang_ja&q=%E5%AD%97", :class=>'interwiki'}, "google:字"]], "[[google:字]]")
      ok_wi([:p, [:a, {:href=>"http://www.google.com/search?num=50&lr=lang_ja&q=%3C", :class=>'interwiki'}, "google:<"]], "[[google:<]]")
      ok_wi([:p, [:a, {:href=>"http://www.amazon.co.jp/exec/obidos/ASIN/4797318325/ref=nosim/q02-22", :class=>'interwiki'}, 'isbn:4797318325']], "[[isbn:4797318325]]")
      ok_wi([:p, [:a, {:href=>"http://www.amazon.co.jp/exec/obidos/external-search?tag=q02-22&keyword=%E5%AD%97&mode=blended", :class=>'interwiki'}, "amazon:字"]], "[[amazon:字]]")
      ok_wi([:p, [:a, {:href=>"http://www.namaraii.com/hiki/hiki.cgi?%BB%FA", :class=>'interwiki'}, "hiki:字"]], "[[hiki:字]]")
      ok_wi([:p, [:a, {:href=>"http://www.hyuki.com/yukiwiki/wiki.cgi?%BB%FA", :class=>'interwiki'}, "yukiwiki:字"]], "[[yukiwiki:字]]")

      # test_interwiki_error
      ok_wi([:p, [:span, {:class=>'interwiki'}, 'a:b']], "[[a:b]]")
      ok_wi([:p, [:span, {:class=>'new'}, "\"D_R\", \"/v/w\"",
	   [:a, {:href=>".new?t=%22D_R%22%2C+%22%2Fv%2Fw%22"},
	     [:img, {:src=>'.theme/i/new.png', :alt=>'create'}]]]],
       "[[\"D_R\", \"/v/w\"]]")
      ok_wi([:p], "[[\"H_R\", \"h://e.c/\"]]")
    end

    def ok(e, w)
      ok_eq(e, Qwik::Resolver.resolve(@site, @action, w))
    end

    def test_res
      res = session

      ok([[:span, {:class=>'interwiki'}, 'Test:t']],
	 [[:plugin, {:method=>'interwiki', :param=>'Test:t'}]])
      page = @site.create('_InterWikiName')
      page.store(",Test,http://example.com/?q=,sjis")
      ok([[:a, {:href=>"http://example.com/?q=t",
	       :class=>'interwiki'}, 'Test:t']],
	 [[:plugin, {:method=>'interwiki', :param=>'Test:t'}]])

      # test_interwiki_error
      ok([],
	 [[:plugin, {:method=>'interwiki', :param=>"\"H_R\", \"h://e.c/\""},
	     '']])
    end
  end
end
