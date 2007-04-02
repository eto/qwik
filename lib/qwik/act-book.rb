# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    D_PluginBook = {
      :dt => 'Book and ISBN plugins',
      :dd => 'Add a link to a book or to search by a phrase.',
      :dc => "* Example
** ISBN plugin
Add a link to a book by isbn.
 {{isbn(4797318325)}}
{{isbn(4797318325)}}
 {{isbn_amazon(4797318325)}}
{{isbn_amazon(4797318325)}}
 {{isbn_amazon(4797318325,書名)}}
{{isbn_amazon(4797318325,書名)}}
** Book Serach plugin
 {{book_search(Wiki)}}
{{book_search(Wiki)}}
 {{book_search(ブログ)}}
{{book_search(ブログ)}}
You can edit the book stores list on [[_BookSearch]].
"
    }

    D_PluginBook_ja = {
      :dt => '本とISBNプラグイン',
      :dd => '本や本の検索へのリンクを作ります。',
      :dc => "* 例
** ISBNプラグイン
ISBNでリンクします。
 {{isbn(4797318325)}}
{{isbn(4797318325)}}
 {{isbn_amazon(4797318325)}}
{{isbn_amazon(4797318325)}}
 {{isbn_amazon(4797318325,書名)}}
{{isbn_amazon(4797318325,書名)}}
リンク先の一覧は、[[_IsbnLink]]で指定できます。
** 本の検索プラグイン。
本を検索します。
 {{book_search(Wiki)}}
{{book_search(Wiki)}}
 {{book_search(ブログ)}}
{{book_search(ブログ)}}
検索リンク先の一覧は、[[_BookSearch]]で指定できます。
"
    }

    BOOK_SEARCH = '_BookSearch'

    def plg_book(key)
      page = @site[BOOK_SEARCH]
      ar = []
      ar << "book:#{key} "
      page.wikidb.array.each {|name, args|
	url, encoding = args
	sk = key
	sk = sk.to_sjis.escape if encoding == 'sjis'
	sk = sk.to_euc.escape  if encoding == 'euc'
	sk = sk.to_utf8.escape if encoding == 'utf8'
	url = url.index("$1") ? url.sub(/\$1/, sk) : url+sk
	ar << [:a, {:href=>url}, name]
	ar << ' '
      }
      return [:div, {:class=>'box'}, ar]
    end
    alias plg_book_search plg_book

    def plg_isbn_amazon(isbn, t=nil)
      isbn = isbn.to_s
      msg = t
      msg = "isbn:#{isbn}" if t.nil?
      a = @site.siteconfig['aid']
      aid = "/#{a}" if a
      return [:a, {:href=>"http://www.amazon.co.jp/exec/obidos/ASIN/#{isbn}#{aid}/ref=nosim/"}, msg]
    end

    ISBN_LINK = '_IsbnLink'

    def plg_isbn(isbn, t=nil)
      isbn = isbn.to_s
      isbn1 = isbn.gsub(/ISBN/i, '')
      isbn2 = isbn1.gsub(/-/, '')
      a = @site.siteconfig['aid']
      aid = "/#{a}" if a

      link = @site[ISBN_LINK]
      db = link.wikidb
      ar = []

      msg = t
      msg = "isbn:#{isbn}" if t.nil?

      ar << msg
      ar << ' '

      db.array.each {|name, args|
	args = args.dup
	url = args.shift
	next if url.nil?

	url = url.sub_str('#{isbn1}', isbn1)
	url = url.sub_str('#{isbn2}', isbn2)
	url = url.sub_str('#{aid}',   aid)
	ar << [:a, {:href=>url}, name]
	ar << ' '
      }

      return [:div, {:class=>'box'}, ar]
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActBook < Test::Unit::TestCase
    include TestSession

    def test_book
      page = @site['_BookSearch']
      page.store(',utf8,http://example.com/utf8/,utf8
,sjis,http://example.com/sjis/,sjis
,euc,http://example.com/euc/,euc')

      ok_wi([:div, {:class=>'box'},
	      ['book:本 ',
		[:a, {:href=>'http://example.com/utf8/%E6%9C%AC'},
		  'utf8'], ' ',
		[:a, {:href=>'http://example.com/sjis/%96%7B'},
		  'sjis'], ' ',
		[:a, {:href=>'http://example.com/euc/%CB%DC'},
		  'euc'], ' ']],
	    '{{book_search(本)}}')

      # test_isbn
      ok_wi([:a, {:href=>'http://www.amazon.co.jp/exec/obidos/ASIN/4797318325/q02-22/ref=nosim/'}, 'isbn:4797318325'], '{{isbn_amazon(4797318325)}}')
      ok_wi([:a, {:href=>'http://www.amazon.co.jp/exec/obidos/ASIN/4797318325/q02-22/ref=nosim/'}, 't'], '{{isbn_amazon(4797318325,t)}}')

      page = @site['_IsbnLink']
      page.store(',i1,http://example.com/i1/#{isbn1}
,i2,http://example.com/i2/#{isbn2}
,aid,http://example.com/aid/#{isbn2}#{aid}
')

      ok_wi([:div, {:class=>'box'}, ['isbn:4797318325', ' ',
		[:a, {:href=>'http://example.com/i1/4797318325'}, 'i1'], ' ',
		[:a, {:href=>'http://example.com/i2/4797318325'}, 'i2'], ' ',
		[:a, {:href=>'http://example.com/aid/4797318325/q02-22'},
		  'aid'], ' ']],
	    '{{isbn(4797318325)}}')
    end
  end
end
