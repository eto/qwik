# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    def c_simple_send(path, type=nil)
      return SimpleSender.send(@config, @req, @res, path.to_s, type)
    end

    def c_download(path)
      return SimpleSender.download(@req, @res, path.to_s, @config.test)
    end
  end

  class SimpleSender
    # copied from webrick
    def self.send(config, req, res, local_path, mtype=nil)
      local_path = local_path.path
      if ! local_path.exist?
	raise WEBrick::HTTPStatus::NotFound
      end

      st = local_path.stat
      res['etag'] = sprintf('%x-%x-%x', st.ino, st.size, st.mtime.to_i)

      if not_modified?(req, res, st.mtime)
	res.body = ''
	raise WEBrick::HTTPStatus::NotModified
      end

      if mtype.nil?
	mtype = res.get_mimetypes(local_path.ext)	# Get content type.
      end
      res['Content-Type']   = mtype
      res['Content-Length'] = st.size
      res['Last-Modified']  = st.mtime.httpdate

      if config.ssl || config.test
	# BUG: ssl can not send data as stream.
	res.body = local_path.read
      else
	res.body = open(local_path.to_s, 'rb')
      end
    end

    def self.download(req, res, local_path, test=false)
      local_path = local_path.path
      if ! local_path.exist?
	raise WEBrick::HTTPStatus::NotFound
      end

      st = local_path.stat
      res['etag'] = sprintf('%x-%x-%x', st.ino, st.size, st.mtime.to_i)

      if not_modified?(req, res, st.mtime)
	res.body = ''
	raise WEBrick::HTTPStatus::NotModified
      end

      res.set_content_type(local_path.ext)
      res['Content-Length'] = st.size
      res['Last-Modified']  = st.mtime.httpdate

      basename = local_path.basename
      decoded = Filename.decode(basename.to_s)	# UTF-8
      filename = decoded.to_page_charset
      res['Content-Disposition'] = "attachment; filename=\"#{filename}\""

      if test
	res.body = local_path.read
      else
	res.body = open(local_path.to_s, 'rb')
      end
    end

    def self.fsend(config, req, res, local_path, mtype, dfilename)
      local_path = local_path.path
      if ! local_path.exist?
	raise WEBrick::HTTPStatus::NotFound
      end
      res['Content-Type'] = mtype
      res['Content-Disposition'] = ' attachment; filename='+dfilename
      res.body = local_path.read
    end

    private

    def self.not_modified?(req, res, mtime)
      if ir = req['if-range']
	begin
	  return true if mtime <= ::Time.httpdate(ir)
	rescue
	  if WEBrick::HTTPUtils::split_header_valie(ir).member?(res['etag'])
	    return true
	  end
	end
      end

      if (ims = req['if-modified-since']) && mtime <= ::Time.parse(ims)
	return true
      end

      if (inm = req['if-none-match']) &&
	  WEBrick::HTTPUtils::split_header_value(inm).member?(res['etag'])
	return true 
      end

      return false
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestCommon < Test::Unit::TestCase
    include TestSession

    def test_simple_send
      t_add_user

      page = @site.create_new
      page.store('t')

      # At the first, attach a text file for test.
      res = session('POST /test/1.files') {|req|
	req.query.update('content'=>t_make_content('t.txt', 't'))
      }
      ok_title('File attachment completed')

      # Get the content using simple send.
      res = session('/test/1.files/t.txt')
      ok_eq('text/plain', res['Content-Type'])
      ok_eq('t', res.body)

      t_without_testmode {
	res = session('/test/1.files/t.txt')
	ok_eq('text/plain', res['Content-Type'])
	assert_instance_of(File, res.body)
	str = res.body.read
	res.body.close		# important
	ok_eq('t', str)
      }
    end

    def test_download
      t_add_user

      page = @site.create_new
      page.store('t')

      # At the first, attach a test file.
      res = session('POST /test/1.files') {|req|
	req.query.update('content'=>t_make_content('t.txt', 't'))
      }
      ok_title('File attachment completed')

      # Get the content by download.
      res = session('/test/1.download/t.txt')
      ok_eq('text/plain', res['Content-Type'])
      ok_eq("attachment; filename=\"t.txt\"", res['Content-Disposition'])
      ok_eq('t', res.body)
    end
  end
end
