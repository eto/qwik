#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '..' unless $LOAD_PATH.include?('..')
require 'qwik/act-backup'

module Qwik
  class Action
    def plg_show_history
      return if @req.user.nil?
      return if !defined?(@req.base) || @req.base.nil?
      return page_attribute('history', _('Show history'))
    end

    def ext_history
      c_require_pagename
      c_require_member
      #c_require_page_exist # does not require the page is exist
      # because you can see the list of the page that is already deleted.

      return c_nerror('no path args') if 0 < @req.path_args.length
      return c_nerror('no ext args')  if 0 < @req.ext_args.length

=begin
      divs = []
      key = @req.base
      qp key
      @site.backupdb.each_by_key(key) {|v, time|
	res = [:div, {:class=>'period'}, c_res(v)]
	divs << [:div, {:class=>'era', :id=>time.to_i.to_s}, res]
      }
=end

      key = @req.base
      list = backup_list(@site, key)

      divs = list.map {|v, time|
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

      title = _('Time machine')+' | '+pagename

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

      ok_wi([:span, {:class=>'attribute'},
	      [:a, {:href=>'1.history'}, 'Show history']],
	    '{{show_history}}')

      page = @site['1']
      page.store('* t1') # store the first
      page.store('* t2') # store the second

      res = session('/test/1.html')
      ok_in(['t2'], '//title')

      res = session('/test/1.history')
      ok_in(['Time machine | 1'], '//title')
    end
  end
end