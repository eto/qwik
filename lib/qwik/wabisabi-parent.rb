#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '../../lib' unless $LOAD_PATH.include?('../../lib')

module WabisabiParentModule
  def set_all_parent
    self.traverse_with_parent {|parent, child|
      child.set_parent(parent)
    }
  end

  def traverse_with_parent(&b)
    self.each {|child|
      next if ! child.is_a?(Array)
      yield(self, child)
      child.traverse_with_parent(&b)	# Recursive.
    }
  end

  def parent
    @parent = nil if ! defined?(@parent)
    return @parent
  end

  def set_parent(parent)
    @parent = parent
  end

end

class Array
  include WabisabiParentModule
end

if $0 == __FILE__
  require 'qwik/testunit'
  $test = true
end

if defined?($test) && $test
  class TestWabisabiParent < Test::Unit::TestCase
    def test_all
      h = [:html,
	[:div, {:class=>'main'},
	  [:div, {:class=>'day'},
	    [:h2, 'bh2']],
	  [:div, {:class=>'sidebar'},
	    [:h2, 'sh2',
	      [:b, 'a'], 'sh2a']]]]

      # test_set_all_parent
      h.set_all_parent

      # test_parent
      ok_eq(nil, h.parent)
      ok_eq(h, h[1].parent)
      ok_eq([:h2, 'sh2', [:b, 'a'], 'sh2a'],
	    h[1][3][2][2].parent)
    end
  end
end
