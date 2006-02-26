#
# reference: http://www.maani.us/charts/ PHP/SWF Charts
# charts.php v4.1
# Copyright (c) 2003-2006, maani.us
#

$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'

class Array
  def keys
    ar = []
    (0..(self.length)).each {|i|
      ar << i
    }
    return ar
  end
end

module Qwik
  class Action
    NotUse_D_charts = {
      :dt => 'Charts plugin',
      :dd => 'You can make a chart using charts plugin.',
      :dc => '* Example
 {{chart
 a
 }}
{{chart
a
}}

'
    }

    def plg_chart
      return 'error' if @req.ext != 'html'

      # @chart_num is global for an action.
      @chart_num = 0 if ! defined?(@chart_num)
      @chart_num += 1	# Start from 1
      num = @chart_num

      files = @site.files(@req.base)
      return if files.nil?

      xml = ''
      xml = yield if block_given?
      xmlfilename = "charts#{@chart_num}.html"
      files.put(xmlfilename, xml, true)

      dir = "#{@req.base}.files/"
      flash_file = dir+'charts.swf'
      library_path = dir+'charts_library'
      php_source = dir+xmlfilename
      width = 400
      height = 250
      #bg_color = '666666'
      bg_color = 'eeffbb'

      #transparent = true
      transparent = false
      license = nil
      return chart_generate_wabisabi(flash_file, library_path, php_source,
				     width, height, bg_color, transparent,
				     license)
    end

    def chart_generate_wabisabi(flash_file, library_path, php_source,
				width = 400, height = 250, bg_color = '666666',
				transparent = false, license = nil)
      html = chart_generate_html(flash_file, library_path, php_source,
				 width, height, bg_color, transparent, license)
      return HTree(html).to_wabisabi
    end

    def chart_generate_html(flash_file, library_path, php_source,
			    width = 400, height = 250, bg_color = '666666',
			    transparent = false, license = nil)
      php_source = php_source.escape
      library_path = library_path.escape
      html = ''
      html << "<object classid='clsid:D27CDB6E-AE6D-11cf-96B8-444553540000' codebase='http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=6,0,0,0' "
      html << "width=#{width} height=#{height} id='charts' align=''>"
      html << "<param name=movie value='#{flash_file}?library_path=#{library_path}&php_source=#{php_source}"
      html << "&license=#{license}" if license
      html << "'><param name=quality value=high><param name=bgcolor value=#" + bg_color + ">"
      html << "<param name=wmode value=transparent>" if transparent
      html << "<embed src='#{flash_file}?library_path=#{library_path}&php_source=#{php_source}"
      html << "&license=#{license}" if license
      html << "' quality=high bgcolor=#" + bg_color +
	" width=#{width} height=#{height} name='charts' align='' "
      html << "wmode=transparent " if transparent
      html << "type='application/x-shockwave-flash' pluginspage='http://www.macromedia.com/go/getflashplayer'></embed></object>"
      return html
    end

    def charts_generate_xml(chart = {})
      xml = "<chart>\n"
      chart.each {|k1, c1|
	if ! (c1.is_a?(Array) || c1.is_a?(Hash))
	  # test_case1: chart type, etc.
	  xml << "  <#{k1}>#{c1}</#{k1}>\n"
	  next
	end

	c1keys = c1.keys
	c1first = c1[c1keys[0]]
	if ! (c1first.is_a?(Array) || c1first.is_a?(Hash))
	  # test_case2: chart type, etc.
	  if (k1 == 'chart_type' or
	      k1 == 'series_color' or
	      k1 == 'series_image' or
	      k1 == 'series_explode' or
	      k1 == 'axis_value_text')
	    xml << "  <"+k1+">\n"
	    xml << c1.map {|c2|
	      c2.nil? ? "    <null/>\n" : "    <value>#{c2}</value>\n"
	    }.join
	    xml << "  </#{k1}>\n"
	    next
	  end

	  # test_case3: axis_category, etc.
	  xml << "  <#{k1}"
	  xml << c1.map {|k2, c2| " #{k2}='#{c2}'" }.join
	  xml << " />\n"
	  next
	end

	xml << "  <#{k1}>\n"
	c1.each_with_index {|c2, k2|

	  c2keys = c2.keys
	  case k1
	  when 'chart_data'
	    # test_case4: chart_data
	    xml << "    <row>\n"
	    xml << c2.map {|c3|
	      c3.nil? ? "      <null/>\n" :
		c3.is_a?(Numeric) ? "      <number>#{c3}</number>\n" :
		"      <string>#{c3}</string>\n"
	    }.join
	    xml << "    </row>\n"

	  when 'chart_value_text'
	    # test_case5: chart_value_text
	    xml << "    <row>\n"
	    xml << c2.map {|c3|
	      c3.nil? ? "      <null/>\n" : "      <string>#{c3}</string>\n"
	    }.join
	    xml << "    </row>\n"

	  when 'draw'
	    # test_case6: draw
	    xml << "    <#{c2['type']}"
	    text = ''
	    c2.each {|k3, c3|
	      next if k3 == 'type'
	      if k3 == 'text'
		text = c3
		next
	      end
	      xml << " #{k3}='#{c3}'"
	    }
	    if ! text.empty?
	      xml << ">#{text}</text>\n"
	    else
	      xml << " />\n"
	    end

	  else
	    # test_case7: 
	    xml << "    <value"
	    xml << c2.map {|k3, c3|
	      " #{k3}='#{c3}'"
	    }.join
	    xml << " />\n"
	  end
	}
	xml << "  </#{k1}>\n"
      }
      xml << "</chart>\n"

      return xml
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActCharts < Test::Unit::TestCase
    include TestSession

    def test_chart_generate
      res = session
      embed = @action.chart_generate_wabisabi('flash_file', 'library_path', 'php_source')
      e = [[:object,
	  {:id=>'charts',
	    :classid=>'clsid:D27CDB6E-AE6D-11cf-96B8-444553540000',
	    :codebase=>"http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=6,0,0,0",
	    :align=>'',
	    :width=>'400',
	    :height=>'250'},
	  [:param,
	    {:value=>"flash_file?library_path=library_path&php_source=php_source",
	      :name=>'movie'}],
	  [:param, {:value=>'high', :name=>'quality'}],
	  [:param, {:value=>"#666666", :name=>'bgcolor'}],
	  [:embed,
	    {:pluginspage=>'http://www.macromedia.com/go/getflashplayer',
	      :type=>'application/x-shockwave-flash',
	      :src=>"flash_file?library_path=library_path&php_source=php_source",
	      :align=>'',
	      :name=>'charts',
	      :width=>'400',
	      :quality=>'high',
	      :height=>'250',
	      :bgcolor=>"#666666"}]]]
      ok_eq(e, embed)
    end

    def ok_gen(e, s)
      ok_eq(e, @action.charts_generate_xml(s))
    end

    def test_charts_generate_xml
      res = session

      # test_case1: chart type, etc.
      ok_gen("<chart>\n</chart>\n", {})
      ok_gen("<chart>\n  <k>v</k>\n</chart>\n", {'k'=>'v'})

      # test_case2: chart type, etc.
      ok_gen("<chart>\n  <chart_type>\n  </chart_type>\n</chart>\n",
	     {'chart_type'=>[]})
      ok_gen("<chart>\n  <chart_type>\n    <null/>\n  </chart_type>\n</chart>\n", {"chart_type"=>[nil]})
      ok_gen("<chart>\n  <chart_type>\n    <value>a</value>\n  </chart_type>\n</chart>\n", {"chart_type"=>['a']})

      # test_case3: axis_category, etc.
      ok_gen("<chart>\n  <axis_category k='v' />\n</chart>\n",
	     {'axis_category'=>{'k'=>'v'}})

      # test_case4: chart_data
      ok_gen("<chart>\n  <chart_data>\n    <row>\n    </row>\n  </chart_data>\n</chart>\n",
	     {'chart_data'=> [ [] ] })
      ok_gen("<chart>\n  <chart_data>\n    <row>\n      <null/>\n    </row>\n  </chart_data>\n</chart>\n",
	     {'chart_data'=> [ [nil] ] })
      ok_gen("<chart>\n  <chart_data>\n    <row>\n      <string>a</string>\n    </row>\n  </chart_data>\n</chart>\n",
	     {'chart_data'=> [ ['a'] ] })
      ok_gen("<chart>\n  <chart_data>\n    <row>\n      <number>0</number>\n    </row>\n  </chart_data>\n</chart>\n",
	     {'chart_data'=> [ [0] ] })

      # test_case5: chart_value_text
      ok_gen("<chart>\n  <chart_value_text>\n    <row>\n      <null/>\n    </row>\n  </chart_value_text>\n</chart>\n",
	     {'chart_value_text'=> [ [nil] ] })
      ok_gen("<chart>\n  <chart_value_text>\n    <row>\n      <string>a</string>\n    </row>\n  </chart_value_text>\n</chart>\n",
	     {'chart_value_text'=> [ ['a'] ] })

      # test_case6: draw
      ok_gen("<chart>\n  <draw>\n    <v />\n  </draw>\n</chart>\n",
	     {'draw'=> [ {'type'=>'v'} ] })
      ok_gen("<chart>\n  <draw>\n    <t k='v' />\n  </draw>\n</chart>\n",
	     {'draw'=> [ {'type'=>'t', 'k'=>'v'} ] })
      ok_gen("<chart>\n  <draw>\n    <text k='v'>te</text>\n  </draw>\n</chart>\n",
	     {'draw'=> [ {'type'=>'text', 'k'=>'v', 'text'=>'te'} ] })

      # test_case7: 
      ok_gen("<chart>\n  <a>\n    <value k='v' />\n  </a>\n</chart>\n",
	     {'a'=> [ {'k'=>'v'} ] })
    end
  end
end

__END__
* Charts
* Charts
This is a test for generating charts.
