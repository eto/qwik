#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '../../lib' unless $LOAD_PATH.include?('../../lib')

module TestModulePublic
  def t_make_public(klass, *args)
    args.each {|method_name|
      klass.instance_eval {
	public method_name
      }
    }
  end

  def t_make_readable(klass, *args)
    args.each {|variable_name|
      klass.instance_eval {
	attr_reader variable_name
      }
    }
  end

  def t_make_writable(klass, *args)
    args.each {|variable_name|
      klass.instance_eval {
	attr_writer variable_name
      }
    }
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class DummyClass
    def initialize
      @var = 't'
    end

    private

    def hello
      return 'hello'
    end
  end

  class TestTestModulePublic < Test::Unit::TestCase
    include TestModulePublic

    def test_all
      dc = DummyClass.new

      # test_t_make_public
      ok_eq(true, dc.private_methods.include?('hello'))
      ok_eq(false, dc.public_methods.include?('hello'))
      t_make_public(DummyClass, :hello)
      ok_eq('hello', dc.hello)
      ok_eq(false, dc.private_methods.include?('hello'))
      ok_eq(true, dc.public_methods.include?('hello'))

      # test_t_make_readable
      t_make_readable(DummyClass, :var)
      ok_eq('t', dc.var)
    end
  end
end
