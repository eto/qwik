#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '../../lib' unless $LOAD_PATH.include?('../../lib')
require 'qwik/wabisabi-get'
require 'qwik/wabisabi-traverse'
require 'qwik/wabisabi-parent'

module WabisabiIndexModule
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
#	  elsif 1 < result.length
#	    new_parent += result
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
  require 'qwik/testunit'
  $test = true
end

if defined?($test) && $test
  class TestWabisabiIndex < Test::Unit::TestCase
    def test_all
      h = [:html, [:div, {:class=>'main'},
	  [:div, {:class=>'day'}, [:h2, 'bh2']],
	  [:div, {:class=>'sidebar'}, [:h2, 'sh2', [:b, 'a'], 'sh2a']]]]

      # test_make_index
      h.make_index

      # test_index_tag
      ok_eq([:h2, 'bh2'], h.index_tag(:h2))

      # test_index_class
      ok_eq([:div, {:class=>'sidebar'}, [:h2, 'sh2', [:b, 'a'], 'sh2a']],
	    h.index_class('sidebar'))

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
      ok_eq([[:a, 't']], w)

    end
  end
end
