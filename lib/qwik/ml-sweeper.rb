#
# Copyright (C) 2002-2004 Satoru Takabayashi <satoru@namazu.org> 
# Copyright (C) 2003-2006 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
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
	if Sweeper.ml_file?(filename)
	  mlname = File.basename(filename)
	  address = Sweeper.mladdress(mlname, @config.ml_domain)
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

    def self.ml_file? (filename)
      return false if File.file?(filename)
      return false if /\./ =~ File.basename(filename) # avoid the name with dot
      return true
    end

    def self.mladdress (name, ml_domain)
      return "#{name}@#{ml_domain}"
    end

    def sweep_ml (ml)
      if ml.inactive?
	@logger.log "[#{ml.name}]: Inactive"
	#ml.close
	ml.close_dummy
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
      c = QuickML::Sweeper
      eq true, c.ml_file?('/qwik/data/test')
      eq "test@example.net", c.mladdress('test', 'example.net')
    end
  end
end
