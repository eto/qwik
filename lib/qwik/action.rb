# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

require 'qwik/parser'
require 'qwik/server-memory'
require 'qwik/template'
require 'qwik/tokenizer'
require 'qwik/wabisabi'

# Load utils.
require 'qwik/util-basic'
require 'qwik/util-charset'
require 'qwik/util-filename'
require 'qwik/util-time'

# Load common actions.
require 'qwik/common-basic'
require 'qwik/common-backtrace'
require 'qwik/common-condition'
require 'qwik/common-gettext'
require 'qwik/common-javascript'
require 'qwik/common-notice'
require 'qwik/common-plain'
require 'qwik/common-plugin'
require 'qwik/common-res'
require 'qwik/common-send'
require 'qwik/common-session'
require 'qwik/common-surface'
require 'qwik/common-url'

# Load some basic actions.
require 'qwik/act-basic'
require 'qwik/act-edit'
require 'qwik/act-file'
require 'qwik/act-html'
require 'qwik/act-interwiki'
require 'qwik/act-login'
require 'qwik/act-new'		# newpage_form
require 'qwik/act-sitelog'
require 'qwik/act-theme'
require 'qwik/act-toc'

# Use for site_updated
require 'qwik/act-metadata'
require 'qwik/act-archive'

module Qwik
  class Action
    def initialize
      @config = @memory = @req = @res = nil
    end

    def init(config, memory, req, res)
      @config, @memory, @req, @res = config, memory, req, res
    end

    def site_updated
      pagelist_update
      metadata_clear_cache
      archive_clear_cache
    end

    def run
      init_gettext

      # for maps plugin support.
      sitename = @req.query['site']
      @req.sitename = sitename if sitename
      pagename = @req.query['page']
      @req.base = pagename if pagename

      # Get site.
      @site = @memory.farm.get_site(@req.sitename)

      if @site.nil?
	@site = @memory.farm.get_top_site
	unless @req.plugin == 'theme'
	  return action_no_such_site(@req.sitename)
	end
      end

      begin
	# Get user.
	login_get_user

	# Do PRE Action.
	method = "pre_act_#{@req.plugin}"
	if self.respond_to?(method)
	  return self.send(method)
	end

	# Do PRE Ext.
	method = "pre_ext_#{@req.ext}"
	if self.respond_to?(method)
	  return self.send(method)
	end

	# Check auth for the site.
	require_mail   = true
	require_member = true
	if @site.is_open?
	  require_mail   = false
	  require_member = false
	end

	if require_mail && @req.user.nil?
	  @res.clear_cookies
	  return action_go_login
	end

	if require_member && !@site.member.exist?(@req.user)
	  user = @req.user
	  ml = @site.ml_address
	  return action_go_login if user.nil?
	  return action_member_only_form(user, ml)
	end

	# Do action.
	if @req.plugin
	  action = @req.plugin
	  method = "act_#{action}"
	  if self.respond_to?(method)
	    return self.send(method)
	  else
	    return c_nerror("no such action : #{action}")
	  end
	end

	# Do ext action.
	ext = @req.ext
	method = "ext_#{ext}"
	if self.respond_to?(method)
	  return self.send(method)
	else
          # Special attached file mode.
          @req.path_args = ["#{@req.base}.#{@req.ext}"]
          @req.base = 'FrontPage'
          return act_files
	end

      rescue InvalidUserError
	@res.clear_cookies	# important
	return login_invalid_user

      rescue RequireLogin
	return action_require_login

      rescue RequireMember
	return action_go_login if @req.user.nil?
	return action_member_only_form(@req.user, @site.ml_address)

      rescue RequirePost
	return action_require_post

      rescue PageNotFound
	return action_page_not_found

      rescue RequireNoPathArgs
	return action_require_no_path_args

      rescue BaseIsNotSitename
	return action_require_base_is_sitename

      rescue WEBrick::HTTPStatus::Status
	raise $!

      rescue StandardError
	e = $!
	# Why?
	pp e.message
	pp e.backtrace
	raise e
	#return c_nerror(e.message){ backtrace_html($!) }
      end
    end

    def action_no_such_site(sitename)
      c_notfound(_('No such site.')) {
	[:div,
	  [:p, [:b, sitename], ' : ', _('No corresponding site.')],
	  [:p , _('Please send mail to make a site')],
	  [:p, [:a, {:href=>'http://qwik.jp/'}, 'qwik.jp'],
	    _('Access here and see how to.')]]
      }
    end

    def action_go_login
      url = c_relative_to_root('.login')
      c_notice(_('Login'), url, 200, 1) {
	[:div,
	  [:p, _('Please log in.')],
	  [:p, login_create_login_link]]
      }
    end

    def action_require_login
      c_nerror(_('Please log in.')) {
	[:div,
	  [:p, _('You need to log in to use this function.')],
	  [:p, login_create_login_link, ' : ' + _('Access here.')],
	  [:hr],
	  [:p, [:a, {:href=>'FrontPage.html'}, _('Go back')]]]
      }
    end

    def action_member_only_form(user, ml)
      c_nerror(_('Members Only')) {
	[:div,
	  [:p, _('You are now logged in with this user id.'), [:br],
	    [:strong, user]],
	  [:p, _('This user with this ID is not a member of this group.'), [:br],
	    [:strong, ml]],
	  [:p, _('If you would like to log in on another account,'), [:br],
	    _('please log out first.')],
	  logout_form]
      }
    end

    def action_require_post
      c_nerror(_('Please input POST')) {
	[[:p, _('This function requires POST input.')],
	  [:p, [:a, {:href=>'FrontPage.html'}, _('Go back')]]]
      }
    end

    def action_require_no_path_args
      c_notfound(_('Incorrect path arguments.')) {
	[:h2, _('Path arguments are not acceptable.')]
      }
    end

    # action_page_not_found is moved to act-new.rb

    def action_require_base_is_sitename
      c_notfound(_('Not found.')) {
	[:h2, _('Not found.')]
      }
    end

    # Null ext.
    def pre_ext_
      sitename = @req.base
      title = "redirect to site : #{sitename}"
      url = c_relative_to_root("#{sitename}/")
      c_notice(title, url) {
	[:h2, title]
      }
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestAction < Test::Unit::TestCase
    include TestSession

    def test_nonexistent_site
      res = session '/nosuchsite/'
      ok_title 'No such site.'
      assert_text 'No such site.', 'h1'
      assert_text 'nosuchsite', 'b'
      eq 404, @res.status
    end

    def test_private_site
      res = session '/test/'
      ok_title 'Members Only'
      ok_xp [:p, 'You are now logged in with this user id.', [:br],
	[:strong, 'user@e.com']],'//p'
    end

    def test_nonexistent_action
      t_add_user
      res = session '/test/.nosuch'
      ok_title 'no such action : nosuch'
    end

    def test_nonexistent_ext
      t_add_user
      res = session '/test/1.nosuch'
      ok_title "No such file"
    end

    def test_redirect
      res = session '/test'
      ok_title 'redirect to site : test'
      ok_xp [:meta, {:content=>'0; url=/test/',
	  'http-equiv'=>'Refresh'}], '//meta[2]'
    end

    def test_redirect
      t_with_path {
	res = session '/test'
	ok_title 'redirect to site : test'
	ok_xp [:meta, {:content=>'0; url=/qwik/test/',
	    'http-equiv'=>'Refresh'}], '//meta[2]'
      }
    end

    def test_go_login
      res = session('/test/') {|req|
	req.cookies.clear
      }
      ok_title 'Login'
      ok_xp [:meta, {:content=>'1; url=/test/.login',
	  'http-equiv'=>'Refresh'}], '//meta[2]'

      t_with_path {
	res = session('/test/') {|req|
	  req.cookies.clear
	}
	ok_title 'Login'
	ok_xp [:meta, {:content=>'1; url=/qwik/test/.login',
	    'http-equiv'=>'Refresh'}], '//meta[2]'
      }
    end
  end
end
