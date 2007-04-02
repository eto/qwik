# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/util-pathname'

module PidModule
  def write_pid_file(pidfile)
    pidfile.path.put("#{Process.pid}\n")
  end

  def read_pid_file(pidfile)
    pid = nil
    pid = pidfile.path.get_first.chomp.to_i
    return pid
  end

  def remove_pid_file(pidfile)
    if Process.pid == read_pid_file(pidfile)
      pidfile.path.unlink
    end
  end

  # for test
  def exist_pid_file?(pidfile)
    return pidfile.path.exist?
  end
end

if $0 == __FILE__
  require 'test/unit'
  $test = true
end

if defined?($test) && $test
  class TestUtilPid < Test::Unit::TestCase
    include PidModule

    def test_all
      f = 'test-pid.txt'

      # test_exist_pid_file?
      assert_equal false, exist_pid_file?(f)

      # test_write_pid_file
      write_pid_file(f)
      assert_equal true, exist_pid_file?(f)

      # test_read_pid_file
      assert_equal Process.pid, read_pid_file(f)
      
      # test_remove_pid_file
      remove_pid_file(f)
      assert_equal false, exist_pid_file?(f)
    end
  end
end
