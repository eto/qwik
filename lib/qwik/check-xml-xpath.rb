# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/test-common'

#class TestXPath < Test::Unit::TestCase
class TestXPath
  include TestSession

  def test_xpath
    t_add_user
    page = @site.create_new
    page.store('t')

    session('/test/1.html')
    px("//div[@class='section']", 0)

    require 'xml/xpath'
    xpath = XML::XPATH.new
    xpath.xml = @res.body.format_xml.page_to_xml
    i = xpath.execute("//div[@class='section']/p")
    print "#{i} nodes :\n"
    p xpath.to_a
  end
end
