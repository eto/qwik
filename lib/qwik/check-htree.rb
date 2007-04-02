# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH << 'compat' unless $LOAD_PATH.include? 'compat'
require 'htree'

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/testunit'

class CheckHTree < Test::Unit::TestCase
  def assert_xhtml(expected, template, message=nil)	# from htree/test
    prefix = "<html\n>"
    suffix = "</html\n>"
    result = HTree.expand_template(''){"<html>#{template}</html>"}
    assert_match(/\A#{Regexp.quote prefix}/, result)
    assert_match(/#{Regexp.quote suffix}\z/, result)
    result = result[prefix.length..(-suffix.length-1)]
    ok_eq(expected, result, message)
  end

  def test_htree
    return	# do not test.

    assert_xhtml("<b\n>t</b\n>", '<b>t</b>')
    assert_xhtml("<e\n>1</e\n>", '<e _text=1>d</e>')
    str = '<html><e _text=1>d</e></html>'

    doc = HTree(str)	# doc is a template
    assert_instance_of(HTree::Doc, doc)
    assert_instance_of(HTree::Elem, doc.root)
    ok_eq('{http://www.w3.org/1999/xhtml}html', doc.root.name)
    assert_instance_of(HTree::Elem, doc.root.children[0])
    assert_instance_of(HTree::Elem, doc.root.children[0])
    assert_instance_of(HTree::Text, doc.root.children[0].children[0])
    assert_instance_of(String, doc.root.children[0].children[0].rcdata)
    ok_eq('d', doc.root.children[0].children[0].rcdata)

    doc = HTree{str}	# doc is a document. the template is evaluated.
    assert_instance_of(HTree::Doc, doc)
    assert_instance_of(HTree::Elem, doc.root)
    assert_instance_of(HTree::Elem, doc.root.children[0])
    assert_instance_of(HTree::Text, doc.root.children[0].children[0])
    ok_eq('1', doc.root.children[0].children[0].rcdata)

    str = "<html>\n  <body _text=\"body\"></body>\n</html>"
    body = 'b'
    result = HTree.expand_template(''){str}
    ok_eq("<html\n><body\n>b</body\n></html\n>", result)
  end
end
