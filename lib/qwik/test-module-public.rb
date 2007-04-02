# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

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
  require 'test/unit'
  $test = true
end

if defined?($test) && $test
  class TestModulePublicDummyClass
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
      dc = TestModulePublicDummyClass.new

      # test_t_make_public
      assert_equal true,  dc.private_methods.include?('hello')
      assert_equal false, dc.public_methods.include?('hello')
      t_make_public(TestModulePublicDummyClass, :hello)
      assert_equal 'hello', dc.hello
      assert_equal false, dc.private_methods.include?('hello')
      assert_equal true,  dc.public_methods.include?('hello')

      # test_t_make_readable
      t_make_readable(TestModulePublicDummyClass, :var)
      assert_equal 't', dc.var
    end
  end
end
