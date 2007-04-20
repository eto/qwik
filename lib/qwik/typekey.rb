#
# Copyright (C) 2005 jouno <jouno2002@yahoo.co.jp>
# License under GPL-2
#
# original is Adam Bregenzer(<adam@bregenzer.net>)'s python version
# http://adam.bregenzer.net/python/typekey/TypeKey.py
#
# modified by Kouichirou Eto
#
# note:
# nick name field must be sent as utf-8 url_encoded string.

# sample code:

=begin
token = 'your_site_token'
tk = TypeKey.new(token, '1.1')

if cgi.params['tk'][0] == '1'
  ts    = cgi.params['ts'][0]
  email = cgi.params['email'][0]
  name  = cgi.params['name'][0]
  nick  = cgi.params['nick'][0]
  sig   = cgi.params['sig'][0]
  if tk.verify(email, name, nick, ts, sig)
    puts 'verify!'
  else
    puts 'not!'
  end
end

return_url = 'http://localhost/cgi-bin/tk_test.cgi'

url_sign_in = tk.get_login_url(return_url + '?tk=1')
url_sign_out = tk.get_logout_url(return_url)

puts "<a href=\"#{url_sign_in}\">sign in</a><br />"
puts "<a href=\"#{url_sign_out}\">sign out</a><br />"
=end

require 'uri'
require 'open-uri'
require 'base64'
require 'openssl'

class TypeKeyError < StandardError; end
class TimeOutError < TypeKeyError; end
class VerifyFailed < TypeKeyError; end

# This class handles TypeKey logins.
class TypeKey
  def initialize(token, version = '1.1')
    @token = token
    @version = version

    # Base url for generating login and logout urls.
    @base_url = 'https://www.typekey.com/t/typekey/'

    # Url used to download the public key.
    @key_url = 'http://www.typekey.com/extras/regkeys.txt'

    # Location for caching the public key.
    @key_cache_path = '/tmp/tk_key_cache'

    # Length of time to wait before refreshing the public key cache, in seconds.
    # Defaults to two days.
    @key_cache_timeout = 60 * 60 * 24 * 2

    # Length of time logins remain valid, in seconds.
    # Defaults to five minutes.
    @login_timeout = 60 * 5
  end
  attr_accessor :base_url, :login_timeout
  attr_accessor :key_url, :key_cache_path, :key_cache_timeout

  # Verify a typekey login
  def verify(email, name, nick, ts, sig, key = nil)
    sig.gsub!(/ /, '+') # sig isn't urlencoded.

    key = get_key if key.nil?

    message_ar = [email, name, nick, ts.to_s]
    message_ar << @token if @version == '1.1'
    message = message_ar.join('::')

    raise VerifyFailed if ! dsa_verify(message, sig, key)
    raise TimeOutError if (Time.now.to_i - ts.to_i) > @login_timeout
    return true
  end

  # Return a URL to login to TypeKey
  def get_login_url(return_url, email = false)
    url  = @base_url
    url += "login?t=#{@token}"
    url += (email ? '&need_email=1' : '')
    url += "&_return=#{URI.escape(return_url)}"
    url += "&v=#{@version}"
    return url
  end

  # Return a URL to logout of TypeKey
  def get_logout_url(return_url)
    return @base_url + 'logout?_return=' + URI.escape(return_url)
  end

  # Return the TypeKey public keys, cache results unless a url is passed
  def get_key(url = nil)
    if url.nil?
      begin
        mod_time = File.mtime(@key_cache_path).to_i
      rescue SystemCallError
        mod_time = 0
      end

      if @key_cache_timeout < (Time.now.to_i - mod_time) ||
          ! File.exist?(@key_cache_path)
        open(@key_url) {|fh| # using open-uri
          @key_string = fh.read
        }
        File.open(@key_cache_path, 'w') {|fh|
          fh.puts(@key_string)
        }
      else
        File.open(@key_cache_path, 'r') {|fh|
          @key_string = fh.read
        }
      end
    else
      open(url) {|fh|
        @key_string = fh.read
      }
    end

    tk_key = Hash.new

    for pair in @key_string.strip.split(' ')
      key, value = pair.split('=')
      tk_key[key] = value.to_i
    end

    return tk_key
  end

  # Verify a DSA signature
  def dsa_verify(message, sig, key)
    r_sig, s_sig = sig.split(':')
    r_sig = Base64.decode64(r_sig).unpack('H*')[0].hex
    s_sig = Base64.decode64(s_sig).unpack('H*')[0].hex
    sign = OpenSSL::ASN1::Sequence.new([OpenSSL::ASN1::Integer.new(r_sig),
					 OpenSSL::ASN1::Integer.new(s_sig)]
				       ).to_der
    dsa = OpenSSL::PKey::DSA.new
    dsa.p = key['p']
    dsa.q = key['q']
    dsa.g = key['g']
    dsa.pub_key = key['pub_key']
    dss1 = OpenSSL::Digest::DSS1.new
    return dsa.verify(dss1, sign, message)
  end
end
