# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

# See qwik/wabisabi-format-xml.rb for complete test.

require 'test/unit'
require 'ext/xmlformatter.so'

class TextXMLFormatter_so < Test::Unit::TestCase
  def test_all
    formatter = Gonzui::XMLFormatter.new
    assert_equal("<a\n/>", formatter.format([:a]))
  end
end
