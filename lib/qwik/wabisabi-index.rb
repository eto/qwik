# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/wabisabi-basic'
require 'qwik/wabisabi-traverse'

module WabisabiIndexModule
  def set_parent(parent)
    @parent = parent
    return nil
  end

  def parent
    @parent = nil if ! defined?(@parent)
    return @parent
  end

  def traverse_with_parent(&b)
    self.each {|child|
      next if ! child.is_a?(Array)
      yield(self, child)
      child.traverse_with_parent(&b)	# Recursive.
    }
  end

  def set_all_parent
    self.traverse_with_parent {|parent, child|
      child.set_parent(parent)
    }
  end

  def make_index
    @tags  = Hash.new {|h, k| h[k] = [] }
    @klass = Hash.new {|h, k| h[k] = [] }

    self.traverse_element {|e|
      classname = e.attr(:class)
      if classname
	@klass[classname] << e
      end

      name = e.element_name
      @tags[name] << e
    }

    self.set_all_parent
  end

  def index_tag(element_name)
    return @tags[element_name][0]
  end

  def index_class(classname)
    return @klass[classname][0]
  end

  # Use parent.
  def index_each_tag(element_name)
    if ! defined?(@tags)
      self.make_index
    end

    tags = @tags[element_name]
    return if tags.nil?
    tags.each {|e|
      result = yield(e)

      parent = e.parent
      new_parent = []
      parent.each_with_index {|child, i|
	if child.object_id == e.object_id
	  if result.nil?
	    # do nothing.
	  else
	    new_parent << result
	  end
	else
	  new_parent << child
	end
      }

      parent.replace(new_parent)
    }
    return nil
  end
end

class Array
  include WabisabiIndexModule
end

if $0 == __FILE__
  require 'test/unit'
  $test = true
end

if defined?($test) && $test
  class TestWabisabiIndex < Test::Unit::TestCase
    def test_parent
      child = [:child]
      parent = [:parent, child]

      # test_parent
      assert_equal nil, child.parent

      # test_set_parent
      child.set_parent(parent)
      assert_equal [:parent, [:child]], child.parent

      # test_traverse_with_parent
      parent.traverse_with_parent {|p, c|
	assert_equal [:parent, [:child]], p
	assert_equal [:child], c
      }

      # test_set_all_parent
      parent.set_all_parent
      assert_equal [:parent, [:child]], child.parent
    end

    def test_parent_real
      w = [:html,
	[:div, {:class=>'main'},
	  [:div, {:class=>'day'},
	    [:h2, 'bh2']],
	  [:div, {:class=>'sidebar'},
	    [:h2, 'sh2',
	      [:b, 'a'], 'sh2a']]]]

      # test_set_all_parent
      w.set_all_parent

      # test_parent
      ok_eq(nil, w.parent)
      ok_eq(w, w[1].parent)
      ok_eq([:h2, 'sh2', [:b, 'a'], 'sh2a'],
	    w[1][3][2][2].parent)
    end

    def test_all
      w = [:html, [:div, {:class=>'main'},
	  [:div, {:class=>'day'}, [:h2, 'bh2']],
	  [:div, {:class=>'sidebar'}, [:h2, 'sh2', [:b, 'a'], 'sh2a']]]]

      # test_make_index
      w.make_index

      # test_index_tag
      assert_equal [:h2, 'bh2'], w.index_tag(:h2)

      # test_index_class
      assert_equal [:div, {:class=>'sidebar'}, [:h2, 'sh2', [:b, 'a'], 'sh2a']],
	    w.index_class('sidebar')

      # test_index_each_tag
      w = [:p, '']
      w.make_index
      nw = w.index_each_tag(:a) {|ww|
	[ww]
      }

      w = [[:a, '']]
      w.make_index
      w.index_each_tag(:a) {|ww|
	www = ww.dup
	www[-1] = 't'
	www
      }
      assert_equal [[:a, 't']], w
    end
  end
end
