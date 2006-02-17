#
# Copyright (C) 2003-2006 Kouichirou Eto
# Copyright (C) 2005 Moriyoshi Koizumi
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of
# the GNU General Public License version 2.
#

$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'
require 'qwik/act-text'

module Qwik
  class Action
    D_graphviz = {
      :dt => 'Graphviz plugin',
      :dd => 'You can make a graph.',
      :dc => "* Examples
{{graphviz
digraph G {
  \"A\" ->  B
  \"C\" ->  D
  \"E\" ->  F
}
}}
{{{
{{graphviz
digraph G {
  \"A\" ->  B
  \"C\" ->  D
  \"E\" ->  F
}
}}
}}}

{{graphviz
digraph G {
  node [shape=doublecircle]; Master
  node [shape=circle];
  Master -> Slave_1
  Master -> Slave_2
  Master -> Slave_3
  Master -> Slave_4
}}
{{{
{{graphviz
digraph G {
  node [shape=doublecircle]; Master
  node [shape=circle];
  Master -> Slave 1
  Master -> Slave 2
  Master -> Slave 3
  Master -> Slave 4
}}
}}}

* Configurable paramters
Please specify these parameter in \"etc/config.txt\".

| '''name'''		| '''description'''		| '''example'''
| graphviz_dot_path	| path to 'dot' command		| /usr/bin/dot
| graphviz_font_name	| font name			| IPAUIGothic
| graphviz_font_size	| font size			| 10

* Specifing fonts
You can see the font list of the server by this command.
 % fc-list
The font name is passed as -Nforname= option for dot command.

If you'd like to use Japanese font, please use 'Sazanami font', etc.
 # apt-get install ttf-sazanami-gothic

* Links
- http://www.graphviz.org/
- http://voltex.jp/.test/qwik/1.html
- http://www.voltex.jp/patches/qwik-graphviz-plugin-200512041629.patch.diff

* BUGS
- You can not specify drawing options.
- You can only set two parameters (font name, font size).
- You can not use imagemap for the graph.

* Thanks
The Graphviz plugin is created by Mr. Moriyoshi Koizumi.
Thank you very much.
"
    }

    def plg_graphviz
      #return if @config.test && !(defined?($test_graphviz) && $test_graphviz)
      str = yield.to_s
      str = str.set_page_charset.to_utf8
      f = "graphviz-#{str.md5hex}.png"
      files = @site.files
      if ! files.exist?(f)
	png = Graphviz.generate_png(@config, str)
	return [:div, {:class=>'graphviz'}, ''] if png.nil?
	files.put(f, png)
      end
      return [:div, {:class=>'graphviz'},
	[:img, {:src=>".files/#{f}", :alt=>str}]]
    end
  end

  class Graphviz
    def self.generate_png(config, str)
      cmdpath  = config[:graphviz_dot_path]
      return nil if cmdpath.nil?

      fontname = config[:graphviz_font_name].to_s.gsub(/\$|"|`|\!/, '\\\&')
      fontsize = config[:graphviz_font_size].to_s.gsub(/\$|"|`|\!/, '\\\&')
      out = ''
      cmd = "#{cmdpath} -Tpng -Nfontname=\"#{fontname}\" -Nfontsize=\"#{fontsize}\""
      #p cmd
      IO.popen(cmd, 'r+') {|io|
	io.puts str
	io.close_write
	out = io.read
      }
      return out
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $debug = true
end

if defined?($debug) && $debug
  class TestActGraphviz < Test::Unit::TestCase
    include TestSession

    def test_all
      ok_wi [:div, {:class=>"graphviz"}, [:img,
	  {:src=>".files/graphviz-f27b0e2b9dfab5d00382ed5cdffa9871.png",
	    :alt=>"digraph G {\n  \"A\" ->  B\n}\n"}]],
	"{{graphviz
digraph G {
  \"A\" ->  B
}
}}"
      eq ["graphviz-f27b0e2b9dfab5d00382ed5cdffa9871.png"], @site.files.list
    end
  end
end
