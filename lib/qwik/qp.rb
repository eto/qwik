# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

module QP
  def caller_msg(ca)
    file, linenum, msg = ca.first.split(/:([0-9]+):/)
    msg = $1 if /\Ain \`(.+)\'\z/ =~ msg
    File.basename(file)+':'+linenum.to_s+':'+msg.to_s
  end

  def ar_inspect(ar)
    '['+ar.map {|arg| arg.inspect }.join(', ')+']'
  end

  def runtime
    $__qp_t__ = Time.now unless defined? $__qp_t__
    sprintf('%.1f', Time.now - $__qp_t__)
  end

  def qp(ca, *args)
    QP.caller_msg(ca)+"\t"+QP.ar_inspect(args)
  end

  def tp(ca, *args)
    QP.runtime+':'+QP.qp(ca, *args)
  end

  module_function :caller_msg, :ar_inspect, :runtime, :qp, :tp
end

def qp(*args)
  $stdout.print QP.qp(caller(1), *args)+"\n"
end

def tp(*args)
  print QP.tp(caller(1), *args)+"\n"
end

if $0 == __FILE__
  $LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
  $test = true
end

if defined?($test) && $test
  require 'qwik/testunit'

  class TestQP < Test::Unit::TestCase
    def test_all
      #assert_match(/testcase.rb:\d\d:_*send_*/, QP.caller_msg(caller(1)))
      ok_eq("[1, \"a\"]", QP.ar_inspect([1, 'a']))
      assert_match(/\d+\.\d/, QP.runtime)
      #assert_match(/\d+\.\d:testcase.rb:\d\d:_*send_*	\[1, 'a'\]/, QP.tp(caller(1), 1, 'a'))
    end
  end
end
