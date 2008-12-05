# -*- coding: shift_jis -*-
# Copyright (C) 2008 National Institute of
#                    Advanced Industrial Science and Technology (AIST)
# All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

module Qwik
  class Site
    def lastmod_of_all
      ar = []
      self.path.find do |p|
	Find.prune if p.basename.to_s == '.cache' or p.basename.to_s == '.svn'
	ar << p.mtime
      end
      ar.max
    end
  end

  class Action
    D_SiteBackup = {
      :dt => 'Site backup',
      :dd => 'You can get a tgz(tar.gz) archive of the whole site content.',
      :dc => '* Example
{{sitebackup}}

You can get a zip archive with all text data of the Wiki site.
You can get a tgz(tar and gziped) archive of the whole site content.

You can move your site by getting the archive and placing them on your
qwikWeb data directory.

At the first click, it only shows the progress of archiving.
After the archiving is finished, you can download the archive file.

If you change anything on the site, it\'ll recreate the archive.
'
    }

    D_SiteBackup_ja = {
      :dt => 'サイト・バックアップ',
      :dd => 'サイト・バックアップを取得できます。',
      :dc => '* 使い方
{{sitebackup}}

このリンクから、サイトの内容すべてをtar.gz形式のアーカイブにしてダウンロードできます。

展開してqwikWebのdataディレクトリに置けば，サイトをそのまま移行することができます．

最初の一回目は、アーカイブ作成のためのプロセスが実行されます。
作成が終わってからリロードするか、ブラウザから元のページに戻って
もう一度リンクをクリックすると、アーカイブをダウンロードすることができます。

サイトの内容が更新された後、このリンクを再度クリックすると、アーカイブも再作成されます。
'
    }

    def plg_sitebackup
      return "no tar command" if ! SiteBackup.command_exist?
      return page_attribute('sitebackup', _('Site backup'), @site.sitename)
    end

    def ext_sitebackup
      return c_nerror("no tar command") if ! SiteBackup.command_exist?
      c_require_member
      c_require_base_is_sitename

      backup = SiteBackup.new(@site, @config)
      if backup.latest?
	return c_notice("Download archive", "#{@site.sitename}.tgz", 200, 2) {
	  [:p, "Backup process is complete. download ",
	   [:a, {:href=>"#{@site.sitename}.tgz"}, "archive"],
	   "."
	  ]
	}
      end

      if backup.generating?
	return c_notice("in progress", "#{@site.sitename}.sitebackup", 200, 5) {
	  [:p, "Backup process is running."]
	}
      end

      backup.generate
      return c_notice("starting", "#{@site.sitename}.sitebackup", 200, 5) {
	[:p, "Backup process is starting"]
      }
    end

    # only for download archive
    def ext_tgz
      c_require_member
      c_require_base_is_sitename

      backup = SiteBackup.new(@site, @config)
      if backup.latest?
	return c_simple_send(backup.archive_path, "application/gzip")
      else
	return c_notfound { "no latest backup" }
      end
    end
  end

  class SiteBackup
    TAR_CMD = '/bin/tar'	# path to tar command (GNU version is required)
    def self.command_exist?
      TAR_CMD.path.executable?
    end

    def initialize(site, config)
      @site = site
      @config = config
      @archive_path = site.cache_path + "#{@site.sitename}.tgz"
      @tmpfile_path = site.cache_path + "sitebackup.tmp"
    end
    attr_reader :archive_path
    attr_reader :tmpfile_path

    def _site_lastmod
      @site.lastmod_of_all
    end

    def _archive_mtime
      result = nil
      result = @archive_path.mtime if @archive_path.exist?
      return result
    end

    def _tmpfile_mtime
      result = nil
      result = @tmpfile_path.mtime if @tmpfile_path.exist?
      return result
    end

    def latest?(site_lastmod = _site_lastmod, archive_mtime = _archive_mtime,
		       tmpfile_mtime = _tmpfile_mtime) # explicit arguments for test
      return false if archive_mtime.nil?
      if tmpfile_mtime.nil?
	archive_mtime >= site_lastmod
      else
	archive_mtime >= site_lastmod && archive_mtime > tmpfile_mtime
      end
    end

    def generating?(site_lastmod = _site_lastmod, archive_mtime = _archive_mtime,
		  tmpfile_mtime = _tmpfile_mtime) # explicit arguments for test
      return false if tmpfile_mtime.nil?
      if archive_mtime.nil?
	tmpfile_mtime > site_lastmod
      else
	tmpfile_mtime >= archive_mtime && tmpfile_mtime > site_lastmod
      end
    end

    def invoke(cmd)
      system(cmd)
      child_process = $?
      child_process.exitstatus == 0 ? :success : :failure
    end

    def command
      "#{TAR_CMD} zcf #{@tmpfile_path} -C #{@config.sites_dir} " +
	"--exclude .cache --exclude .svn -h #{@site.sitename}"
    end

    def generate
      if defined?($test) && $test
	_generate
      else
	do_concurrent { _generate }
      end
    end

    def _generate
      cleanup
      result = invoke(command)
      if result == :success && @tmpfile_path.exist?
	@tmpfile_path.rename(@archive_path)
      else
	@tmpfile_path.unlink if @tmpfile_path.exist?
      end
    end

    def do_concurrent
      Thread.new {
	yield
      }
    end

    def cleanup
      @tmpfile_path.unlink if @tmpfile_path.exist?
      @archive_path.unlink if @archive_path.exist?
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
  class MockSite
    def cache_path; ".test/data/test/.cache/".path; end
    def sitename; "test"; end
  end

  class MockConfig
    def sites_dir; ".test/data/"; end
  end

  class TestSiteBackup < Test::Unit::TestCase
    include TestSession

    def setup
      site = MockSite.new
      config = MockConfig.new
      @backup = Qwik::SiteBackup.new(site, config)
    end

    def test_archive_path
      expected = ".test/data/test/.cache/test.tgz".path
      actual = @backup.archive_path
      is expected, actual
    end

    def test_tmpfile_path
      expected = ".test/data/test/.cache/sitebackup.tmp".path
      actual = @backup.tmpfile_path
      is expected, actual
    end

    def test_command_exist
      ok Qwik::SiteBackup.command_exist?
    end

    def test_backup_is_latest
      site_lastmod = Time.at(0)
      archive_mtime = Time.at(1)
      tmpfile_mtime = nil
      excepted = true
      actual = @backup.latest?(site_lastmod, archive_mtime, tmpfile_mtime)
      is excepted, actual
    end

    def test_backup_is_latest2
      site_lastmod = Time.at(0)
      archive_mtime = Time.at(0)
      tmpfile_mtime = nil
      excepted = true
      actual = @backup.latest?(site_lastmod, archive_mtime, tmpfile_mtime)
      is excepted, actual, "archive and site-lastmod is same"
    end

    def test_backup_is_not_latest2
      site_lastmod = Time.at(0)
      archive_mtime = Time.at(1)
      tmpfile_mtime = Time.at(1)
      excepted = false
      actual = @backup.latest?(site_lastmod, archive_mtime, tmpfile_mtime)
      is excepted, actual, "tmpfile is latest"
    end

    def test_backup_is_not_latest3
      site_lastmod = Time.at(0)
      archive_mtime = nil
      tmpfile_mtime = nil
      excepted = false
      actual = @backup.latest?(site_lastmod, archive_mtime, tmpfile_mtime)
      is excepted, actual, "backup is not exist"
    end

    def test_backup_is_creating
      site_lastmod = Time.at(0)
      archive_mtime = Time.at(0)
      tmpfile_mtime = Time.at(1)
      excepted = true
      actual = @backup.generating?(site_lastmod, archive_mtime, tmpfile_mtime)
      is excepted, actual
    end

    def test_backup_is_creating2
      site_lastmod = Time.at(0)
      archive_mtime = nil
      tmpfile_mtime = Time.at(1)
      excepted = true
      actual = @backup.generating?(site_lastmod, archive_mtime, tmpfile_mtime)
      is excepted, actual, "at first: backup is not exist"
    end

    def test_backup_is_creating3
      site_lastmod = Time.at(0)
      archive_mtime = Time.at(1)
      tmpfile_mtime = Time.at(1)
      excepted = true
      actual = @backup.generating?(site_lastmod, archive_mtime, tmpfile_mtime)
      is excepted, actual, "tmp and backup is same"
    end

    def test_backup_is_not_creating
      site_lastmod = Time.at(0)
      archive_mtime = Time.at(0)
      tmpfile_mtime = nil
      excepted = false
      actual = @backup.generating?(site_lastmod, archive_mtime, tmpfile_mtime)
      is excepted, actual, "tmp is absent"
    end

    def test_backup_is_not_creating2
      site_lastmod = Time.at(1)
      archive_mtime = Time.at(1)
      tmpfile_mtime = Time.at(1)
      excepted = false
      actual = @backup.generating?(site_lastmod, archive_mtime, tmpfile_mtime)
      is excepted, actual, "site is modified"
    end

    def test_invoke
      expected = :success
      input = "ruby -e 'true'"
      actual = @backup.invoke(input)
      is expected, actual
    end

    def test_invoke_fail
      expected = :failure
      input = "ruby -e 'exit 1'"
      actual = @backup.invoke(input)
      is expected, actual, "exit status sould be 1"
    end

    def test_invoke_unavailable
      expected = :failure
      input = "never-seen-command"
      actual = @backup.invoke(input)
      is expected, actual, "command should not found"
    end

    def test_command
      expected = "#{Qwik::SiteBackup::TAR_CMD} zcf .test/data/test/.cache/sitebackup.tmp -C .test/data/ " +
	"--exclude .cache --exclude .svn -h test"
      actual = @backup.command
      is expected, actual
    end

    def test_do_concurrent
      t1 = t2 = nil
      thread = @backup.do_concurrent {
	Thread.pass
	sleep 0.1
	t1 = Time.now
      }
      t2 = Time.now
      thread.join
      assert_not_equal t1.to_f, t2.to_f
    end

  end

  class TestActSiteBackup < Test::Unit::TestCase
    include TestSession
    
    def test_plg_tgz
      ok_wi [:p, [:a, {:href=>'test.sitebackup'}, 'test.sitebackup']], '[[test.sitebackup]]'
      ok_wi [:span, {:class=>'attribute'},
	     [:a, {:href=>'test.sitebackup'}, 'Site backup']], '{{sitebackup}}'
    end

    def test_ext_tgz
      t_add_user

      # Add a page
      page = @site.create_new
      page.store '* Test'

      # Wait to make time-lag between archive and site data
      sleep 1

      # Create backup
      res = session '/test/test.sitebackup'
      ok_title 'starting'

      res = session '/test/test.sitebackup'
      ok_title 'Download archive'

      res = session '/test/test.tgz'
      ok_eq 'application/gzip', res['Content-Type']

      # Compare with cache file
      content = (@site.cache_path + "test.tgz").read
      ok_eq(content, res.body)

      # Wait to make time-lag between archive and site data
      sleep 1

      # Attach a file
      res = session('POST /test/1.files') {|req|
	req.query.update('content'=>t_make_content('t.txt', 't'))
      }
      ok_title('File attachment completed')

      # Remake backup
      res = session '/test/test.sitebackup'
      ok_title 'starting'

      # Download again
      res = session '/test/test.tgz'
      ok_eq 'application/gzip', res['Content-Type']

      # Compare with cache file
      content = (@site.cache_path + "test.tgz").read
      ok_eq(content, res.body)
    end

  end
end
