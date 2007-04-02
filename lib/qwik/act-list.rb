# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    NotYet_D_PluginListEdit = {
      :dt => 'List editing plugin',
      :dd => 'You can edit a list in the page.',
      :dc => "* Example
{{list
- A
- B
- C
}}
You can see a list with three lines.

- By clicking the item, you can edit the item.
- You can drag-and-drop the list.
The system automatically save your editing by Ajax method.
"
    }

    PLG_LIST_SCRIPT = "
function qwikSetInPlaceEditor(id, action) {
  new Ajax.InPlaceEditor(
    id,
    action,
    {
      onComplete: function(transport, element) {
        if (element.innerHTML.length == 0) {
          Element.remove(element.parentNode);
        }
      }
    }
  )
}

function qwikCreateSortable(list_id, list_action) {
  Sortable.create(
    list_id,
    {
      onUpdate: function() {
        new Ajax.Request(
          list_action,
          {
            asynchronous: true,
            evalScripts: true,
            parameters: Sortable.serialize(
              list_id,
              {
                name: 'sortable_list'
              }
            )
          }
        )
      }
    }
  )
}
"

    def plg_list
      content = nil
      content = yield if block_given?
      content ||= ''

      @list_num = 0 if ! defined?(@list_num)
      @list_num += 1
      list_num = @list_num

      div = list_make_div(list_num, content)

      return div
    end

    def list_make_div(list_num, content)
      w = c_tokenize(content)

      div = [:div, {:class=>'list'}]

      list_id = "list_#{list_num}"
      ul, inplace_editors = list_make_ul(list_num, list_id, w)
      div << ul

      script = list_make_script(@req.base, list_num, list_id,
				inplace_editors)
      div << script

      return div
    end

    def list_make_ul(list_num, list_id, w)
      ul = [:ul, {:id=>list_id}]
      inplace_editors = []
      item_num = 1
      w.each_element(:ul) {|li|
	#level  = li[1]		# FIXME: Use level info correctly.
	content = li[2]
	item_id = "item_#{list_num}_#{item_num}"
	span_id = "item_edit_area_#{list_num}_#{item_num}"
	action = "#{@req.base}.#{list_num}.#{item_num}.list_edit"
	ul << [:li, {:id=>item_id},
	  [:span, {:class=>"item_edit_area", :id=>span_id}, content]]
	inplace_editors << [span_id, action]
	item_num += 1
      }
      return ul, inplace_editors
    end

    def list_make_script(base, list_num, list_id, inplace_editors)
      list_action = "#{base}.#{list_num}.list_pos"
      script = ''
      script << PLG_LIST_SCRIPT if list_num == 1
      inplace_editors.each {|span_id, action|
	script << "qwikSetInPlaceEditor('#{span_id}', '#{action}');\n"
      }
      script << "qwikCreateSortable('#{list_id}', '#{list_action}');\n"
      return [:script, {:type=>'text/javascript'}, script]
    end

    def ext_list_edit
      list_num = @req.ext_args[0].to_i
      item_num = @req.ext_args[1].to_i
      return c_nerror if list_num < 1 || item_num < 1

      query = @req.query
      # [{""=>"ok", "value"=>"Aa", "_"=>""}]
      value = query['value']

      begin
	plugin_edit(:list, list_num) {|content|
	  new_content = Action.list_edit(content, item_num, value)
	  new_content
	}
      rescue NoCorrespondingPlugin
	return c_nerror(_('Failed'))
      rescue PageCollisionError
	return mcomment_error(_('Page collision detected.'))
      end

      c_make_log('list_edit') # COMMENT

      c_set_status
      c_set_no_cache
      c_set_contenttype('text/plain')
      body = value
      c_set_body(body)
    end

    def self.list_edit(content, item_num, value)
      tokens = TextTokenizer.tokenize(content)
      index = 1		# list index starts with 1
      tokens.each_element(:ul) {|token|
	if index == item_num
	  token[2] = value	# Destructive.
	end
	index += 1
      }
      return tokens_to_s(tokens)
    end

    def self.tokens_to_s(tokens)
      token_str = ''
      tokens.each_element(:ul) {|token|
	level_s = '-' * token[1]
	token_str << "#{level_s} #{token[2]}\n"
      }
      return token_str
    end

    def ext_list_pos
      list_num = @req.ext_args[0].to_i
      return c_nerror if list_num < 1

      item_list = @req.query["sortable_list[]"].list

      item_list = Action.parse_list(item_list)

      new_content = ''
      begin
	plugin_edit(:list, list_num) {|content|
	  new_content = Action.list_arrange(content, item_list)
	  pp content, new_content
	  new_content
	}
      rescue NoCorrespondingPlugin
	return c_nerror(_('Failed'))
      rescue PageCollisionError
	return mcomment_error(_('Page collision detected.'))
      end

      c_make_log('list_pos') # COMMENT

      c_set_status
      c_set_no_cache
      c_set_contenttype('text/plain')
      body = new_content
      c_set_body(body)
    end

    def self.parse_list(list)
      return list.map {|item|
	/\A(\d+)_(\d+)\z/ =~ item
	$2.to_i
      }
    end

    def self.list_arrange(content, item_list)
      tokens = TextTokenizer.tokenize(content)
      new_tokens = []
      item_list.each {|item_num|
	new_tokens << tokens[item_num - 1]
      }
      return tokens_to_s(new_tokens)
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActList < Test::Unit::TestCase
    include TestSession

    def test_all
      c = Qwik::Action

      eq([[:ul, 1, "a"]], Qwik::TextTokenizer.tokenize("-a"))
      eq([[:ul, 2, "a"]], Qwik::TextTokenizer.tokenize("--a"))
      eq([[:ul, 1, "a"], [:ul, 1, "b"]],
	 Qwik::TextTokenizer.tokenize("-a\n-b"))

      # test_tokens_to_s
      eq("- a\n", c.tokens_to_s([[:ul, 1, "a"]]))
      eq("-- a\n", c.tokens_to_s([[:ul, 2, "a"]]))
      eq("- a\n- b\n", c.tokens_to_s([[:ul, 1, "a"], [:ul, 1, "b"]]))

      # test_list_edit
      eq("- b\n", c.list_edit('-a', 1, 'b'))
      eq("- c\n- b\n", c.list_edit("-a\n-b", 1, 'c'))
      eq("- a\n- c\n", c.list_edit("-a\n-b", 2, 'c'))

      # test_parse_list
      eq([1, 3, 2], c.parse_list(["1_1", "1_3", "1_2"]))

      # test_list_arrange
      eq("- a\n- b\n", c.list_arrange("-a\n-b", [1, 2]))
      eq("- b\n- a\n", c.list_arrange("-a\n-b", [2, 1]))
    end

    def test_all2
      t_add_user

=begin
      # test_plg_list
      ok_wi([:div, {:class=>"list"},
	      [:form, {:method=>"POST", :action=>""},
		[[:ul, [:li, "a"]]],
		[:div, {:class=>"submit"},
		  [:input, {:value=>"Update", :type=>"submit"}]]]],
	    "{{list
- A
- B
- C
}}")
=end

      page = @site.create_new
      page.store("{{list
- a
- b
}}
")
      res = session("POST /test/1.1.1.list_edit?value=c")
      eq("{{list\n- c\n- b\n}}\n", page.load)

      res = session("POST /test/1.1.2.list_edit?value=d")
      eq("{{list\n- c\n- d\n}}\n", page.load)
    end
  end
end
