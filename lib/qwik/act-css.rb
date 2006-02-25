require 'uri'
require 'net/http'

$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    def pre_act_css
      str = ''
      if 1 < @req.path_args.length
	url = @req.path_args.join('/')
	url = url.sub(/\Ahttp:\//, 'http://') if /\Ahttp:\/[^\/]/ =~ url
	str = c_fetch_by_url(url)
      else
	filename = @req.path_args[0]
	ext = Filename.extname(filename)
	raise if ext != 'css'
	file = @site.attach.path(filename)
	raise unless file.exist?
	str = file.open {|f| f.read}
      end
      return c_notfound(_('Access Failed')) if str.nil?
      str = '/* invalid css */' unless CSS.valid?(str)
      @res.body = str
    end

    def c_fetch_by_url(url)
      uri = URI.parse(url)
      raise if uri.scheme != 'http'
      res = nil
      begin
	Net::HTTP.start(uri.host, uri.port) {|http|
	  res = http.get(uri.path)
	}
      rescue
	return nil
      end
      res.body
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActCSS < Test::Unit::TestCase
    include TestSession

    def test_all
      # test_extcss
      d = @dir+'.attach'
      d.erase_all_for_test if d.exist?

      attach = @site.attach
      attach.put('test.css', '/* test */')
      res = session('/test/.css/test.css')
      ok_eq('/* test */', res.body)
      attach.delete('test.css')

      attach.put('test.css', '@i')
      res = session('/test/.css/test.css')
      ok_eq('/* invalid css */', res.body)
      attach.delete('test.css')
    end
  end
end
