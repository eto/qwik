#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '..' unless $LOAD_PATH.include?('..')
require 'qwik/wabisabi-get'

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
    #qp tags, caller(1)[0]
    #qp tags, caller(1)[0], caller(2)[0]

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
      ok_eq(s, o)
      ok_eq(d, o)
      assert_not_equal(s.object_id, o.object_id)
      assert_not_equal(d.object_id, o.object_id)
      ok_eq(s[0].object_id, o[0].object_id)
      ok_eq(d[0].object_id, o[0].object_id)
      ok_eq(    s[1].object_id, o[1].object_id)
      assert_not_equal(d[1].object_id, o[1].object_id)
      ok_eq(    s[1][1].object_id, o[1][1].object_id)
      assert_not_equal(d[1][1].object_id, o[1][1].object_id)

      # test_prepare

      # test_each_tag_unit
      w = [:p, '']
      nw = w.each_tag(:a){|ww|
	[ww]
      }
      ok_eq([:p, ''], w)
      ok_eq([:p, ''], nw)

      w = [[:a, '']]
      ok_eq([:a, ''], w[0])
      nw = w.each_tag(:a){|ww|
	www = ww.dup
	www[-1] = 't'
	www
      }
      ok_eq([[:a, '']], w)
      ok_eq([[:a, 't']], nw)


      # test_set_attr
      e = [:a, {:href=>'t.html'}, 't']
      e = e.clone_with(:href=>'s.html')
      ok_eq([:a, {:href=>'s.html'}, 't'], e)
      e = e.clone_with('s')
      ok_eq([:a, {:href=>'s.html'}, 't', 's'], e)

      # test_each_tag
      org = [:a, [:b, [:c], [:d], [:c]]]
      xml = org.each_tag(:c){|e| nil }
      ok_eq([:a, [:b, [:d]]], xml)
      ok_eq([:a, [:b, [:d]]], xml)
      xml = org.each_tag(:c){|e| e }
      ok_eq([:a, [:b, [:c], [:d], [:c]]], xml)
      xml = org.each_tag(:c){|e| [:cc] }
      ok_eq([:a, [:b, [:cc], [:d], [:cc]]], xml)
      xml = org.each_tag(:c){|e| [:dd] }
      ok_eq([:a, [:b, [:dd], [:d], [:dd]]], xml)

      # test_each_tag_with_clone
      org = [:a, [:b, [:c], [:d], [:c]]]
      xml = org.each_tag(:c){|e| e.clone_with('test1') }
      ok_eq([:a, [:b, [:c, 'test1'], [:d], [:c, 'test1']]], xml)

      # test_clone
      e = [:a, {:href=>'1.html'}, 't']
      xml = e.clone_with('test1')
      ok_eq([:a, {:href=>'1.html'}, 't', 'test1'], xml)
      xml = e.clone_with(:href=>'n.html')
      ok_eq([:a, {:href=>'n.html'}, 't'], xml)

      # test_textarea
      org = [[:textarea, '']]
      xml = org.each_tag(:textarea){|e|
	e.clone_with('text')
      }
      ok_eq([[:textarea, '', 'text']], xml)

      # test_textarea_apply
      org = [[:textarea, {:id=>'contents'}, '']]
      data = {}
      data[:contents] = 'text'
      xml = org.apply(data)
      ok_eq([[:textarea, {:id=>'contents'}, '', 'text']], xml)

      # test_apply
      org = [:p, [:div, {:id=>'a'}, ''], [:div, {:id=>'b'}, '']]
      data = {}
      data[:a] = 'a'
      data[:b] = [:b]
      h = org.apply(data)
      ok_eq([:p, [:div, {:id=>'a'}, '', 'a'],
		     [:div, {:id=>'b'}, '', [:b]]], h)

      data = {}
      data[:a] = nil
      data[:b] = {:action => 'd.html'}
      h = org.apply(data)
      ok_eq([:p, [:div, {:action=>'d.html', :id=>'b'}, '']], h)

      data = {}
      data[:a] = ['a', [:hr]] # OK.
      data[:b] = nil
      h = org.apply(data)
      ok_eq([:p, [:div, {:id=>'a'}, '', ['a', [:hr]]]], h)

      # test_replace
      h = [:a, [:b], [:c]]
      h2 = h.each_tag {|e| e[0] == :c ? 'text' : e } # insert a text
      ok_eq([:a, [:b], 'text'], h2)
      h2 = h.each_tag(:nosuch) {|e| nil } # no effect
      ok_eq([:a, [:b], [:c]], h2)
      h2 = h.each_tag(:b) {|e| e } # no effect
      ok_eq([:a, [:b], [:c]], h2)
      h2 = h.each_tag(:b) {|e| nil } # delete it
      ok_eq([:a, [:c]], h2)
      h2 = h.each_tag(:b) {|e| 'text' } # insert a text
      ok_eq([:a, 'text', [:c]], h2)
      h2 = h.each_tag(:b) {|e| [:d] } # insert a element
      ok_eq([:a, [:d], [:c]], h2)
      h2 = h.each_tag(:b) {|e| [:d, 'text'] } # insert a element with text
      ok_eq([:a, [:d, 'text'], [:c]], h2)

      h = [:p, [:span, {:id=>'a'}], [:span, {:id=>'b'}]]
      h2 = h.each_tag(:span){|e| e.attr(:id) } # insert the id as text
      ok_eq([:p, 'a', 'b'], h2)
      h2 = h.each_tag(:span){|e| e.attr(:id) == 'b' ? e : nil }
      ok_eq([:p, [:span, {:id=>'b'}]], h2)

      h = [[:h2], [:h3], [:h4], [:h5], [:h6]] 
      h2 = h.each_tag(:h3, :h4) {|e| [e[0], e[0].to_s] } # insert a text
      ok_eq([[:h2], [:h3, 'h3'], [:h4, 'h4'], [:h5], [:h6]], h2)
      h2 = h.each_tag {|e| e[0] == :h5 ? 'text' : e } # insert a text
      ok_eq([[:h2], [:h3], [:h4], 'text', [:h6]], h2)
      h2 = h.each_tag(:h4) {|e| [[:h3, 'h'], [:hr]] } # 
      ok_eq([[:h2], [:h3], [:h3, 'h'], [:hr], [:h5], [:h6]], h2)

      h = [[:span, '']]
      h2 = h.each_tag(:span){|e| [[:h3, 'h'], [:hr]] }
      ok_eq([[:h3, 'h'], [:hr]], h2)
      h2 = h.each_tag(:span){|e|
	[[:h3, 'h3'], [:ul, [:li, [:a, {:href=>'1.html'}, '1']]]]
      }
      ok_eq([[:h3, 'h3'], [:ul, [:li, [:a, {:href=>'1.html'}, '1']]]],
		   h2)

      # test_remove_comment
      ok_eq([:p, 'a', 'c'], [:p, 'a', [:"!--", 'b'], 'c'].remove_comment)
    end
  end
end
