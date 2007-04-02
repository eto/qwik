# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/wabisabi-basic'
require 'qwik/wabisabi-traverse'
require 'qwik/util-css'

module WabisabiValidator
  VALID_TAGS = %w(
div
h2 h3 h4 h5 h6
p blockquote pre
ul ol li
dl dt dd
table tbody tr td 
span
a
em strong del
b i
img
plugin
hr
sup sub
font
)
  TAGS = VALID_TAGS.map {|t| t.intern }

  VALID_ATTR = %w(
href
src alt
method
param
align border hspace vspace
style
color
size
)
  ATTR = VALID_ATTR.map {|t| t.intern }

  URL_ATTR = %w(
href
src
)
  URL = URL_ATTR.map {|t| t.intern }

  STYLE_ATTR = %w(
style
)
  STYLE = STYLE_ATTR.map {|t| t.intern }

  def valid?(w)
    w.traverse_element {|e|
      element_name = e[0]
      next unless element_name.is_a?(Symbol)
      unless TAGS.include?(element_name)
	return element_name	# Invalid
      end

      attr = e.attr
      next if attr.nil?
      attr.each {|k, v|
	unless ATTR.include?(k)
	  return k		# Invalid
	end

	if URL.include?(k)	# k is URL
	  vs = v.to_s
	  if /\Ahttps?:\/\// =~ vs
	    # OK
	  elsif /\A[-\w\.]+\z/ =~ vs
	    # OK
	  else
	    #if /\Ajavascript/i =~ vs
	    return 'Invalid URL'	# Invalid URL
	  end
	end

	if STYLE.include?(k)		# k is style
	  style = v.to_s
	  unless CSS.valid?(style)
	    return 'Invalid CSS'	# Invalid CSS
	  end
	end
      }
    }
    return true
  end

  module_function :valid?
end

if $0 == __FILE__
  require 'test/unit'
  $test = true
end

if defined?($test) && $test
  class TestWabisabiValid < Test::Unit::TestCase
    def ok(e, w)
      assert_equal e, WabisabiValidator.valid?(w)
    end

    def test_valid
      ok true, [:p, 't']
      ok true, [:ul, 't']
      ok :script, [:script, 't']
      ok true, [:img, {:src=>'s', :alt=>'a'}, 't']
      ok :onload, [:img, {:onload=>'o'}, 't']
      ok 'Invalid URL', [:img, {:src=>'javascript:do something'}]
      ok true, [:img, {:src=>'http://example.net/a.jpg'}]
      ok true, [:img, {:src=>'https://example.net/a.jpg'}]
    end
  end
end
