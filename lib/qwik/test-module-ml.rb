# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

require 'pp'

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/testunit'
require 'qwik/test-module-path'
require 'qwik/test-module-session'
require 'qwik/test-module-public'
require 'qwik/mock-logger'
require 'qwik/mock-socket'
require 'qwik/mock-sendmail'
require 'qwik/config'
require 'qwik/ml-memory'

$quickml_debug = true

module QuickML
  class Group
    def setup_test_config
      # setup config
      raise 'config not defined' if !defined?($test_config)
      @qwikconfig = $test_config

      # setup memory
      raise 'memory not defined' if !defined?($test_memory)
      @qwikmemory = $test_memory
    end
  end
end

module TestModuleML
  include TestSession
  include TestModulePublic

  # ============================== setup
  def setup
    web_setup
    ml_setup
  end

  def ml_setup
    # setup quickml config
    if ! defined?($quickml_config) || $quickml_config.nil?
      config = Qwik::Config.new
      config[:logger] = QuickML::MockLogger.new
      config.update(Qwik::Config::DebugConfig)
      config.update(Qwik::Config::TestConfig)
      QuickML::ServerMemory.init_mutex(config)
      QuickML::ServerMemory.init_catalog(config)

      $quickml_config = config
    end
    @ml_config = $quickml_config
    dummy = @ml_config.logger.get_log	# clear log

    @ml_dir = @ml_config.sites_dir.path+'test'
    @ml_dir.teardown

    @ml_catalog = @ml_config.catalog
    @ml_message_charset = 'iso-2022-jp'

    t_make_public(QuickML::Group, :site_post)
  end

  # ============================== teardown
  def teardown
    ml_teardown
    web_teardown
  end

  def ml_teardown
    @ml_dir.teardown if @ml_dir
  end

  # ============================== session
  def sendmail(from, to, subject, cc=nil)
    message = yield

    cc_line = ''
    cc_line = "Cc: #{cc}\n" if cc
    separator_line = ''
    separator_line = "\n" unless /\n\z/ =~ message

    contents = ''
    contents << "To: #{to}\n"
    contents << "From: #{from}\n"
    contents << "Subject: #{subject}\n"
    contents << cc_line
    contents << separator_line
    contents << message

    inputs = "HELO localhost
MAIL FROM: #{from}
RCPT TO: #{to}
DATA
#{contents}
.
QUIT
"
    inputs = inputs.set_sourcecode_charset.to_mail_charset
    socket = QuickML::MockSocket.new(inputs)
    c = @ml_config
    session = QuickML::Session.new(c, c.logger, c.catalog, socket)
    session.start
    return socket.result
  end

  def send_normal_mail(from)
    sendmail(from, 'test@q.example.com', 'test') { 'test' }
  end

  def unsubscribe(from)
    sendmail(from, 'test@q.example.com', 'unsubscribe') { '' }
  end

  def sm(sub, &b)
    sendmail('bob@example.net', 'test@q.example.com', sub, &b)
  end

  # ============================== assert
  def ok_log(e, range=nil)
    logs = @ml_config.logger.get_log
    logs = logs[range] if range
    return ok_eq(e, logs) if e.is_a?(Array)
    return ok_eq(e, logs.join("\n"))
  end
  alias ok ok_log

  # ==================== backward compatibility
#  def gen_mail(&b)
#    return QuickML::Mail.generate(&b)
#  end

  def post_mail(group, &b)
    mail = QuickML::Mail.generate(&b)
    group.site_post(mail, true)
    return mail
  end
end
