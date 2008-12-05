# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    D_PluginMap = {
      :dt => 'Map plugin',
      :dd => 'You can embed a map and create makers.',
      :dc => "* Example
{{{
{{map(139.7005, 35.6595, 3)
* [139.7005,35.6595] Shibuya
- Hachiko Mae
* [139.7030,35.6715] Harajuku
- Takeshita St.
}}
}}}
See [[PluginMap]] for example.
* Thanks
I use '[[Google Local|http://maps.google.com/]]' for the map.
Thank you very much.
"
    }

    def plg_map(clat, clng, mag=0)
      # Prepare maplink div.

      href = ".map?s=#{@req.sitename}&k=#{@req.base}"
      fullhref = "#{href}&m=full"

      #href = c_relative_to_root(href)
      #fullhref = c_relative_to_root(fullhref)
      href = "/#{href}"
      fullhref = "/#{fullhref}"

      div = [:div, {:class=>'maplink'},
	[:iframe, {:src=>href,
	    :style=>'width:700px;height:400px;border:0;'}, ''],
	[:br],
	[:div, {:style=>'margin: 0 0 1em 0;'},
	  [:a, {:href=>fullhref, :style=>'font-size:x-small;'},
	    _('Show map in full screen.')]]]
      content = yield
      elements = c_res(content)
      div += elements
      return div
    end

    def pre_act_map
      sitename = @req.query['s']
      pagekey  = @req.query['k']
      mode     = @req.query['m']

      # Prepare site.
      @site = @memory.farm.get_site(sitename)
      if @site.nil?
	@site = @memory.farm.get_top_site
	return action_no_such_site(@req.sitename)
      end
      if ! @site.is_open?
        c_require_member	# IMPORTANT: Security check.
      end

      page = @site[pagekey]
      c_nerror('No such page.') if page.nil?
      plugin = get_first_plugin(page, 'map')

      param = plugin[1][:param]
      args = Action.plugin_parse_args(param)
      clat = args.shift.to_f
      clng = args.shift.to_f
      mag = args.shift.to_i

      content = plugin[2]

      ar = []
      ar << map_style
      maparea = map_maparea(clat, clng, mag, content, mode)
      ar << maparea

      title = 'map'
      c_plain(title){ar}

      head = @res.body.get_path('/head')
      head << map_initial_script
      head << map_script(clat, clng, mag, content, mode)

      body = @res.body.get_path('/body')
      body[1][:onload] = 'qwikMakeMap();'

      footer= @res.body.get_path("//div[@class='footer']")
      footer.clear

      if ! @config.test
	map_make_page_utf8
      end
    end

    def map_make_page_utf8
      @res.body = @res.body.format_xml.page_to_xml
      @res['Content-Type'] = "text/html; charset=#{Charset::UTF8}"
    end

    def get_first_plugin(page, method)
      str = page.load
      elements = c_parse(str)
      elements.each {|element|
	if element[0] == :plugin && element[1][:method] == method
	  return element
	end
      }
      return nil
    end

    GOOGLE_MAPS_API_KEY_FILE = 'google-maps-api-key.txt'

    def map_get_api_key
      file = @config.etc_dir.path+GOOGLE_MAPS_API_KEY_FILE
      return if ! file.exist?
      return file.open {|f| f.gets }.chomp
    end

    def map_style
      return [:style, '.header { display: none ! important; }
body { background: #fff; }']
    end

    def map_initial_script
      key = map_get_api_key
      #return if key.nil?	# Fatal error.
      key ||= ''	# Ad hoc.
      src = "http://maps.google.com/maps?file=api&v=1&key=#{key}"
      return [:script, {:src=>src, :type=>'text/javascript'}, '']
    end

    def map_script(clat, clng, mag, content, mode='iframe')
      maparea = []

      # Prepare markers.
      elements = c_parse(content)

      markers = []
      marker = nil

      elements.each {|element|
	if element[0] == :h2
	  marker = []
	  markers << marker
	  marker << element
	else
	  if marker
	    marker << element
	  end
	end
      }

      ms = []
      markers.each {|marker|
	h2 = marker[0]
        if h2[1] == '[' && h2[3] == ']'
	  lat, lng = h2[2].split(',')
          h2[1] = ''	# Destruct headers.
          h2[2] = ''
          h2[3] = ''
	  ms << [lat, lng, marker]
        end
      }

      marker_script = ''
      ms.each {|lat, lng, marker|
	s = marker.rb_format_xml(-1, -1)
        s = s.sub(/\n/, '')
	marker_script << "qwikSetMark(#{lat}, #{lng}, '#{s}');\n"
      }

      # Add script.
      clat = clat.to_f
      clng = clng.to_f
      mag = mag.to_i
      # You should set width for div element in the marker.
      script = "
function qwikMakeMap() {
  if (GBrowserIsCompatible()) {
    // Define the function inside.
    function qwikSetMark(lat, lng, body) {
      var point = new GPoint(lng, lat);
      var html=\"<div style='width:220px'>\"+body+\"</div>\";
      var marker = new GMarker(point);
      map.addOverlay(marker);
      GEvent.addListener(marker, 'click', function() {
        marker.openInfoWindowHtml(html);
      });
      marker.openInfoWindowHtml(html);
    }

    var map = new GMap(document.getElementById('map'));
    map.addControl(new GLargeMapControl());
    map.addControl(new GMapTypeControl());
    map.centerAndZoom(new GPoint(#{clng}, #{clat}), #{mag});
    GEvent.addListener(map, 'moveend', function() {
      var center = map.getCenterLatLng();
      var latLngStr = '* [' + center.y + ',' + center.x + '] ';
      document.getElementById('message').innerHTML = latLngStr;
    });

    #{marker_script}
  }
}
"
      maparea << [:script, {:type=>'text/javascript'},
                 "\n//",
                 [:'![CDATA[', "\n\n"+script+"\n//"],
                 "\n"]
      return maparea
    end

    def map_maparea(clat, clng, mag, content, mode='iframe')
      maparea = [:div, {:class=>'maparea'}]

      # Add initial script.
      #maparea << map_initial_script

      # Add <div id='map'></div>
      style = 'width: 696px; height: 382px;'
      style = 'width: 100%; height: 600px;' if mode == 'full'
      maparea << [:div, {:id=>'map', :style=>style}, '']
      maparea << [:div, {:id=>'message', :style=>'font-size:x-small;'}, '']
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  require 'qwik/wabisabi-format-xml'
  $test = true
end

if defined?($test) && $test
  class TestActMap < Test::Unit::TestCase
    include TestSession

    TEST_MAP_CONTENT = '
{{map(139.7005, 35.6595, 3)
* [139.7005,35.6595] Shibuya
- Hachiko Mae
* [139.7030,35.6715] Harajuku
- Takeshita St.
}}
'

    def test_all
      t_add_user

      page = @site.create_new
      str = TEST_MAP_CONTENT
      page.store(str)
      res = session '/test/1.html'

      ok_title '1'
      w = res.body.get_path("//div[@class='maplink']")
      eq [:div, {:class=>'maplink'},
	[:iframe, {:src=>'/.map?s=test&k=1',
	    :style=>'width:700px;height:400px;border:0;'}, '']],
	w[0..2]

      res = session '/.map?s=test&k=1'
      ok_title 'map'
      w = res.body.get_path("//div[@class='maparea']")
    end

    def nutest_map
      str = '
{{map(1, 2, 3, 400, 300)
* StoreA
,4,5
- List1
- http://example.com/StoreA
> CommentA
* StoreB
,6,7
{{file(StoreB.jpg)}}
- List2
- http://example.com/StoreB
> CommentB
}}
'
    end
  end
end
