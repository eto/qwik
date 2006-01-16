#
# Copyright (C) 2002-2004 Satoru Takabayashi <satoru@namazu.org> 
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '../../lib' unless $LOAD_PATH.include?('../../lib')
require 'qwik/group'

module QuickML
  class Sweeper
    def initialize (config)
      @config = config
      @status = :safe
      @logger = @config.logger
    end

    def start
      @logger.vlog 'Sweeper started'
      loop {
	sleep(@config.sweep_interval)
	begin
	  sweep
	rescue Exception => e
	  @logger.log "Unknown Sweep Error: #{e.class}: #{e.message}"
	  @logger.log e.backtrace
	end
      }
    end

    def shutdown
      until @status == :safe
	sleep(0.5)
      end
      @logger.vlog 'Sweeper shutdown'
    end

    private

    def sweep
      @status = :sweeping
      @logger.vlog 'Sweeper runs'
      Dir.new(@config.sites_dir).each {|filename|
	filename = File.join(@config.sites_dir, filename)
	if ml_file?(filename)
	  address = mladdress(mlname(filename))
	  ServerMemory.ml_mutex(@config, address).synchronize {
            ml = Group.new(@config, address)
	    ml.group_config_check_exist
	    sweep_ml(ml)
	  }
	end
      }
      @logger.vlog 'Sweeper finished'
      @status = :safe
    end

    def ml_file? (filename)
      # original
      #File.file?(filename) && Group.valid_name?(mlname(filename))

      # by eto
      return false if File.file?(filename)
      return false if /\./ =~ File.basename(filename) # avoid the name with dot
      return true
    end

    def mladdress (name)
      address = name 
      address += (name.include?('@')) ? '.' : '@'
      address += @config.ml_domain
      return address
    end

    def mlname (filename)
      return File.basename(filename)
    end

    def sweep_ml (ml)
      if ml.inactive?
	@logger.log "[#{ml.name}]: Inactive"
	ml.close
      elsif ml.need_alert?
	ml.report_ml_close_soon
      end
    end

  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  require 'qwik/test-module-ml'
  $test = true
end

if defined?($test) && $test
  class TestMLSweeper < Test::Unit::TestCase
    include TestModuleML

    def test_all
      t_make_public(QuickML::Sweeper, :ml_file?)

      sweeper = QuickML::Sweeper.new(@ml_config)
      ok_eq(true, sweeper.ml_file?('/qwik/data/test'))
    end

  end
end
