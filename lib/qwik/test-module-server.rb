#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

require 'open-uri'

$LOAD_PATH << '../../lib' unless $LOAD_PATH.include?('../../lib')
require 'qwik/testunit'
require 'qwik/config'
#require 'qwik/server'
require 'qwik/htree-to-wabisabi'
require 'qwik/test-module-path'
#require 'qwik/qp'

module TestServerSetupModule
  def setup
    @dir = '../../data/test'.path
    @dir.setup
  end

  def teardown
    @dir.teardown
  end
end

module TestServerModule
  def setup_server(bind_address = '127.0.0.1')
    config = Qwik::Config.new
    config[:debug] = true
    config[:test] = true	# do not show webrick log
    config[:bind_address] = bind_address

    server = Qwik::Server.new(config)

    memory = server.memory

    wreq = Qwik::WEBrickRequest.new(server.config)
    wreq.request_uri = URI.parse('http://example.com/test/')
    wreq.peeraddr = [nil, nil, nil, '127.0.0.1']

    wres = Qwik::WEBrickResponse.new(server.config)
    wres.set_config

    return server, config, memory, wreq, wres
  end

  def session(config, memory, wreq, wres)
    req = Qwik::Request.new(config)
    req.parse_webrick(wreq)

    res = Qwik::Response.new(config)
    res.set_webrick(wres)

    action = Qwik::Action.new
    action.init(config, memory, req, res)
    action.run

    res.setback(wres)

    return wres
  end

  def teardown_server(server)
    server.shutdown
  end

  def write_page(pagekey, content)
    file = @dir+"#{pagekey}.txt"
    file.put(content+"\n")
  end

  def read_page(pagekey)
    file = @dir+"#{pagekey}.txt"
    str = file.get
    return str
  end

  def get_uri(uri)
    hash = {
      'Cookie' => "userpass=user@e.com,95988593; path=/;",
    }
    str = ''
    open(uri, hash) {|f|
      str = f.read
    }
    return str
  end

  def get_path(path)
    return get_uri("http://127.0.0.1:9190/test/#{path}")
  end

  def ok_xp(e, path, str)
    ok_eq(e, HTree(str).to_wabisabi.get_path(path))
  end

  def ok_in(e, path, str)
    ok_eq(e, HTree(str).to_wabisabi.get_path(path).inside.get_single)
  end
end
