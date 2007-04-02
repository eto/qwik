# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/wabisabi-basic'

module WabisabiTraverseModule
  def traverse_element(*tags, &b)
    if tags.length == 0 || (self[0].is_a?(Symbol) && tags.include?(self[0]))
      yield(self)
    end

    self.each {|s|
      next unless s.is_a?(Array)
      s.traverse_element(*tags, &b)	# Recursive.
    }
  end

  def get_tag(tag)
    tag = tag.to_s
    tag, num = split_name_num(tag)
    find_nth_element(num, tag.intern)
  end

  def get_by_class(klass)
    get_has_attr(:class, klass)
  end

  def get_path(path)
    xml = self
    path.split('/').each {|pa|
      next unless 0 < pa.length
      return nil if xml.nil?
      xml = xml.get_a_path(pa)
    }
    xml
  end

  def get_a_path(path)
    if /\A(.*)\[(.+)\]\z/ =~ path
      tag = $1
      select = $2
      attr, value = parse_attr_selector(select)
      if attr
	return get_has_attr(attr, value)
      end
    end
    return get_tag(path)
  end

  private

  def parse_attr_selector(attr_selector)
    unless attr_selector.include?("=")
      return nil
    end

    left, right = attr_selector.split("=", 2)

    if /\A@([a-z:]+)\z/ =~ left
      attr_name = $1.intern
    else
      raise 'unknown attribute selector '+left
    end

    # FIXME: It's not right to this twice.
    right = $1 if /\A'(.+)'\z/ =~ right
    right = $1 if /\A"(.+)"\z/ =~ right

    if /\A(.*)\z/ =~ right
      value = $1
    else
      raise 'unknown attribute value '+right
    end

    return [attr_name, value]
  end

  def get_has_attr(attr, value)
    each_has_attr(attr, value) {|l|
      return l
    }
    return nil
  end

  def each_has_attr(key, value)
    traverse_element {|e|
      attr = e.attr
      if attr && attr[key] == value
	yield(e)
      end
    }
  end

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
end

class Array
  include WabisabiTraverseModule
end

if $0 == __FILE__
  require 'test/unit'
  $test = true
end

if defined?($test) && $test
  require 'qwik/test-module-public'

  class TestWabisabiTraverse < Test::Unit::TestCase
    include TestModulePublic

    def test_all
      # test_get_path
      h = [:html, [:div, {:class=>'main'},
	  [:div, {:class=>'day'}, [:h2, 'bh2']],
	  [:div, {:class=>'sidebar'}, [:h2, 'sh2', [:b, 'a'], 'sh2a']]]]
      t_make_public(Array, :get_has_attr)
      assert_equal [:div, {:class=>'sidebar'}, [:h2, 'sh2', [:b, 'a'], 'sh2a']],
	h.get_has_attr(:class, 'sidebar')
      assert_equal [:div, {:class=>'sidebar'}, [:h2, 'sh2', [:b, 'a'], 'sh2a']],
	h.get_path("//div[@class='sidebar']")
      assert_equal [:b, 'a'], h.get_path("//div[@class='sidebar']/b")
      assert_equal [:div, {:class=>'sidebar'}, [:h2, 'sh2', [:b, 'a'], 'sh2a']],
	h.get_a_path("div[@class='sidebar']")
      assert_equal [:b, 'a'],
	h.get_a_path("div[@class='sidebar']").get_a_path('b')

      # test_get_tag1
      h = [:a, {:href=>'t1', :alt=>'t2'}, 't3']
      e = h.get_tag('a')
      assert_equal [:a, {:href=>'t1', :alt=>'t2'}, 't3'], e

      # test_get_tag2
      h = [:a, [:b, [:c]]]
      assert_equal [:c], h.get_tag('c')
      assert_equal [:b, [:c]], h.get_tag('b')

      # test_get_tag3
      h = [:a, [:b, 'tb'], [:b, 'tb2'], [:c]]
      assert_equal [:b, 'tb'], h.get_tag('b')
      assert_equal nil, h.get_tag('nosuchtag')
      assert_equal [:b, 'tb'], h.get_tag('b[1]')
      assert_equal [:b, 'tb2'], h.get_tag('b[2]')
      assert_equal [:b, 'tb'], h.get_tag('//b')

      # test_get_path_with_space
      h = [:html, [:div, {:class=>'main'},
	  [:div, {:class=>'day edit'}, [:h2, 'bh2']],
	  [:div, {:class=>'sidebar'}, [:h2, 'sh2', [:b, 'a'], 'sh2a']]]]
      assert_equal [:div, {:class=>'sidebar'}, [:h2, 'sh2', [:b, 'a'], 'sh2a']],
	h.get_path("//div[@class='sidebar']")
      assert_equal [:div, {:class=>'day edit'}, [:h2, 'bh2']],
	h.get_path("//div[@class='day edit']")

      # test_get_has_attr
      h = [:html,
	[:div, {:class=>'main'},
	  [:div, {:id=>'menu'},
	    [:h2, 'menuh2']]]]
      assert_equal [:div, {:id=>'menu'}, [:h2, 'menuh2']],
	h.get_has_attr(:id, 'menu')
      assert_equal [:div, {:id=>'menu'}, [:h2, 'menuh2']],
	h.get_path("//div[@id='menu']")
    end


    def test_private
      e = []

      # test_parse_attr_selector
      t_make_public(Array, :parse_attr_selector)
     #assert_raise(RuntimeError){ e.parse_attr_selector('a') }
      assert_raise(RuntimeError){ e.parse_attr_selector('a=b') }
      assert_equal [:a, 'b'], e.parse_attr_selector('@a=b')
      assert_equal [:a, 'b c'], e.parse_attr_selector("@a='b c'")

      # test_get_has_attr

      # test_each_has_attr

      # test_split_name_num
      t_make_public(Array, :split_name_num)
      assert_equal ['sidebar', 1], e.split_name_num('sidebar')
      assert_equal ['sidebar', 1], e.split_name_num('sidebar[1]')
      assert_equal ['sidebar', 2], e.split_name_num('sidebar[2]')

      # test_find_nth_element
    end
  end
end
