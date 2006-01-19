#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '..' unless $LOAD_PATH.include?('..')
require 'qwik/wabisabi-traverse'

module WabisabiGetModule
  def attr(k=nil)
    attr = self[1]
    return nil if ! attr.is_a?(Hash)
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

  def children
    children = []
    self.each_child {|child|
      children << child
    }
    return children
  end

  def each_child
    self.each {|e|
      next if e.is_a?(Symbol) || e.is_a?(Hash)
      yield(e)
    }
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
  include WabisabiGetModule
end

if $0 == __FILE__
  require 'qwik/testunit'
  $test = true
end

if defined?($test) && $test
  class TestWabisabiGet < Test::Unit::TestCase
    def test_attr
      # test_attr
      h = [:a, {:href=>'t1', :alt=>'t2'}, 't3']
      ok_eq({:href=>'t1', :alt=>'t2'}, h.attr)

      # test_set_attr
      w = [:a]
      ok_eq([:a, {:href=>'u'}], w.set_attr(:href=>'u'))
      ok_eq([:a, {:href=>'u', :class=>'c'}], w.set_attr(:class=>'c'))
    end

    def test_all
      h = [:a, {:href=>'t.html'}, 't', [:b, 'b']]

      # test_element_name
      ok_eq(nil, [].element_name)
      ok_eq(nil, ['t'].element_name)
      ok_eq(:a, [:a, 't'].element_name)
      ok_eq(:a, h.element_name)

      # test_inside
      ok_eq(['t', [:b, 'b']], h.inside)

      # test_children
      ok_eq(['t', [:b, 'b']], h.children)

      # test_each_child
      h.each_child {|e|
	# do nothing
      }

      # test_each_child_with_index
      h.each_child_with_index {|e, i|
	# do nothing
      }

      # test_text
      ok_eq('t', [:a, 't'].text)
      ok_eq('t', [:a, ['t']].text)
      ok_eq('tb', h.text)

      # test_get_single
      ok_eq([:a], [:a].get_single)
      ok_eq([:a], [[:a]].get_single)
      ok_eq([[:a], [:b]], [[:a], [:b]].get_single)
    end
  end
end
