# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/wabisabi-basic'

module WabisabiTemplateModule
  def deep_copy
    map {|a|
      a.is_a?(Array) ? a.deep_copy : a
    }
  end

  def prepare
    h_class = {}
    h_id = {}
    self.each_tag {|e|
      attr = self.attr
      next if attr.nil?
      klass = attr[:class]
      h_class[klass] = self if klass
      tag_id = attr[:id]
      h_id[tag_id] = self if tag_id
    }
    @h_class = h_class
    @h_id = h_id
  end

  def set_to_class(klass, w)
    prepare if @h_class
    e = @h_class[klass]
    e << w
  end

  def each_tag(*tags, &block)
    raise 'block not given' unless block_given?

    ar = []
    deleted = false
    self.each {|w|
      if ! w.is_a?(Array)
	ar << w
	next
      end

      if tags.length == 0 || tags.include?(w[0])
	y = yield(w)

	if y.nil?	# do nothing, go next
	  deleted = true
	  next
	end

	if y != w	# not equal
	  if y.is_a?(Array) && !y[0].is_a?(Symbol)
	    ar += y
	  else
	    ar << y
	  end
	  next
	else
	  # do nothing, run through
	end
      end

      ar << w.each_tag(*tags, &block)	# recursive
    }

    if ar[0].is_a?(Symbol) && deleted
      num = 0
      ar.each {|a|
	next if a.is_a?(Symbol) || a.is_a?(Hash)
	num += 1
      }
      if num == 0
	ar << ''
      end
    end

    ar
  end

  def clone_with(*ar)
    name = self[0]
    nar = [name]

    offset = 1
    attr = {}
    while self[offset].is_a?(Hash)
      attr.update(self[offset])
      offset += 1
    end
    if 0 < attr.length
      nar << attr
    end

    nar += self[offset...self.length].dup
    ar.each {|e|
      if e.is_a?(Hash)
	attr.update(e)
      elsif e.nil?
	# do nothing
      else
	nar << e
      end
    }
    nar
  end

  def apply(data)
    self.each_tag {|e|
      next e unless e[0].is_a?(Symbol)
      next e unless e[1].is_a?(Hash)
      attr = e[1]
      eid = attr[:id]
      next e if eid.nil?
      eid = eid.intern
      d = data[eid]
      next nil if d.nil?
      next e if d == true
      if d.is_a? Hash
	next e.clone_with(d)
      elsif d.is_a? Array
	next e.clone_with(d)
      end
      e.clone_with(d)
    }
  end

  def remove_comment
    self.each_tag(:"!--") {|x|
      nil
    }
  end
end

class Array
  include WabisabiTemplateModule
end

if $0 == __FILE__
  require 'qwik/testunit'
  $test = true
end

if defined?($test) && $test
  class TestWabisabiTemplate < Test::Unit::TestCase
    def test_all
      # test_deep_copy
      o = [:a, [:b, [:c]]]
      s = o.dup # shallow copy
      d = o.deep_copy
      assert_equal     s, o
      assert_equal     d, o
      assert_not_equal s.object_id, o.object_id
      assert_not_equal d.object_id, o.object_id
      assert_equal     s[0].object_id, o[0].object_id
      assert_equal     d[0].object_id, o[0].object_id
      assert_equal     s[1].object_id, o[1].object_id
      assert_not_equal d[1].object_id, o[1].object_id
      assert_equal     s[1][1].object_id, o[1][1].object_id
      assert_not_equal d[1][1].object_id, o[1][1].object_id

      # test_prepare

      # test_each_tag_unit
      w = [:p, '']
      nw = w.each_tag(:a){|ww|
	[ww]
      }
      assert_equal [:p, ''], w
      assert_equal [:p, ''], nw

      w = [[:a, '']]
      assert_equal [:a, ''], w[0]
      nw = w.each_tag(:a){|ww|
	www = ww.dup
	www[-1] = 't'
	www
      }
      assert_equal [[:a, '']], w
      assert_equal [[:a, 't']], nw

      # test_set_attr
      e = [:a, {:href=>'t.html'}, 't']
      e = e.clone_with(:href=>'s.html')
      assert_equal [:a, {:href=>'s.html'}, 't'], e
      e = e.clone_with('s')
      assert_equal [:a, {:href=>'s.html'}, 't', 's'], e

      # test_each_tag
      org = [:a, [:b, [:c], [:d], [:c]]]
      xml = org.each_tag(:c){|e| nil }
      assert_equal [:a, [:b, [:d]]], xml
      assert_equal [:a, [:b, [:d]]], xml
      xml = org.each_tag(:c){|e| e }
      assert_equal [:a, [:b, [:c], [:d], [:c]]], xml
      xml = org.each_tag(:c){|e| [:cc] }
      assert_equal [:a, [:b, [:cc], [:d], [:cc]]], xml
      xml = org.each_tag(:c){|e| [:dd] }
      assert_equal [:a, [:b, [:dd], [:d], [:dd]]], xml

      # test_each_tag_with_clone
      org = [:a, [:b, [:c], [:d], [:c]]]
      xml = org.each_tag(:c){|e| e.clone_with('test1') }
      assert_equal [:a, [:b, [:c, 'test1'], [:d], [:c, 'test1']]], xml

      # test_clone
      e = [:a, {:href=>'1.html'}, 't']
      xml = e.clone_with('test1')
      assert_equal [:a, {:href=>'1.html'}, 't', 'test1'], xml
      xml = e.clone_with(:href=>'n.html')
      assert_equal [:a, {:href=>'n.html'}, 't'], xml

      # test_textarea
      org = [[:textarea, '']]
      xml = org.each_tag(:textarea){|e|
	e.clone_with('text')
      }
      assert_equal [[:textarea, '', 'text']], xml

      # test_textarea_apply
      org = [[:textarea, {:id=>'contents'}, '']]
      data = {}
      data[:contents] = 'text'
      xml = org.apply(data)
      assert_equal [[:textarea, {:id=>'contents'}, '', 'text']], xml

      # test_apply
      org = [:p, [:div, {:id=>'a'}, ''], [:div, {:id=>'b'}, '']]
      data = {}
      data[:a] = 'a'
      data[:b] = [:b]
      h = org.apply(data)
      assert_equal [:p, [:div, {:id=>'a'}, '', 'a'],
	[:div, {:id=>'b'}, '', [:b]]], h

      data = {}
      data[:a] = nil
      data[:b] = {:action => 'd.html'}
      h = org.apply(data)
      assert_equal [:p, [:div, {:action=>'d.html', :id=>'b'}, '']], h

      data = {}
      data[:a] = ['a', [:hr]]		# OK.
      data[:b] = nil
      h = org.apply(data)
      assert_equal [:p, [:div, {:id=>'a'}, '', ['a', [:hr]]]], h

      # test_replace
      h = [:a, [:b], [:c]]
      h2 = h.each_tag {|e| e[0] == :c ? 'text' : e }	# insert a text
      assert_equal [:a, [:b], 'text'], h2
      h2 = h.each_tag(:nosuch) {|e| nil }	# no effect
      assert_equal [:a, [:b], [:c]], h2
      h2 = h.each_tag(:b) {|e| e }		# no effect
      assert_equal [:a, [:b], [:c]], h2
      h2 = h.each_tag(:b) {|e| nil }		# delete it
      assert_equal [:a, [:c]], h2
      h2 = h.each_tag(:b) {|e| 'text' }		# insert a text
      assert_equal [:a, 'text', [:c]], h2
      h2 = h.each_tag(:b) {|e| [:d] }		# insert a element
      assert_equal [:a, [:d], [:c]], h2
      h2 = h.each_tag(:b) {|e| [:d, 'text'] }	# insert a element with text
      assert_equal [:a, [:d, 'text'], [:c]], h2

      h = [:p, [:span, {:id=>'a'}], [:span, {:id=>'b'}]]
      h2 = h.each_tag(:span){|e| e.attr(:id) }	# insert the id as text
      assert_equal [:p, 'a', 'b'], h2
      h2 = h.each_tag(:span){|e| e.attr(:id) == 'b' ? e : nil }
      assert_equal [:p, [:span, {:id=>'b'}]], h2

      h = [[:h2], [:h3], [:h4], [:h5], [:h6]] 
      h2 = h.each_tag(:h3, :h4) {|e| [e[0], e[0].to_s] }	# insert a text
      assert_equal [[:h2], [:h3, 'h3'], [:h4, 'h4'], [:h5], [:h6]], h2
      h2 = h.each_tag {|e| e[0] == :h5 ? 'text' : e }	# insert a text
      assert_equal [[:h2], [:h3], [:h4], 'text', [:h6]], h2
      h2 = h.each_tag(:h4) {|e| [[:h3, 'h'], [:hr]] }
      assert_equal [[:h2], [:h3], [:h3, 'h'], [:hr], [:h5], [:h6]], h2

      h = [[:span, '']]
      h2 = h.each_tag(:span){|e| [[:h3, 'h'], [:hr]] }
      assert_equal [[:h3, 'h'], [:hr]], h2
      h2 = h.each_tag(:span){|e|
	[[:h3, 'h3'], [:ul, [:li, [:a, {:href=>'1.html'}, '1']]]]
      }
      assert_equal [[:h3, 'h3'], [:ul, [:li, [:a, {:href=>'1.html'}, '1']]]],
		   h2

      # test_remove_comment
      assert_equal [:p, 'a', 'c'], [:p, 'a', [:"!--", 'b'], 'c'].remove_comment
    end
  end
end
