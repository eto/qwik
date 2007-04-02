# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/wabisabi-template'

module Qwik
  class Action
    def resolve_all_plugin(wabisabi)
      return wabisabi.each_tag(:plugin) {|w|
	resolve_plugin(w)
      }
    end

    # Make index before call this method.  Use parent.
    def nunuresolve_all_plugin(wabisabi)
      #wabisabi.make_index
      wabisabi.index_each_tag(:plugin) {|e|
	resolve_plugin(e)
      }
      return wabisabi
    end

    def nu2_resolve_all_plugin(wabisabi)
      wabisabi.make_index
      return wabisabi.index_each_tag(:plugin) {|e|
	new_ele = resolve_plugin(e)
	e.replace(new_ele)
      }
    end

    def resolve_plugin(w)
      attr = w.attr
      return [] if attr.nil?

      method = attr[:method]
      return [] if method.nil? || method.empty?

      param  = attr[:param]
      param ||= ''

      if w[2]
	data   = w[2].to_s
	result = self.c_call_plugin(method, param) { data }
      else
	result = self.c_call_plugin(method, param)
      end

      result = [] if result.nil?
     #result = [] if result.empty?
      result = [result] if ! result.is_a?(Array)
      return result
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActResolve < Test::Unit::TestCase
    include TestSession

    def ok(e, w)
      eq e, @action.resolve_plugin(w)
    end

    def test_resolve_plugin
      res = session
      ok [], [:a]
      ok [], [[:plugin]]	# error
      ok [], [[:plugin, 't']]	# error
      ok [:br], [:plugin, {:method=>'br', :param=>''}, '']
    end

    def ok_all(e, w)
      w.make_index
      eq e, @action.resolve_all_plugin(w)
    end

    def test_resolve_all_plugin
      res = session
      ok_all [[:br]], [[:plugin, {:method=>'br', :param=>''}, '']]
      ok_all [[:span, {:class=>"plg_error"}, "nosuch plugin | ",
	  [:strong, "nosuchplugin"]]],
	     [[:plugin, {:method=>'nosuchplugin', :param=>''}, '']]
    end
  end
end
