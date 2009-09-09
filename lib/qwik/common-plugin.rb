# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/util-csv-tokenizer'

module Qwik
  class Action
    def c_call_plugin(method, param, &b)
      args = nil
      args = Action.plugin_parse_args(param) if param && !param.empty?
      args ||= []
      args.each {|s|
	s.set_page_charset
      }
      m = "plg_#{method}"
      begin
	return self.send(m, *args, &b) if self.respond_to?(m)
	return [:span, {:class=>'plg_error'}, 'nosuch plugin | ',
	  [:strong, method]]
      rescue
        #raise if @config.test || @config.debug
	raise if @config.test

	h = @req.fromhost
	if Action.from_local?(h)
	  return PrettyBacktrace.to_html($!)	# common-backtrace
	else
	  return [:span, {:class=>'plg_error'}, 'plugin error | ',
	    [:strong, method]]
	end
      end
    end

    def self.plugin_parse_args(param)
      args = CSVTokenizer.csv_split(param)
      args.collect! {|a|
	case a
	when /\A'(.+)'$/, /^"(.+)"\z/
	  $1
	else
	  a
	end
      }
      args
    end

    def self.from_local?(h)
      if h == 'localhost' ||
	  h == '127.0.0.1' ||
	  /\A\w+\z/ =~ h ||
	  /\A192\.168\..+\z/ =~ h ||
	  /\A150\.29\.151/ =~ h ||
	  /\A61\.193\.236/ =~ h
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
  class TestActPlugin < Test::Unit::TestCase
    include TestSession

    def ok(e, s)
      eq e, Qwik::Action.plugin_parse_args(s)
    end

    def test_parse_args
      ok ['a'], "'a'"
      ok ['a'], "\"a\""
      ok ['<'], '<'
      ok ['<'], "'<'"
      ok ['a b'], 'a b'
    end

    def ok_plugin(e, ar)
      eq e, @action.c_call_plugin(*ar)
    end

    def test_all
      res = session

      # test_from_local?
      c = Qwik::Action
      eq true, c.from_local?('localhost')
      eq true, c.from_local?('win')
      eq true, c.from_local?('127.0.0.1')
      eq true, c.from_local?('192.168.0.1')
      eq true, c.from_local?('192.168.2.1')
      eq false, c.from_local?('www.example.com')

      # test_call_plugin
      ok_plugin 'test', ['qwik_test', '']
      ok_plugin [:span, {:class=>'plg_error'}, 'nosuch plugin | ',
	[:strong, 'nosuch']], ['nosuch', '']

      t_without_testmode {
	res = @action.c_call_plugin('_qwik_test_for_raise_exception', '')
	eq :h3, res[0][0]
      }
    end
  end
end
