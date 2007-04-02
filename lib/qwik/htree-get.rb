# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH << 'compat' unless $LOAD_PATH.include? 'compat'
require 'htree'

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/htree-template'

module HTree
  module Container
    def split_name_num(name)
      name = name.sub(%r|(^//)|, '')

      if /^(\w+)\[(\d+)\]$/ =~ name
	return [$1, $2.to_i]
      end

      return [name, 1]
    end

    def find_nth_element(num=1, *names)
      i = 1
      traverse_element(*names) {|e|
	return e if i == num
	i += 1
      }
      return nil
    end

    def get_tag(tag)
      tag, num = split_name_num(tag)
      names = html_tags(tag)
      return find_nth_element(num, *names)
    end

    def each_in_class(klass)
      klass, knum = split_name_num(klass)
      k = 1
      klass_path = nil
      make_loc.traverse_element {|l|
	if klass_path.nil?
	  if l.to_node.get_attr('class') == klass
	    if k == knum
	      klass_path = l.path
	    else
	      k += 1
	    end
	  end
	elsif l.path.include?(klass_path)
	  yield l
	end
      }
      return nil
    end

    def get_class_tag(klass, tag)
      tag, num = split_name_num(tag)
      i = 1
      each_in_class(klass) {|l|
	ar = l.path.split('/')
	e = ar.last
	if e == tag
	  return l.to_node if i == num
	  i += 1
	end
      }
      return nil
    end

    def each_class(klass) # obsolete
      return each_has_attr('class', klass, &b)
    end

    def get_class(klass) # obsolete
      return get_has_attr('class', klass)
    end

    def each_has_attr(attr, value)
      make_loc.traverse_element {|l|
	if l.to_node.get_attr(attr) == value
	  yield(l.to_node)
	end
      }
    end

    def get_has_attr(attr, value)
      each_has_attr(attr, value) {|l|
	return l.to_node
      }
      return nil
    end

    def get_a_path(path)
      if /\A(.*)\[(.+)\]\z/ =~ path
	tag = $1
	select = $2
	if /\A@([a-z]+)='([a-z]+)'\z/ =~ select
	  attr = $1
	  value = $2
#	  if attr == 'class'
#	    return get_class(cont)
#	  end
	  return get_has_attr(attr, value)
	end
      end

      return get_tag(path)
    end

    def get_path(path)
      xml = self
      path.split('/').each {|pa|
	if 0 < pa.length
	  return nil if xml.nil?
	  xml = xml.get_a_path(pa)
	end
      }
      return xml
    end
  end

  class Elem
    def attributes_str
      return hash_to_str(attributes)
    end

    def hash_to_str(src)
      h = {}
      src.each {|k, v| h[k.to_s] = v.to_s }
      return h
    end
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  require 'qwik/htree-format-xml'
  $test = true
end

if defined?($test) && $test
  class TestHTreeGet < Test::Unit::TestCase
    def ok(e, s)
      return '' if s.nil?
      ok_eq(e, s.format_xml)
    end

    def test_all
      # test_get_tag
      e = HTree::Elem.new('e')

      # test_split_name_num
      ok_eq(['sidebar', 1], e.split_name_num('sidebar'))
      ok_eq(['sidebar', 1], e.split_name_num("sidebar[1]"))
      ok_eq(['sidebar', 2], e.split_name_num("sidebar[2]"))

      # test_get_tag
      h = HTree("<a><b><c>")
      ok("<c/>", h.get_tag('c'))
      ok("<b><c/></b>", h.get_tag('b'))

      # test_each_in_class
      h = HTree("<p class='a'><ta/></p><p class='b'><tb/></p><p class='b'><tb2/></p>")
      h.each_in_class('a') {|l|
	ok_eq("doc()/p[1]/ta", l.path)
	ok("<ta/>", l.to_node)
      }
      h.each_in_class('b') {|l|
	ok_eq("doc()/p[2]/tb", l.path)
	ok("<tb/>", l.to_node)
      }
      h.each_in_class("b[2]") {|l|
	ok_eq("doc()/p[3]/tb2", l.path)
	ok("<tb2/>", l.to_node)
      }

      ok("<ta/>", h.get_class_tag('a', 'ta'))
      ok("<tb/>", h.get_class_tag('b', 'tb'))
      ok("<tb2/>", h.get_class_tag("b[2]", 'tb2'))

      str = <<'EOS'    
<html><div class='main'>
<div class='day'><h2>bh2</h2></div>
<div class='sidebar'><h2>sh2</h2></div>
</div></html>
EOS
      h = HTree(str)
      ok("<html><div class=\"main\">\n<div class=\"day\"><h2>bh2</h2></div>\n<div class=\"sidebar\"><h2>sh2</h2></div>\n</div></html>\n", h)
      ok("<h2>bh2</h2>", h.get_tag('h2'))
      ok("<h2>sh2</h2>", h.get_tag("h2[2]"))
      ok("<h2>bh2</h2>", h.get_class_tag('day', 'h2'))
      ok("<h2>sh2</h2>", h.get_class_tag('sidebar', 'h2'))

      # test_get_tag2
      h = HTree("<a><b>tb</b><b>tb2</b><c>")
      ok("<b>tb</b>", h.get_tag('b'))
      ok_eq(nil, h.get_tag('nosuchtag'))
      ok("<b>tb</b>", h.get_tag("b[1]"))
      ok("<b>tb2</b>", h.get_tag("b[2]"))
      ok("<b>tb</b>", h.get_tag("//b"))

      # test_xpath
      str = <<'EOS'
<html><div class='main'>
<div class='day'><h2>bh2</h2></div>
<div class='sidebar'><h2>sh2<b>a</b>sh2a</h2></div>
</div></html>
EOS
      h = HTree(str)
      #ok("<html><div class=\"main\">\n<div class=\"day\"><h2>bh2</h2></div>\n<div class=\"sidebar\"><h2>sh2</h2></div>\n</div></html>\n", h)
      #ok("<h2>sh2</h2>", h.get_class_tag('sidebar', 'h2'))
      #ok("<h2>sh2<b>a</b>sh2a</h2>", h.get_class('sidebar'))
      ok("<div class=\"sidebar\"><h2>sh2<b>a</b>sh2a</h2></div>",
	 h.get_class('sidebar'))
      ok_instance_of(HTree::Elem, h.get_class('sidebar'))
      ok("<b>a</b>", h.get_class('sidebar').get_tag('b'))
      ok("<div class=\"sidebar\"><h2>sh2<b>a</b>sh2a</h2></div>",
	 h.get_a_path("div[@class='sidebar']"))
      ok("<b>a</b>", h.get_a_path("div[@class='sidebar']").get_a_path('b'))
      ok("<div class=\"sidebar\"><h2>sh2<b>a</b>sh2a</h2></div>",
	 h.get_path("//div[@class='sidebar']"))
      ok("<b>a</b>", h.get_path("//div[@class='sidebar']/b"))

      str = <<'EOS'
<a href='t1' alt='t2'>t3</a>
EOS
      h = HTree(str)
      ok_instance_of(HTree::Doc, h)
      e = h.get_tag('a')
      ok_instance_of(HTree::Elem, e)
      ok("<a href=\"t1\" alt=\"t2\">t3</a>", e)
      #ok_eq({href=>{text 't1'}, alt=>{text 't2'}}, e.attributes)
      ok_eq({'href'=>'t1', 'alt'=>'t2'}, e.attributes_str)

      # test_xpath_attr
      str = <<'EOS'
<html><div class='main'>
<div id='menu'><h2>menuh2</h2></div>
</div></html>
EOS
      h = HTree(str)
      ok("<div id=\"menu\"><h2>menuh2</h2></div>",
	 h.get_has_attr('id', 'menu'))
      ok_instance_of(HTree::Elem, h.get_has_attr('id', 'menu'))
      ok("<div id=\"menu\"><h2>menuh2</h2></div>",
	 h.get_path("//div[@id='menu']"))
    end
  end
end
