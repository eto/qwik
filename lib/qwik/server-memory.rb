# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
#require 'qwik/farm'	# Do not add farm here.

module Qwik
  class ServerMemory
    def initialize(config)
      @config = config
      @cache = {}
    end

    def [](k)
      @cache[k]
    end

    def []=(k, v)
      @cache[k] = v
    end

    # farm
    def farm
#      @farm = Farm.new(@config, self) unless defined? @farm
#      @farm
      return Farm.new(@config, self)
    end

    # template
    def template
      @template = TemplateFactory.new(@config) unless defined? @template
      @template
    end

    # catalog
    def catalog
      unless defined? @catalog
	@catalog = CatalogFactory.new
	@catalog.load_all_here('catalog-??.rb')
      end
      @catalog
    end

    # act-theme
    def theme
      @theme = ThemeFactory.new(@config) unless defined? @theme
      @theme
    end

    # common-session
    def sessiondb
      @sessiondb = SessionDB.new(@config) unless defined? @sessiondb
      @sessiondb
    end
  end
end
