#
# Copyright (C) 2003-2005 Kouichirou Eto
# Copyright (C) 2005 Moriyoshi Koizumi
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of
# the GNU General Public License version 2.
#

$LOAD_PATH << '..' unless $LOAD_PATH.include?('..')
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

    def plg_graphviz(str=nil)
      y = yield if block_given?
      str = y.chomp if y && y != ''

      if str.nil?
	str = @site.site_url
	n = @site.sitename
      else
	str = str.to_s
	hash_str = str.dup
 	hash_str << @config.graphviz_font_name if @config.respond_to?('graphviz_font_name')
	hash_str << @config.graphviz_font_size if @config.respond_to?('graphviz_font_size')
	n = hash_str.md5hex
      end

      f = 'graphviz-'+n+'.png'
      files = @site.files('FrontPage')
      if ! files.exist?(f)
	res = graphviz_generate(f, str)
	return res if res
      end

      ar = [:img, {:src=>'.files/'+f, :alt=>str}]
      h = ar
      h = [:a, {:href=>str}, ar] if is_valid_url?(str)
      div = [:div, {:class=>'graphviz'}, h]
      return div
    end

    def graphviz_generate(f, str)
      return if @config.test && !(defined?($test_graphviz) && $test_graphviz)

      gv = @memory.graphviz

      #str = str.set_sjis_charset.to_utf8_charset
      str = str.sjistou8

      begin
	png = gv.generate_png(str)
	return [:div, {:class=>'graphviz'}, ''] if png.nil?
      rescue
	return [:div, {:class=>'graphviz'}, '']
      end

      files = @site.files('FrontPage')
      files.put(f, png)

      return nil 
    end
  end

  class Graphviz
    def initialize(bin_path)
      @bin_path = bin_path
      @cmdline = ''
    end

    def font_name=(val)
      @cmdline << ' -Nfontname="' << val.gsub(/\$|"|`|\!/, '\\\&') << '"'
    end

    def font_size=(val)
      @cmdline << ' -Nfontsize="' << val.gsub(/\$|"|`|\!/, '\\\&') << '"'
    end

    def generate_png(str)
      out=''
      p @cmdline
      IO.popen(@bin_path + ' -Tpng ' + @cmdline, 'r+') { |io|
	io.puts str
	io.close_write
	out = io.read
      }
      return out
    end
  end

  class GraphvizMemory
    def initialize(config, memory)
      @config = config
      @memory = memory
      @graphviz = Graphviz.new(@config.graphviz_dot_path)
      @graphviz.font_name = @config.graphviz_font_name if @config.respond_to?('graphviz_font_name')
      @graphviz.font_size = @config.graphviz_font_size if @config.respond_to?('graphviz_font_size')
    end

    def generate_png(d)
      begin 
	return @graphviz.generate_png(d)
      rescue
	return ''
      end
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
      ok_wi([:div, {:class=>"graphviz"},
 [:img, {:src=>".files/graphviz-3c7bc23c6e7fc2e92cb971e53a18a842.png",
   :alt=>"digraph G {\n  \"A\" ->  B\n}"}]],
"{{graphviz
digraph G {
  \"A\" ->  B
}
}}")
    end
  end
end
