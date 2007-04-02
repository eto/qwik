# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH << 'compat' unless $LOAD_PATH.include? 'compat'
require 'htree'
$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module HTree
  class Attr < Hash
    def initialize(h)
      self.update(h)
    end
  end

  module Container
    def html_tags(*tags)
      ar = []
      tags.map {|tag|
	ar << tag
	ar << "{http://www.w3.org/1999/xhtml}#{tag}"
      }
      return ar
    end

    def replace(*otags, &block)
      tags = html_tags(*otags)

      subst = {}
      each_child_with_index {|descendant, i|
	if ! descendant.elem?
	  subst[i] = descendant
	  next
	end

	if tags.length == 0 || tags.include?(descendant.name)
	  y = yield(descendant)
	  if !(y === descendant)
	    subst[i] = y
	    next
	  end
	end

	subst[i] = descendant.replace(*tags, &block)
      }
      return to_node.subst_subnode(subst)
    end
    alias each_tag replace

    def apply(data)
      replace {|e|
	eid = e.get_attr('id')
	next e if eid.nil?
	eid = eid.intern
	d = data[eid]
	next nil if d.nil?
	next e if d == true
	if d.is_a? HTree::Attr
	  next e.clone_with(d)
	elsif d.is_a? Array
	  next e.clone_with(d.flatten)
	end
	e.clone_with(d)
      }
    end
  end

  class Elem
    include Enumerable
    alias each each_child

    def delete_spaces
      ar = map {|e|
	e.is_a?(HTree::Text) ? e.to_s.sub(/^\s+/, "").sub(/\s+$/, "") : e
      }
      clone_without_child.clone_with(ar)
    end

    def clone_without_child
      name = self.name
      org_attr = self.attributes
      attr = symbol_to_str(org_attr)
      return Elem.new(name, attr)
    end

    def clone_with(*ar)
      name = self.name
      org_attr = self.attributes
      attr = symbol_to_str(org_attr)

      nar = []
      ar.flatten.each {|e|
	if e.is_a?(Hash)
	  data = symbol_to_str(e)
	  attr.update(data)
	elsif e.nil?
	  # do nothing
	else
	  nar << e
	end
      }

      return Elem.new(name, attr, @children, *nar)
    end

    private

    def symbol_to_str(sdata)
      data = {}
      sdata.each {|k, v|
	data[k.to_s] = v.to_s
      }
      return data
    end
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  require 'qwik/htree-format-xml'
  require 'qwik/htree-generator'
  $test = true
end

if defined?($test) && $test
  class TestHTreeTemplate < Test::Unit::TestCase
    def ok(e, s)
      ok_eq(e, s.format_xml)
    end

    def test_all
      g = HTree::Generator.new

      # test_symbol_to_str
      HTree::Elem.instance_eval {
	public :symbol_to_str
      }
      ok_eq({'t'=>'s'}, g.a.symbol_to_str({:t => 's'}))

      # test_apply
      org = HTree("<p><div id='a'/><div id='b'/></p>")
      data = {}
      data[:a] = 'a'
      data[:b] = g.b
      h = org.apply(data)
      ok("<p><div id=\"a\">a</div><div id=\"b\"><b/></div></p>", h)

      data = {}
      data[:a] = nil
      data[:b] = HTree::Attr.new(:action => 'd.html')
      h = org.apply(data)
      ok("<p><div action=\"d.html\" id=\"b\"></div></p>", h)

      data = {}
      data[:a] = [['a', g.hr]] # OK.
      data[:b] = nil
      h = org.apply(data)
      ok("<p><div id=\"a\">a<hr/></div></p>", h)

      # test_each_tag
      org = HTree("<a><b><c/><d/><c/></b></a>")
      ok("<a><b><c/><d/><c/></b></a>", org)
      xml = org.each_tag('c'){|e| nil }
      ok("<a><b><d/></b></a>", xml)
      xml = org.each_tag('c'){|e| e }
      ok("<a><b><c/><d/><c/></b></a>", xml)
      xml = org.each_tag('c'){|e| HTree::Elem.new('cc') }
      ok("<a><b><cc/><d/><cc/></b></a>", xml)
      xml = org.each_tag('c'){|e| g.dd }
      ok("<a><b><dd/><d/><dd/></b></a>", xml)
      xml = org.each_tag('c'){|e| e.clone_with('test1') }
      ok("<a><b><c>test1</c><d/><c>test1</c></b></a>", xml)

      # test_set_attr
      e = g.a(:href => 't.html'){'t'}
      ok("<a href=\"t.html\">t</a>", e)
      e = e.clone_with('href' => 's.html')
      ok("<a href=\"s.html\">t</a>", e)
      e = e.clone_with('s')
      ok("<a href=\"s.html\">ts</a>", e)

      # test_textarea
      org = HTree("<textarea></textarea>")
      htree = org.replace('textarea'){|e|
	e.clone_with('text')
      }
      ok("<textarea>text</textarea>", htree)
      org = HTree("<textarea id='contents'></textarea>")
      data = {}
      data[:contents] = 'text'
      htree = org.apply(data)
      ok("<textarea id=\"contents\">text</textarea>", htree)

      # test_html_tags
      h = HTree("<a>")
      ok_eq(['a', "{http://www.w3.org/1999/xhtml}a"], h.html_tags('a'))
      ok_eq(['a', "{http://www.w3.org/1999/xhtml}a", 'b', "{http://www.w3.org/1999/xhtml}b"], h.html_tags('a', 'b'))

      # test_clone
      h = HTree("<a href='1.html'>t</a>")
      e = h.children[0]
      xml = e.clone_with('test1')
      ok("<a href=\"1.html\">ttest1</a>", xml)
      xml = e.clone_with('href'=>'n.html')
      ok("<a href=\"n.html\">t</a>", xml)
    end

    def test_replace
      g = HTree::Generator.new

      h = HTree("<a><b/><c/></a>")

      h2 = h.replace {|e| e.name == 'c' ? 'text' : e } # insert a text
      ok("<a><b/>text</a>", h2)

      h2 = h.replace('nosuch') {|e| nil } # no effect
      ok("<a><b/><c/></a>", h2)

      h2 = h.replace('b') {|e| e } # no effect
      ok("<a><b/><c/></a>", h2)

      h2 = h.replace('b') {|e| nil } # delete it
      ok("<a><c/></a>", h2)

      h2 = h.replace('b') {|e| 'text' } # insert a text
      ok("<a>text<c/></a>", h2)

      h2 = h.replace('b') {|e| g.d } # insert a element
      ok("<a><d/><c/></a>", h2)

      h2 = h.replace('b') {|e| g.d{'text'} } # insert a element with text
      ok("<a><d>text</d><c/></a>", h2)

      h = HTree("<p><span id='a'/><span id='b'/></p>")

      h2 = h.replace('span'){|e| e.get_attr('id') } # insert the id as text
      ok("<p>ab</p>", h2)

      h2 = h.replace('span'){|e| e.get_attr('id') == 'b' ? e : nil }
      ok('<p><span id='b'/></p>', h2)

      h = HTree("<h2/><h3/><h4/><h5/><h6/>")

      h2 = h.replace('h3', 'h4') {|e| g.make(e.name){ e.name } } # insert a text
      ok("<h2/><h3>h3</h3><h4>h4</h4><h5/><h6/>", h2)

      h2 = h.replace {|e| e.name == 'h5' ? 'text' : e } # insert a text
      ok("<h2/><h3/><h4/>text<h6/>", h2)

      h2 = h.replace('h4') {|e| [g.h3{'h'}, g.hr] } # 
      ok("<h2/><h3/><h3>h</h3><hr/><h5/><h6/>", h2)

      h = HTree("<span></span>")
      h2 = h.each_tag('span'){|e| [g.h3{'h'}, g.hr] }
      ok("<h3>h</h3><hr/>", h2)

      h2 = h.each_tag('span'){|e|
	[g.h3{'h3'}, g.ul{g.li{g.a('href'=>'1.html'){'1'}}}]
      }
      ok("<h3>h3</h3><ul><li><a href=\"1.html\">1</a></li></ul>", h2)
    end
  end
end
