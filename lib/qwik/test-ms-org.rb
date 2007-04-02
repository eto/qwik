#
# Copyright (C) 2002-2004 Satoru Takabayashi <satoru@namazu.org> 
# Copyright (C) 2003-2006 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/ml-session'
require 'qwik/test-module-ml'
require 'qwik/test-module-path'
require 'qwik/mock-logger'
require 'qwik/mock-socket'
require 'qwik/mock-sendmail'
$test = true

class TestMLSessionOriginal < Test::Unit::TestCase
  def setup
    config = {
      # Debug.
      :verbose_mode	=> true,	# *TEST*

      # ML server config.
      :sweep_interval		=> 10,		# *TEST*
      :allowable_error_interval	=> 3,		# *TEST*
      :auto_unsubscribe_count	=> 3,		# *TEST*
      :confirm_ml_creation	=> false,	# *TEST*

      # Config for each group.
      :max_members	=> 2,
      :max_mail_length		=> 10 * 1024,	# *TEST*
      :ml_life_time	=> 170,		# *TEST*
      :ml_alert_time	=> 160,		# *TEST*

      # Files and directories.
      :sites_dir	=> '.',			# *TEST*
      :ml_pid_file	=> 'quickml.pid',	# *TEST*
      :log_dir		=> '.',
    }

    config[:logger] = QuickML::MockLogger.new

    @config = Qwik::Config.new
    @config.update(config)
    QuickML::ServerMemory.init_mutex(@config)
    QuickML::ServerMemory.init_catalog(@config)

    @dir = './test/'.path
    @dir.teardown
    @dir.rmtree if @dir.directory?
    @dir.rmdir  if @dir.directory?
  end

  def test_dummy
  end

  def nu_test_basic
    socket = QuickML::MockSocket.new
    c = @config
    session = QuickML::Session.new(c, c.logger, c.catalog, socket)
    session.start
    ok_eq(['220 localhost ESMTP QuickML'], socket.result)

    socket = QuickML::MockSocket.new('HELO')
    c = @config
    session = QuickML::Session.new(c, c.logger, c.catalog, socket)
    session.start
    ok_eq(['220 localhost ESMTP QuickML'], socket.result)

    socket = QuickML::MockSocket.new('HELO localhost')
    c = @config
    session = QuickML::Session.new(c, c.logger, c.catalog, socket)
    session.start
    ok_eq(['220 localhost ESMTP QuickML',
	    '250 localhost'], socket.result)

    res = send_normal_mail 'alice@example.net'
    ok_eq(['220 localhost ESMTP QuickML',
	    '250 localhost',
	    '250 ok',
	    '250 ok',
	    '354 send the mail data, end with .',
	    '250 ok',
	    '221 Bye'], res)
  end

  def send_normal_mail(from)
    sendmail(from, 'test@example.com', 'test') { 'test' }
  end

  def ok_log(ar, range=nil)
    logs = @config.logger.get_log
    logs = logs[range] if range
    ok_eq(ar, logs)
  end

  def test_session
    #sleep 180				# automatic ML deletion
    # finish
  end

  def sendmail(from, to, subject, cc=nil)
    message = yield
    contents = []
    contents << "To: #{to}\n"
    contents << "From: #{from}\n"
    contents << "Subject: #{subject}\n"
    contents << "Cc: #{cc}\n" if cc
    contents << "\n" if /\n\z/ !~ message
    contents << message
    inputs = <<'EOT'
HELO localhost
MAIL FROM: #{from}
RCPT TO: #{to}
DATA
#{contents.join}
.
QUIT
EOT
    socket = QuickML::MockSocket.new(inputs)
    c = @config
    session = QuickML::Session.new(c, c.logger, c.catalog, socket)
    session.start
    return socket.result
  end
end
