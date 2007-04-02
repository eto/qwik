# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/util-pathname'
require 'qwik/wabisabi-traverse'

module Qwik
  class TemplateFactory
    def initialize(config)
      @config = config
      @template_path = config.template_dir.path
    end

    def get(cmd)
      if @config.debug
	require 'qwik/template-generator'
	path = @config.template_dir.path
	TemplateGenerator.make(path, cmd)
      end

      method = "generate_#{cmd}"
      if defined?(Template) && Template.respond_to?(method)
	w = Template.send(method)
	patch(w)
	return w
      end

      if check_template(cmd)
	return get(cmd)
      end

      return nil
    end

    def patch(w)
      w[1].insert(1, {:'xmlns:v'=>'urn:schemas-microsoft-com:vml'})
    end

    def check_template(cmd)
      file = @template_path+"#{cmd}.rb"
      return false if ! file.exist?
      require file
    end
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  require 'qwik/config'
  require 'qwik/server-memory'
  $test = true
end

if defined?($test) && $test
  class TestTemplate < Test::Unit::TestCase
    def apply_template(data, template)
      xml = @memory.template.get(template)
      xml.apply(data)
    end

    def test_all
      # setup config
      @config = defined?($test_config) ? $test_config : Qwik::Config.new
      # setup memory
      @memory = defined?($test_memory) ? $test_memory :
	Qwik::ServerMemory.new(@config)

      # test_non_destructive
      template = @memory.template.get('notice')
      id1 = template.object_id
      head = template.get_tag(:head)
      length1 = head.length
      head << [:title, 'title'] # destructive method

      template = @memory.template.get('notice')
      id2 = template.object_id
      assert_not_equal(id1, id2)
      head = template.get_tag(:head)
      length2 = head.length
      ok_eq(length2, length1)
    end
  end
end
