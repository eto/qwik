# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

require 'webrick/log'

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/testunit'
require 'qwik/test-module-path'
require 'qwik/test-module-public'
require 'qwik/request'
require 'qwik/response'
require 'qwik/loadlib'
require 'qwik/qp'
require 'logger'

module TestSession
  include TestModulePublic

  DEFAULT_USER = 'user@e.com'

  TEST_PNG_DATA = "\211PNG\r\n\032\n\000\000\000\rIHDR\000\000\000\001\000\000\000\001\010\002\000\000\000\220wS\336\000\000\000\fIDATx\332c\370\377\377?\000\005\376\002\3763\022\225\024\000\000\000\000IEND\256B`\202"

  # ============================== setup
  def setup
    web_setup
  end

  def web_setup
    # setup config
    if ! defined?($test_config)
      config = Qwik::Config.new
      $test_org_sites_dir = config[:sites_dir].dup
      config.update(Qwik::Config::DebugConfig)
      config.update(Qwik::Config::TestConfig)
      $test_config = config
    end
    @config = $test_config
    @org_sites_dir = $test_org_sites_dir

    @config.sites_dir.path.check_directory
    @config.grave_dir.path.check_directory
    @config.cache_dir.path.check_directory
    @config.etc_dir.path.check_directory
    @config.log_dir.path.check_directory

    # setup memory
    if ! defined?($test_memory)
      memory = Qwik::ServerMemory.new(@config)
      logfile = '.test/testlog.txt'
      loglevel = WEBrick::Log::INFO
      logger = WEBrick::Log::new(logfile, loglevel)
      memory[:logger] = logger

      burylogfile = '.test/testburylog.txt'
      log = ::Logger.new(burylogfile)
      log.level = ::Logger::INFO
      memory[:bury_log] = log

      $test_memory = memory
    end
    @memory = $test_memory

    # setup dir
    @wwwdir = @config.sites_dir.path + 'www'
    @wwwdir.setup
    @dir = @config.sites_dir.path + 'test'
    @dir.setup

    # setup site
    @site = @memory.farm.get_site('test')
  end

  # ============================== teardown
  def teardown
    web_teardown
  end

  def web_teardown
    @site.erase_all if defined?(@site) && @site
    @wwwdir.teardown if @wwwdir
    #assert_equal false, (@dir+"test").exist?
    @dir.teardown if @dir
  end

  # ============================== session
  def session(path = '/test/')
    # setup_req
    req = Qwik::Request.new(@config)

    # setup user
    t_setup_user(@memory, req, DEFAULT_USER)

    # parse_host
    req.instance_eval {
      @fromhost = 'example.com'
    }

    if /\APOST / =~ path
      req.instance_eval {
	@request_method = 'POST'
      }
      path.sub!(/\APOST /, "")
    end

    if path.include?("?")
      path, query_str = path.split("?", 2)
      query = WEBrick::HTTPUtils.parse_query(query_str)
      req.query.clear
      req.query.update(query)
    end

    req.parse_path(path)
    req.accept_language = ['en']
    req.instance_eval {
      @fromhost = 'localhost'
    }

    # setup_res
    res = Qwik::Response.new(@config)
    res.make_mimetypes(WEBrick::HTTPUtils::DefaultMimeTypes)

    # setup_action
    @action = Qwik::Action.new
    @action.init(@config, @memory, req, res)
    site = @site
    @action.instance_eval {
      @site = site;
    }

    # Setup request by block.
    yield(req) if block_given?

    action = Qwik::Action.new
    action.init(@config, @memory, req, res)
    action.run

    dummy_str = res.setback_body(res.body)

    @res = res
    # Since @res is not thread safe, return res instead of @res.
    return res
  end

  def t_setup_user(memory, req, user)
    req.cookies['user'] = user
    req.cookies['pass'] = memory.passgen.generate(user)
  end
  private :t_setup_user

  # ==================== test common
  def t_site_open
    page = @site['_SiteConfig']
    page.put_with_time(':open:true', 0)
  end

  def t_add_user(user = DEFAULT_USER)
    @site.member.add(user) unless @site.member.exist?(user)
  end

  def t_without_testmode
    org_test  = @config.test
    org_debug = @config.debug
    @config[:test]  = false
    @config[:debug] = false
    yield
    @config[:test]  = org_test
    @config[:debug] = org_debug
  end

  def t_with_site(sitename)
    dir = ("#{sitename}/").path
    dir.setup
    yield
    dir.teardown
  end

  def t_make_content(filename, data)
    content = WEBrick::HTTPUtils::FormData.new(data)
    content.filename = filename
    return content
  end

  def t_with_path
    org_public_url = @config[:public_url]
    @config[:public_url] = "http://www.example.org/qwik/"
    yield
    @config[:public_url] = org_public_url
  end

  def t_with_siteurl(url='http://example.org/q/')
    siteconfig = @site['_SiteConfig']
    siteconfig.store ":siteurl:#{url}\n"
    yield
    siteconfig.store ""
  end

  # ==================== assert xpath module
  def assert_path(e, w, user=DEFAULT_USER, path="//div[@class='section']", &b)
    t_add_user if user

    page = @site['1']
    page = @site.create('1') if page.nil?
    page.store(w)
    res = session('/test/1.html') {|req|
      yield(req) if block_given?
      t_setup_user(@memory, req, user)
    }
    div = res.body.get_path(path)

    if e.is_a? Array
      return assert_equal(e, div.inside.remove_comment.get_single)
    end
    return assert_equal_or_match(e, div.inside.rb_format_xml(-1, -1).chomp)
  end

  def ok_wi(e, w, &b)
    return assert_path(e, w, DEFAULT_USER, "//div[@class='section']", &b)
  end

  # ==================== show
  # Get element by XPath and show it in pretty print mode.
  def pw(xpath=nil, res=@res)
    pp res.body.get_path(xpath)
  end

  # ==================== assert module
  def assert_equal_or_match(e, s)
    return assert_match(e, s) if e.is_a? Regexp
    return assert_equal(e, s)
  end

  def ok_xp(e, path, res=@res)
    elem = res.body.get_path(path)
    return assert_equal(e, nil) if elem.nil?
    return assert_equal(e, elem.remove_comment)
  end

  def ok_in(e, path, res=@res)
    elem = res.body.get_path(path)
    return assert_equal(e, nil) if elem.nil?
    return assert_equal(e, elem.inside.get_single)
  end
  
  def ok_title(e, res=@res)
    elem = res.body.get_path('//title')
    return assert_equal(e, nil) if elem.nil?
    return assert_equal(e, elem.inside.get_single[0])
  end
  
  def assert_text(e, tag, res=@res)
    elem = res.body.get_tag(tag)
    return assert_equal(e, nil) if elem.nil?
    return assert_equal_or_match(e, elem.text)
  end

  def ok_attr(e, s, res=@res)
    elem = (/\A\/\// =~ s) ? res.body.get_path(s) : res.body.get_tag(s)
    return assert_equal(e, nil) if elem.nil?
    return assert_equal(e, elem.attr)
  end
  alias assert_attr ok_attr
  alias assert_rattr ok_attr
end
