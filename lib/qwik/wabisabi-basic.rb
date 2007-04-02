# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module WabisabiBasicModule
  def attr(k=nil)
    attr = self[1]
    return nil unless attr.is_a?(Hash)
    return attr[k] if k
    return attr
  end

  def set_attr(new_attr)
    attr = self.attr
    if attr
      attr.update(new_attr)
    else
      self.insert(1, new_attr)
    end
    return self		# For chain method.
  end

  def element_name
    return self[0] if self[0].is_a?(Symbol)
    return nil
  end

  def inside
    self.reject {|x| x.is_a?(Symbol) || x.is_a?(Hash) }
  end

  def each_child
    self.each {|e|
      next if e.is_a?(Symbol) || e.is_a?(Hash)
      yield(e)
    }
  end

  def children
    children = []
    self.each_child {|child|
      children << child
    }
    return children
  end

  def each_child_with_index
    i = 0
    self.each_child {|e|
      yield(e, i)
      i += 1
    }
  end

  def text
    i = 0
    while true
      x = self[i]
      if x.is_a?(Symbol) || x.is_a?(Hash)
	i += 1
	next
      else
	break
      end
    end

    (i...self.length).map {|i|
      x = self[i]
      if x.is_a?(String)
	x
      elsif x.is_a?(Array)
	if x[0] != :"!--"
	  x.text
	end
      else
	nil
      end
    }.join
  end

  def get_single
    if self.length == 1 && self.first.is_a?(Array)
      return self.first.get_single
    end
    return self
  end

  def each_element(elementname)
    self.each {|e|
      if e.is_a?(Array) && e[0] == elementname
	yield(e)
      end
    }
  end
end

class Array
  include WabisabiBasicModule
end

if $0 == __FILE__
  require 'test/unit'
  $test = true
end

if defined?($test) && $test
  class TestWabisabiBasic < Test::Unit::TestCase
    def test_all
      # test_attr
      w = [:a, {:href=>'t1', :class=>'t2'}, 't3']
      assert_equal({:href=>'t1', :class=>'t2'}, w.attr)

      # test_set_attr
      w = [:a]
      assert_equal [:a, {:href=>'u'}], w.set_attr(:href=>'u')
      assert_equal [:a, {:href=>'u', :class=>'c'}], w.set_attr(:class=>'c')

      w = [:a, {:href=>'t.html'}, 't', [:b, 'b']]

      # test_element_name
      assert_equal nil, [].element_name
      assert_equal nil, ['t'].element_name
      assert_equal :b, [:b, 't'].element_name
      assert_equal :a, w.element_name

      # test_inside
      assert_equal ['t', [:b, 'b']], w.inside

      # test_each_child
      w.each_child {|e|
	assert(e == "t" || e == [:b, "b"])
      }

      # test_children
      assert_equal ['t', [:b, 'b']], w.children

      # test_each_child_with_index
      w.each_child_with_index {|e, i|
	case i
	when 0; assert_equal "t", e
	when 1; assert_equal [:b, "b"], e
	end
      }

      # test_text
      assert_equal 't', [:a, 't'].text
      assert_equal 't', [:a, ['t']].text
      assert_equal 'tb', w.text

      # test_get_single
      assert_equal [:a], [:a].get_single
      assert_equal [:a], [[:a]].get_single
      assert_equal [[:a], [:b]], [[:a], [:b]].get_single

      # test_each_element
      w.each_element(:b) {|e|
	assert_equal [:b, "b"], e
      }
    end
  end
end
