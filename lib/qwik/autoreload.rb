#
# Copyright (C) 2001-2006 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

require 'thread'

class AutoReload
  def self.start(interval, verbose = false, name=nil)
    ar = AutoReload.new
    ar.verbose = verbose
    ar.name = name
    ar.autoreload(interval)
  end

  def initialize
    @status = {}
    @thread = nil
    @verbose = false
    @name = nil
  end
  attr_accessor :verbose
  attr_accessor :name

  def message(str)
    msg = str
    msg = @name.to_s+': '+msg if @name
    return msg
  end

  def autoreload(interval)
    @thread = Thread.new {
      loop {
	begin
	  update
	rescue Exception
	  STDOUT.puts(message('reload: '+$!))
	end
	sleep interval
      }
    }
    @thread.abort_on_exception = true
  end

  private

  def update
    check_lib = [$0] + $"
    check_lib.each {|lib|
      check_lib(lib)
    }
  end

  def check_lib(lib)
    if @status[lib]
      file, mtime = @status[lib]
      return if ! FileTest.exist?(file) # file is disappered.
      curtime = File.mtime(file).to_i
      if mtime < curtime
        if @verbose
          $stdout.puts(message("reload: \"#{file}\""))
        end
	load file	# Load it.
	@status[lib] = [file, curtime]
      end
      return
    end

    check_path = [''] + $LOAD_PATH
    #check_path = ['']
    check_path.each {|path|
      file = File.join(path, lib)
      file = lib if path.empty?	# Check if the lib is a filename.
      if FileTest.exist?(file)
	@status[lib] = [file, File.mtime(file).to_i]
	return 
      end
    }

    #raise "The library '#{lib}' is not found."
    # $stdout.puts(message("The library '#{lib}' is not found.")) if @verbose
  end

  def get_status(file)
    if FileTest.exist?(file)
      return [file, File.mtime(file).to_i]
    end
    return nil
  end
end

def autoreload(*a)
  AutoReload.start(*a)
end
