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
require 'qwik/util-css'

module WabisabiValidModule
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

  def check_valid
    self.traverse_element {|e|
      element_name = e[0]
      next unless element_name.is_a?(Symbol)
      unless TAGS.include?(element_name)
	return element_name	# not valid
      end

      attr = e.attr
      next if attr.nil?
      attr.each {|k, v|
	unless ATTR.include?(k)
	  return k		# not valid
	end

	if URL.include?(k)	# this is url
	  vs = v.to_s
	  if /\Ajavascript/i =~ vs
	    return 'script'	# not valid
	  end
	end

	if STYLE.include?(k)	# this is style
	  style = v.to_s
	  unless Qwik::CSS.valid?(style)
	    return 'not valid css'	# not valid
	  end
	end
      }
    }
    return true
  end
end

class Array
  include WabisabiValidModule
end

if $0 == __FILE__
  require 'qwik/testunit'
  $test = true
end

if defined?($test) && $test
  class TestWabisabiValid < Test::Unit::TestCase
    def ok(e, s)
      ok_eq(e, s.check_valid)
    end

    def test_valid
      ok(true, [:p, 't'])
      ok(true, [:ul, 't'])
      ok(:script, [:script, 't'])
      ok(true, [:img, {:src=>'s', :alt=>'a'}, 't'])
      ok(:onload, [:img, {:onload=>'o'}, 't'])
      ok('script', [:img, {:src=>'javascript:do something'}, 't'])
    end
  end
end
