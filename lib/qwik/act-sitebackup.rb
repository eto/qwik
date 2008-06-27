# -*- coding: cp932 -*-
# Copyright (C) 2007 Tsuyoshi Fukui, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

module Qwik
  TAR_COMMAND = '/usr/bin/tar'	# path to tar command (GNU version is required)
  if FileTest.executable?(TAR_COMMAND) 
    $have_tar_command = true
  else
    $have_tar_command = false
  end

  class Action

    D_SiteBackup = {
      :dt => 'Site backup',
      :dd => 'You can obtain a tgz(tar.gz) backup at the site content.',
      :dc => '* Example
{{tgz}}

You can get a tgz(tar.gz) archive of all data of this Wiki site.

You can extract the package and place them on your qwikWeb data directory
to move your site.

At first click, it displays archiving process.
And then, you can reload or back-and-click again to download the archive file.

If anything is modifed on the site, it reprodued with clicking this link.
'
    }

    D_SiteBackup_ja = {
      :dt => 'サイト・バックアップ',
      :dd => 'サイト・バックアップを取得できます。',
      :dc => '* 使い方
{{tgz}}

このリンクから、サイトの内容まるごと全部(添付ファイル含む)を一つのアーカイブにして
ダウンロードできます。

展開してqwikWebのdataディレクトリに置けば，サイトをそのまま移行することができます．

最初の一回目は、アーカイブ作成のためのプロセスが実行されます。
作成が終わってからリロードするか、ブラウザから元のページに戻って
もう一度リンクをクリックすると、アーカイブをダウンロードすることができます。

サイトの内容が更新された後、このリンクを再度クリックすると、アーカイブも再作成されます。
'
    }

    def plg_tgz
      return "no tar command" if ! $have_tar_command
      return page_attribute('tgz', _('Site backup'), @site.sitename)
    end

    def ext_tgz
      return c_nerror("no tar command") if ! $have_tar_command
      c_require_member
      c_require_base_is_sitename

      # send file if latest
      if tgz_is_new?
	return c_simple_send(tgz_file_path, "application/gzip")
      end

      c_set_contenttype("text/plain")
      c_set_no_cache
      c_set_body(tgz_create)
    end

    def tgz_create
      cmd = "#{TAR_COMMAND} -zvc -C #{@config.sites_dir} -f #{tgz_file_path} " +
	"--exclude .cache --exclude .svn #{@site.sitename}"
      io = IO.popen(cmd)
      return io
    end

    require 'find'
    def tgz_site_lastmod
      ar = []
      @site.path.find do |p|
	Find.prune if p.basename.to_s == '.cache' or p.basename.to_s == '.svn'
	ar << p.mtime
      end
      ar.max
    end

    def tgz_is_new?
      unless tgz_file_path.exist?
	return false
      end
      tgz_file_path.mtime >= tgz_site_lastmod
    end

    def tgz_file_path
      @site.cache_path.check_directory
      @site.cache_path + "#{@site.sitename}.tgz"
    end

  end
end

if $0 == __FILE__
  $LOAD_PATH << '..' unless $LOAD_PATH.include? '..'
  require 'qwik/test-common'
  require 'qwik/util-pathname'
  $test = true
end

if defined?($test) && $test
  class TestSiteBackup < Test::Unit::TestCase
    include TestSession

    def test_plg_tgz
      ok_wi [:p, [:a, {:href=>'test.tgz'}, 'test.tgz']], '[[test.tgz]]'
      ok_wi [:span, {:class=>'attribute'},
	     [:a, {:href=>'test.tgz'}, 'Site backup']], '{{tgz}}'
    end

    def test_ext_tgz
      t_add_user

      # Add a page
      page = @site.create_new
      page.store '* あ'

      # Create backup
      res = session '/test/test.tgz'
      str_file_list = res.body.read
      ok_eq 'text/plain', res['Content-Type']
      assert_match %r(^test/$), str_file_list
      assert_match %r(^test/.backup/$), str_file_list
      assert_match %r(^test/.backup/\d{10}_1$), str_file_list
      assert_match %r(^test/.backup/\d{10}__SiteMember$), str_file_list
      assert_match %r(^test/1.txt$), str_file_list
      assert_match %r(^test/_SiteMember.txt$), str_file_list

#       assert_match %r(test/
# test/.backup/
# test/.backup/\d{10}_1
# test/.backup/\d{10}__SiteMember
# test/1.txt
# test/_SiteMember.txt
# ), str_file_list

      # Download backup
      res = session '/test/test.tgz'
      ok_eq 'application/gzip', res['Content-Type']

      # Compare with cache file
      content = (@site.cache_path + "test.tgz").read
      ok_eq(content, res.body)

      # Extract file list and compare it
      require 'open3'
      Open3.popen3("#{Qwik::TAR_COMMAND} ztf -") do |stdin, stdout, stderr|
	stdin.write res.body
	stdin.close
	ok_eq(str_file_list, stdout.read)
      end

      # Wait to make time lag between archive and site data
      sleep 1

      # Attach a file
      res = session('POST /test/1.files') {|req|
	req.query.update('content'=>t_make_content('t.txt', 't'))
      }
      ok_title('Attach file done')

      # Remake backup
      res = session '/test/test.tgz'
      str_file_list = res.body.read
      ok_eq 'text/plain', res['Content-Type']

      # Confirm that archive is updated
      assert_match %r(^test/$), str_file_list
      assert_match %r(^test/.backup/$), str_file_list
      assert_match %r(^test/.backup/\d{10}_1$), str_file_list
      assert_match %r(^test/.backup/\d{10}__SiteMember$), str_file_list
      assert_match %r(^test/.backup/\d{10}_1$), str_file_list
      assert_match %r(^test/.backup/\d{10}__SiteChanged$), str_file_list
      assert_match %r(^test/1.files/$), str_file_list
      assert_match %r(^test/1.files/t.txt$), str_file_list
      assert_match %r(^test/1.txt$), str_file_list
      assert_match %r(^test/_SiteChanged.txt$), str_file_list
      assert_match %r(^test/_SiteLog.txt$), str_file_list
      assert_match %r(^test/_SiteMember.txt$), str_file_list

#       assert_match %r(test/
# test/.backup/
# test/.backup/\d{10}_1
# test/.backup/\d{10}__SiteMember
# test/.backup/\d{10}_1
# test/.backup/\d{10}__SiteChanged
# test/1.files/
# test/1.files/t.txt
# test/1.txt
# test/_SiteChanged.txt
# test/_SiteLog.txt
# test/_SiteMember.txt
# ), str_file_list

      # Download again
      res = session '/test/test.tgz'
      ok_eq 'application/gzip', res['Content-Type']

      # Compare with cache file
      content = (@site.cache_path + "test.tgz").read
      ok_eq(content, res.body)
    end

  end
end
