#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '../../lib' unless $LOAD_PATH.include?('../../lib')

module Qwik
  class Action
    D_textarea = {
      :dt => 'Textarea plugin',
      :dd => 'You can show a simple textarea field.',
      :dc => "
* Textarea plugin
{{textarea
This is an example for textarea.
}}
 {{textarea
 This is an example for textarea.
 }}
You can show a editable text filed.

Since this is description page, you can not edit text field here.
" }

    TEXTAREA_MIN_COLS = 50
    TEXTAREA_MIN_ROWS = 4

    def plg_textarea
      # @textarea_num is global for an action.
      @textarea_num = 0 if ! defined?(@textarea_num)
      @textarea_num += 1
      action = "#{@req.base}.#{@textarea_num}.textarea"

      content = ''
      content = yield if block_given?

      cols = rows = 0
      content.each_line {|line|
	len = line.chomp.length
	cols = len if cols < len
	rows += 1
      }
      cols = TEXTAREA_MIN_COLS if cols < TEXTAREA_MIN_COLS
      rows = TEXTAREA_MIN_ROWS if rows < TEXTAREA_MIN_ROWS

      return [:div, {:class=>'textarea'},
	[:form, {:method=>'POST', :action=>action},
	  [:textarea, {:name=>'t', :cols=>cols, :rows=>rows}, content],
	  [:br],
	  [:input, {:type=>'submit', :value=>_('Update')}]]]
    end

    def ext_textarea
      c_require_post
      c_require_page_exist

      num = @req.ext_args[0].to_i
      return c_nerror(_('Error')) if num < 1

      text = @req.query['t']
      return c_nerror(_('No text')) if text.nil? || text.empty?
      text = text.normalize_newline

      begin
	plugin_edit(:textarea, num) {|content|
	  text
	}
      rescue NoCorrespondingPlugin
	return c_nerror(_('Failed'))
      rescue PageCollisionError
	return mcomment_error(_('Page collision detected.'))
      end

      c_make_log('textarea')	# TEXTAREA

      url = "#{@req.base}.html"
      return c_notice(_('Edit text done.'), url){
	[[:h2, _('Edit text done.')],
	  [:p, [:a, {:href=>url}, _('Go back')]]]
      }
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActTextarea < Test::Unit::TestCase
    include TestSession

    def test_plg_textarea
      ok_wi([:div, {:class=>"textarea"},
	      [:form, {:action=>"1.1.textarea", :method=>"POST"},
		[:textarea, {:rows=>4, :name=>"t", :cols=>50}, "a\n"],
		[:br],
		[:input, {:value=>"Update", :type=>"submit"}]]],
	    "{{textarea
a
}}")
      ok_wi([:div, {:class=>"textarea"},
	      [:form, {:action=>"1.1.textarea", :method=>"POST"},
		[:textarea, {:rows=>4, :name=>"t", :cols=>55},
		  "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\n"],
		[:br],
		[:input, {:value=>"Update", :type=>"submit"}]]],
	    "{{textarea
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
}}")
      ok_wi([:div, {:class=>"textarea"},
	      [:form, {:action=>"1.1.textarea", :method=>"POST"},
		[:textarea, {:rows=>6, :name=>"t", :cols=>50},
		  "a\nb\nc\nd\ne\nf\n"],
		[:br],
		[:input, {:value=>"Update", :type=>"submit"}]]],
	    "{{textarea
a
b
c
d
e
f
}}")
    end

    def test_ext_textarea
      t_add_user

      page = @site.create_new
      page.store("{{textarea}}\n")
      res = session('POST /test/1.html')
      ok_xp([:div, {:class=>"textarea"},
	      [:form, {:action=>"1.1.textarea", :method=>"POST"},
		[:textarea, {:rows=>4, :name=>"t", :cols=>50}, ""],
		[:br],
		[:input, {:value=>"Update", :type=>"submit"}]]],
	    "//div[@class='textarea']")

      res = session("POST /test/1.1.textarea?t=a")
      ok_eq("{{textarea\na\n}}\n", page.load)

      res = session("POST /test/1.1.textarea?t=a2")
      ok_eq("{{textarea\na2\n}}\n", page.load)
    end
  end
end
