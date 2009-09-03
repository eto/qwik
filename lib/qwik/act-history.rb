# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/act-backup'

module Qwik
  class Action
    D_ExtHistory = {
      :dt => 'History mode',
      :dd => 'You can see the history of the page interactively.',
      :dc => "* How to
Go edit page, follow 'Time machine' link in the right side.
You see the interactive history of the page.
"
    }

    D_ExtHistory_ja = {
      :dt => 'ページの歴史モード',
      :dd => 'ページの歴史をインタラクティブに見ることができます。',
      :dc => "* 使い方
編集画面の右側に「タイムマシーン」というリンクがあります。
そのリンクより、ページの編集履歴をインタラクティブに見ることができます。
"
    }



    def plg_show_history
      return if @req.user.nil?
      return if ! defined?(@req.base) || @req.base.nil?
      return page_attribute('history', _('Show history'))
    end

    def ext_history
      c_require_pagename
      c_require_member
      return c_notice(_('Announcement')) {
	[[:h2, _('Announcement')],
	  [:p, "TimeMachine function is disabled for server issue."]]
      }
    end

    def nu_ext_history
      c_require_pagename
      c_require_member
      #c_require_page_exist
      # You can see the history of the deleted page.

      return c_nerror('no path args') if 0 < @req.path_args.length
      return c_nerror('no ext args')  if 0 < @req.ext_args.length

=begin
      divs = []
      key = @req.base
      @site.backupdb.each_by_key(key) {|v, time|
	res = [:div, {:class=>'period'}, c_res(v)]
	divs << [:div, {:class=>'era', :id=>time.to_i.to_s}, res]
      }
=end

      key = @req.base
      list = backup_list(@site, key)

      divs = list.map {|v, time|
	v = @site.backupdb.get(key, time)
	[:div, {:class=>'era', :id=>time.to_s},
	  [:div, {:class=>'period'}, c_res(v)]]
      }

      return history_show(@req.base, divs)
    end

    def history_show(pagename, divs)
      ar = []

      ar << [:style, "@import '.theme/css/wema.css';"]

      handle = [:div, {:class=>'wema', :id=>'curosr',
	  :style=>'left:0px;top:0px;'},
	[:div, {:class=>'menubar'},
	  [:span, {:class=>'handle'}, 'handle'],
	  [:span, {:class=>'close'}, [:a, {:href=>'#'}, ' X ']]], # noop
	[:div, {:class=>'cont'},
	  [:span, {:id=>'indicator'}, _('Move this')]]]
      ar << handle

      section = []
      section << [:div, {:id=>'eratable'}, '']
      section << divs
      section << [:div, {:id=>'lines'}, '']
      ar << [:div, {:class=>'day'},
	[:div, {:class=>'section'},
	  section]]

      ar << [:script,
	{:type=>'text/javascript', :src=>'.theme/js/wema.js'}, '']
      ar << [:script,
	{:type=>'text/javascript',:src=>'.theme/js/history.js'}, '']

      title = _('Time machine')+" | #{pagename}"

      return c_plain(title) { ar }
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActHistory < Test::Unit::TestCase
    include TestSession

    def test_act_history
      t_add_user

      ok_wi [:span, {:class=>'attribute'},
	[:a, {:href=>'1.history'}, 'Show history']],
	'{{show_history}}'

      page = @site['1']
      page.store('* t1')	# store the first
      page.store('* t2')	# store the second

      res = session '/test/1.html'
      ok_in ['t2'], '//title'

      res = session '/test/1.history'
#      ok_in ['Time machine | 1'], '//title'
    end
  end
end
