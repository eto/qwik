# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH << 'compat' unless $LOAD_PATH.include? 'compat'
require 'htree'

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module HTree
  class Doc
    def to_wabisabi
      return children.map {|child|
	child.to_wabisabi
      }
    end
  end

  class XMLDecl
    def to_wabisabi
      w = [:'?xml']
      w << @version
      w << @encoding if @encoding
      w << @standalone ? 'yes' : 'no' if @standalone
      return w
    end
  end

  class DocType
    def to_wabisabi
      w = [:'!DOCTYPE']
      w << root_element_name
      w << 'PUBLIC'
      w << public_identifier
      w << system_identifier
      return w
    end
  end

  module Node
    def to_wabisabi
      ar = []

      element_name = name.sub('{http://www.w3.org/1999/xhtml}', '').intern
      ar << element_name

      if 0 < attributes.length
	h = {}
	attributes.each {|k, v|
	  h[k.to_s.intern] = v.to_s
	}
	ar << h
      end

      children.each {|h|
	case h
	when Elem, Text, Comment, BogusETag
	  ar << h.to_wabisabi
	else
	  p 'what?', h
	end
      }

      return ar
    end
  end

  class Text
    def to_wabisabi
      return to_s
    end
  end

  class Comment
    def to_wabisabi
      return [:'!--', @content]
    end
  end

  class BogusETag
    def to_wabisabi
      return ''
    end
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  $test = true
end

if defined?($test) && $test
  class TestHTreeToWabisabi < Test::Unit::TestCase
    def ok_ht(e, str)
      ok_eq(e, HTree(str).to_wabisabi)
    end

    def ok(e, htree)
      ok_eq(e, htree.to_wabisabi)
    end

    def test_doc
      ok([[:'!DOCTYPE', 'html', 'PUBLIC',
	     '-//W3C//DTD html 4.01 Transitional//EN',
	     'http://www.w3.org/TR/html4/loose.dtd'],
	   [:html, [:head, [:title, 't']], [:body, [:p, 'b']]]],
	 HTree('<!DOCTYPE HTML PUBLIC "-//W3C//DTD html 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd"><html><head><title>t</title></head><body><p>b</p></body></html>'))

      e = HTree::Elem.new('a')
      doc = HTree::Doc.new(e)
      ok_eq('#<HTree::Doc {emptyelem <a>}>', doc.inspect)
      ok([[:a]], doc)
    end

    def test_xmldecl
      ok_ht([[:'?xml', '1.0', 'utf-8']],
	    '<?xml version="1.0" encoding="utf-8"?>')

      e = HTree::XMLDecl.new('1.0', 'utf-8')
      ok_eq('{xmldecl }', e.inspect)
      ok([:'?xml', '1.0', 'utf-8'], e)
    end

    def test_doctype
      ok_ht([[:'!DOCTYPE', 'html', 'PUBLIC',
		 '-//W3C//DTD html 4.01 Transitional//EN',
		 'http://www.w3.org/TR/html4/loose.dtd']],
	     '<!DOCTYPE HTML PUBLIC "-//W3C//DTD html 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">')

      e = HTree::DocType.new('HTML', '-//W3C//DTD html 4.01 Transitional//EN',
			     'http://www.w3.org/TR/html4/loose.dtd')
#     ok_eq('{doctype <!DOCTYPE HTML PUBLIC "-//W3C//DTD html 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">}', e.inspect)
      ok_eq("PUBLIC \"-//W3C//DTD html 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\"", e.generate_content)
      ok([:'!DOCTYPE', 'HTML', 'PUBLIC',
	   '-//W3C//DTD html 4.01 Transitional//EN',
	   'http://www.w3.org/TR/html4/loose.dtd'], e)
    end

    def test_node
      ok_ht([[:a]], '<a/>')
      ok_ht([[:a]], '<a></a>')
      ok_ht([[:a, [:b]]], '<a><b/></a>')
      ok_ht([[:a, {:href=>'foo.html'}]], "<a href='foo.html'></a>")

      e = HTree::Elem.new('a')
      ok([:a], e)	# test_elem
      e = HTree::Elem.new('b', e)	# test_elem_with_elem
      ok([:b, [:a]], e)
      e = HTree::Elem.new('a', {'href'=>'foo.html'})	# test_elem_with_attr
      ok([:a, {:href=>'foo.html'}], e)
    end

    def test_text
      ok_ht(['a'], 'a')
      e = HTree::Text.new('a')
      ok('a', e)
    end

    def test_comment
      ok_ht([[:'!--', 'c']], '<!--c-->')
      e = HTree::Comment.new('a')
      ok_eq('a', e.content)
      ok([:'!--', 'a'], e)
    end

    def test_bogustag
      ok([[:p, 't']], HTree('<p>t</p>'))
      ok([[:p, 't'], ''], HTree('<p>t</p></p>'))
    end
  end
end
