# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/mdlb-sample'
require 'qwik/htree-to-wabisabi'
require 'qwik/util-charset'

# $KCODE = 's'

module Modulobe
  class Model
    def initialize(xml)
      @wabisabi = Model.parse_xml(xml)
      @speed = Model.extract_world(@wabisabi)
      @name, @author, @comment = Model.extract_info(@wabisabi)
    end

    def self.parse_xml(xml)
      xml ||= ''
      return HTree(xml).to_wabisabi
    end

    def self.extract_world(wabisabi)
      world = wabisabi.get_path('//world')
      return nil if world.nil?
      speed = world.get_path('/speed').text
      return speed
    end

    def self.extract_info(wabisabi)
      info = wabisabi.get_path('//model/info')
      return nil if info.nil?
      name    = info.get_path('/name').text.set_xml_charset.to_page_charset
      author  = info.get_path('/author').text.set_xml_charset.to_page_charset
      comment = info.get_path('/comment').text.set_xml_charset.to_page_charset
      return name, author, comment
    end
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  $test = true
end

if defined?($test) && $test
  class TestMdlbModel < Test::Unit::TestCase
    def test_all
      c = Modulobe::Model

      xml = Modulobe::Sample::MODEL1

      # test_parse_xml
      ok_eq([], c.parse_xml(''))
      w = c.parse_xml(xml)
      ok_eq([:'?xml', '1.0', 'utf-8'], w[0])

      # test_extract_world
      ok_eq('0', c.extract_world(w))

      # test_extract_info
      ok_eq(nil, c.extract_info([]))
      ok_eq(['test model', 'test author', "test comment.\n"],
	    c.extract_info(w))

      xml = Modulobe::Sample::MODEL_CORE
      w = c.parse_xml(xml)
      ok_eq(['', '', ''], c.extract_info(w))

      xml = Modulobe::Sample::MODEL_WITH_NAME
      w = c.parse_xml(xml)
      ok_eq(['n', 'a', "c\n"], c.extract_info(w))

      xml = Modulobe::Sample::MODEL_WITH_JNAME
      w = c.parse_xml(xml)
      ok_eq(["\202\240 ", "\202\242 ", "\202\244\n"], c.extract_info(w))
    end
  end
end
