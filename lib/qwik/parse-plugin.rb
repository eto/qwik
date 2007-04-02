# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/parser'

module Qwik
  class Plugin
    # Split a string into paragraphs.
    def self.split(str)
      paras = []

      cur_str = nil
      in_plugin = false
      str.each_line {|line|
	if ! in_plugin
	  if /\A\{\{/ =~ line
	    paras << cur_str if cur_str
	    cur_str = line
	    in_plugin = true
	    if /\}\}$/ =~ line		# Use $ for new line.
	      paras << cur_str
	      cur_str = nil
	      in_plugin = false
	    end
	  else
	    cur_str = '' if cur_str.nil?
	    cur_str += line
	  end
	else
	  if /\A\}\}$/ =~ line
	    cur_str += line
	    paras << cur_str
	    cur_str = nil
	    in_plugin = nil
	  else
	    cur_str += line
	  end
	end
      }

      if cur_str
	paras << cur_str
      end

      return paras
    end

    def self.rewrite(paras, pluginname, num)
      cur_num = 1
      nparas = []
      paras.each {|para|
	if /\A\{\{(\w+)/ =~ para && (name = $1.intern) == pluginname
	  if cur_num == num
	    tokens = TextTokenizer.tokenize(para)
	    tree = TextParser.make_tree(tokens)
	    raise if 1 < tree.length
	    plugin = tree[0]
	    raise if plugin[0] != :plugin
	    new_plugin = yield(plugin)
	    new_para = encode(new_plugin)
	    nparas << new_para
	  else
	    nparas << para
	  end
	  cur_num += 1
	else
	  nparas << para
	end
      }
      return nparas
    end

    def self.encode(plugin)
      method = plugin[1][:method]
      param = plugin[1][:param]
      content = plugin[2]
      str = "{{#{method}"
      str << "(#{param})" if param && ! param.empty?
      if content
	content.chomp!
	str << "
#{content}
"
      end
      str << "}}
"
      return str
    end

    def self.join(paras)
      str = paras.join
      return str
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestPlugin < Test::Unit::TestCase
    include TestSession

    def ok_sp(e, s)
      ok_eq(e, Qwik::Plugin.split(s))
    end

    def test_plugin_split
      ok_sp([], '')
      ok_sp(['a'], 'a')
      ok_sp(['a
b'], 'a
b')
      ok_sp(['{{p}}'], '{{p}}')
      ok_sp(['a
', '{{p}}'], 'a
{{p}}')
      ok_sp(['a
', '{{p}}
', 'b'], 'a
{{p}}
b')
      ok_sp(['a
', '{{p
}}
', 'b'], 'a
{{p
}}
b')
    end

    def ok_re(expected, paras, num)
      nparas = Qwik::Plugin.rewrite(paras, :p, num) {|plugin|
	plugin << 'c'
	plugin
      }
      ok_eq(expected, nparas)
    end

    def test_plugin_rewrite
      ok_re(["{{p
c
}}
"],
	    ['{{p}}'], 1)
      ok_re(['{{p}}'], ['{{p}}'], 2)
      ok_re(["a
", "{{p
c
}}
", "b
"],
	    ["a
", "{{p}}
", "b
"], 1)
      ok_re(["a
", "{{p
c
}}
", "{{p}}
", "b
"],
	    ["a
", "{{p}}
", "{{p}}
", "b
"], 1)
      ok_re(["{{p}}
", "{{p
c
}}
"],
	    ["{{p}}
", '{{p}}'], 2)
      ok_re(["{{p
c
}}
", '{{q}}'],
	    ["{{p}}
", '{{q}}'], 1)
      ok_re(["{{p}}
", '{{q}}'],
	    ["{{p}}
", '{{q}}'], 2)
    end

    def ok_en(e, s)
      ok_eq(e, Qwik::Plugin.encode(s))
    end

    def test_plugin_encode
      ok_en("{{m}}
", [:plugin, {:method=>'m'}])
      ok_en("{{m}}
", [:plugin, {:method=>'m', :param=>''}])
      ok_en("{{m(p)}}
", [:plugin, {:method=>'m', :param=>'p'}])
      ok_en("{{m(p)

}}
", [:plugin, {:method=>'m', :param=>'p'}, ''])
      ok_en("{{m
c
}}
", [:plugin, {:method=>'m'}, 'c'])
      ok_en("{{m
c
}}
", [:plugin, {:method=>'m'}, "c
"])
      ok_en("{{m
c

}}
", [:plugin, {:method=>'m'}, "c

"])
      ok_en("{{m(p)
c
}}
", [:plugin, {:method=>'m', :param=>'p'}, 'c'])
      ok_en("{{m(p)
c
}}
", [:plugin, {:method=>'m', :param=>'p'}, "c
"])
    end

    def test_plugin_join
      ok_eq("a
{{p
c
}}
b
",
	    Qwik::Plugin.join(["a
", "{{p
c
}}
", "b
"]))
    end
  end
end
