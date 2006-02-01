#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'
require 'qwik/wabisabi-diff'

module Qwik
  class Action
    D_backup = {
      :dt => 'Show Backup pages',
      :dd => 'You can see backup files.',
      :dc => "* Example
{{backup_list}}
 {{backup_list}}
" }

    def plg_backup_list
      return if @req.user.nil?
      return if ! defined?(@req.base) || @req.base.nil?
      return page_attribute('backup', _('Show backup'))
    end

    def ext_backup
      c_require_pagename
      c_require_member
      #c_require_page_exist # does not require the page is exist
      # because you can see the list of the page that is already deleted.
      c_require_no_path_args

      args = @req.ext_args
      if 0 < args.length # has target
	return backup_show(@site, @req.base, args)
      end

      return backup_list_page(@site, @req.base)
    end

    def backup_show(site, key, args)
      page = site[key]

      # error check
      return c_nerror('only one time stamp') if 1 < args.length

      # should be a number
      time = args.shift
      return c_nerror('should be number') unless /\A[0-9]+\z/ =~ time

      # Is the backup exist?
      time = Time.at(time.to_i)
      unless site.backupdb.exist?(key, time)
	return c_notfound('not found')
      end

      # Get the old content.
      str = site.backupdb.get(key, time)

      # Get the list.
      list = backup_list(site, key)

      # Get the index of the content.
      index = nil
      list.each_with_index {|a, i|
	if a[1] == time.to_i
	  index = i
	end
      }
      return c_notfound("no data?") if index.nil?

      msg = ''
      if index == 0
	msg = [:p, _('The first page.')]
      else
	diff = backup_diff(list, index-1, index)
	msg = [:div, {:class=>'differ'}, *diff]
      end

      return c_plain(key+' @ '+time.ymdax){
	[[:div, {:class=>'day'},
	    [:h2, _('Diff from the previous page')],
	    [:div, {:class=>'section'},
	      msg]],
	  [:div, {:class=>'day'},
	    [:h2, _('Original data')],
	    [:div, {:class=>'section'},
	      [:pre, str]]]]
      }
    end

    def backup_list(site, key)
      list = []
      site.backupdb.each_by_key(key) {|v, time|
	list << [v, time.to_i]
      }
      return list
    end

    def backup_diff(list, last, now)
      s1, t1 = list[last]
      s2, t2 = list[now]
      return DiffGenerator.generate(s1, s2)
    end

    def backup_list_page(site, key)
      list = backup_list(site, key)

      ul = list.map {|v, time|
	[:li, [:a, {:href=>key+'.'+time.to_s+'.backup'},
	    Time.at(time).format_date]]
      }
      if 0 < ul.length
	ul.last << ' '+_("<-")+' '+ _('newest')
      end

      return c_plain(_('backup list')) {
	[:div, {:class=>'day'},
	  [:div, {:class=>'section'},
	    [:ul, ul]]]
      }
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActBackup < Test::Unit::TestCase
    include TestSession

    def test_plg_backup_list
      ok_wi([:span, {:class=>'attribute'},
	      [:a, {:href=>'1.backup'}, 'Show backup']],
	    "{{backup_list}}")
    end

    def test_act_backup2
      #return if $0 != __FILE__

      # Only members can see the page.
      res = session('/test/1.html')
      ok_title('Member Only')
      res = session('/test/1.backup')
      ok_title('Member Only')

      t_add_user

      # You can see backup page even if the page does not exist.
      res = session('/test/1.html')
      ok_title('Page not found.')
      res = session('/test/1.backup')
      ok_in(['backup list'], '//title')

      page = @site.create_new
      page.put_with_time('t', 0)

      res = session('/test/1.html')
      ok_title('1')
      res = session('/test/1.backup')
      ok_in(['backup list'], '//title')

      # Error check.
      res = session('/test/1.backup/0')
      ok_title('Require no path args')
      res = session('/test/1.100.200.backup')
      ok_title('only one time stamp')
      res = session('/test/1.hoge.backup')
      ok_title('should be number')

      list = @action.backup_list(@site, '1')
      ok_eq('t', list[0][0])
      ok_eq('', list[1][0])
      ok_eq(nil, list[2])

      t1 = list[0][1]
      res = session("/test/1.#{t1}.backup")
      assert_text(/\A1 @ /, 'title')
      assert_text('t', 'pre')

      # Edit the page again.
      page.put_with_time('t2', 1)

      list = @action.backup_list(@site, '1')
      ok_eq('t', list[0][0])
      ok_eq('t2', list[1][0])
      ok_eq('', list[2][0])
      ok_eq(nil, list[3])

      diff = @action.backup_diff(list, 0, 1)
      ok_eq([[:del, 't'], [:br], [:ins, 't2'], [:br]], diff)

      t2 = list[1][1]
      session("/test/1.#{t2}.backup")
      assert_text(/\A1 @ /, 'title')
      assert_text('t2', 'pre')
      ok_in([[:del, 't'], [:br], [:ins, 't2'], [:br]],
	    "//div[@class='differ']")

      # Edit the page again. The 3rd times.
      page.put_with_time('t3', 2)

      list = @action.backup_list(@site, '1')
      ok_eq('t', list[0][0])
      ok_eq('t2', list[1][0])
      ok_eq('t3', list[2][0])
      ok_eq('', list[3][0])
      ok_eq(nil, list[4])

      diff = @action.backup_diff(list, 1, 2)
      ok_eq([[:del, 't2'], [:br], [:ins, 't3'], [:br]], diff)

      t3 = list[2][1]
      session("/test/1.#{t3}.backup")
      assert_text('t3', 'pre')
      ok_in([[:del, 't2'], [:br], [:ins, 't3'], [:br]],
		"//div[@class='differ']")
    end
  end
end
