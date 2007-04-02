# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    def plg_tableform(dest=nil)
      content = yield
      return TableForm.generate(self, dest, content, @req.base)
    end

    def plg_form(dest=nil, method=nil)
      str = yield
      dest = @req.base unless dest && ! dest.empty?
      action = dest.to_s.escape
      action += '.html' if action[0] != ?.
      http_method = nil
      if method
	http_method = 'GET' if method == 'GET'
	http_method = 'POST' if method == 'POST'
      end
      hash = {:method=>http_method, :action=>action}
      hash.delete_if {|k, v| v.nil? }
      form = [:form, hash]
      form += c_res(str)
      return form
    end

    def req_user
      return @req.user
    end
  end

  class TableForm
    def self.generate(action, dest, str, pagename)
      table = [:table, {:class=>'form'}]

      str.each {|line|
	line.chomp!

	ar = line.split(/\|/)
	ar.shift

	case ar.length
	when 1
	  table << [:tr, [:td, {:colspan=>2, :class=>'msg'}, ar.shift]]

	when 2
	  midashi = ar.shift
	  td = []
	  nakami = ar.shift
	  nakami.sub!(/^\{\{/, "")
	  nakami.sub!(/\}\}$/, "")

	  if /^([^\(\)]+)\((.*)\)$/ =~ nakami
	    cmd, args = $1, $2
	    aa = args.split(/,/)

	    case cmd
	    when 'input'
	      td << gen_input(*aa)

	    when 'select'
	      td << gen_select(*aa)

	    when 'textarea'
	      name, w, h, msg = aa
	      msg = '' if !msg
	      msg.gsub!(/\\n/, "\n")
	      td << gen_textarea(name, w, h, msg)

	    when 'submit'
	      su = gen_submit(*aa)
	      su.attr[:class] = 'submit'
	      td << su

	    when 'show'
	      td << [:span, action.show(*aa)]

	    when 'ring_show'
	      td << [:span, action.plg_ring_show(*aa)]

	    when 'member_user'
	     #td << [:span, action.plg_member_user]
	      td << [:span, action.req_user]

	    end
	  else
	    td << [:span, nakami]
	  end
	  etd = [:td, {:class=>'nakami'}, td]
	  etr = [:tr, [:td, {:class=>'midashi'}, midashi], etd]
	  table << etr
	else
	  table << [:tr, ar.to_s] #debug
	end
      }

      action = "#{pagename.to_s.escape}.html"
      action = "#{dest.to_s.escape}.html" if dest && ! dest.empty?

      div = [:div, {:class=>'form'},
	[:form, {:method=>'POST', :action=>action},
	  [:input, {:type=>'hidden', :name=>'page', :value=>pagename.escape}],
	  table]]
      return div
    end

    def self.gen_input(name, value=nil, size=nil, maxsize=nil)
      attr = {:name=>name}
      attr[:value] = value if value
      attr[:size] = size if size
      attr[:maxsize] = maxsize if maxsize
      return [:input, attr]
    end

    def self.gen_input_password(n, v=nil)
      attr = {:type=>'password', :name=>n}
      attr[:value] = v if v
      return [:input, attr]
    end

    def self.gen_select(n, *aa)
      return [:select, {:name=>n}] + aa.map {|a| [:option, {:name=>a}, a] }
    end

    def self.gen_submit(v=nil, n=nil)
      attr = {:type=>'submit'}
      attr[:value] = v if v
      attr[:name] = n if n
      return [:input, attr]
    end

    def self.gen_textarea(name, cols=nil, rows=nil, msg=nil)
      msg ||= ''
      msg.gsub!(/\\n/, "\n")
      attr = {:name=>name}
      attr[:cols] = cols if cols
      attr[:rows] = rows if rows
      return [:textarea, attr, msg]
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActTableForm < Test::Unit::TestCase
    include TestSession

    alias ok ok_eq

    def test_form_element
      c = Qwik::TableForm
      ok([:input, {:name=>'n'}], c.gen_input('n'))
      ok([:input, {:value=>'v', :name=>'n'}], c.gen_input('n', 'v'))
      ok([:input, {:type=>'password', :name=>'n'}], c.gen_input_password('n'))
      ok([:input, {:value=>'v', :type=>'submit'}], c.gen_submit('v'))
      ok([:textarea, {:name=>'n'}, ''], c.gen_textarea('n'))
      ok([:textarea, {:cols=>'40', :name=>'n', :rows=>'7'}, ''],
	 c.gen_textarea('n', '40', '7'))
      ok([:textarea, {:cols=>'40', :name=>'n', :rows=>'7'}, 'msg'],
	 c.gen_textarea('n', '40', '7', 'msg'))
      # does not work for now
      ok([:textarea, {:cols=>'40', :name=>'n', :rows=>'7'}, "line1\nline2"],
	 c.gen_textarea('n', '40', '7', "line1\\nline2"))
      ok([:select, {:name=>'n'}], c.gen_select('n'))
      ok([:select, {:name=>'n'}, [:option, {:name=>'1'}, '1']],
	 c.gen_select('n', '1'))
    end

    def test_form_arg
      ok_wi([:form, {:action=>'DestPage.html'}, [:p, 'a']],
	    "{{form(DestPage)\na\n}}")
      ok_wi([:form, {:method=>'POST', :action=>'DestPage.html'}, [:p, 'a']],
	    "{{form(DestPage, POST)\na\n}}")
      ok_wi([:form, {:action=>'1.html'}, [:dl, [:dt, 'k'], [:dd, 'v']]],
	    "{{form\n:k:v\n}}")
      # test_real_situation
    end

    def test_tableform
      ok_wi([:div, {:class=>'form'},
	      [:form, {:method=>'POST', :action=>'dest.html'},
		[:input, {:value=>'1', :type=>'hidden', :name=>'page'}],
		[:table, {:class=>'form'},
		  [:tr,
		      [:td, {:class=>'midashi'}, 'k'],
		      [:td, {:class=>'nakami'}, [[:span, 'v']]]]]]],
	    "{{tableform(dest)\n|k|v|\n}}")

      ok_wi([:div, {:class=>'form'},
	      [:form, {:method=>'POST', :action=>'dest.html'},
		[:input, {:value=>'1', :type=>'hidden', :name=>'page'}],
		[:table, {:class=>'form'},
		  [:tr,
		      [:td, {:class=>'midashi'}, 'mail'],
		      [:td, {:class=>'nakami'},
			[[:input, {:size=>'must',
			      :value=>'', :name=>'tomail'}]]]],
		    [:tr, [:td, {:class=>'msg', :colspan=>2},
			'input your mail.']],
		    [:tr,
		      [:td, {:class=>'midashi'}, ''],
		      [:td, {:class=>'nakami'},
			[[:input, {:value=>' GO ',
			      :type=>'submit', :class=>'submit'}]]]]]]],
	    "{{tableform(dest)
|mail|{{input(tomail,,must)}}|
|input your mail.|
||{{submit( GO )}}|
}}")

      ok_wi([:div, {:class=>'form'},
	      [:form, {:method=>'POST', :action=>'1.html'},
		[:input, {:value=>'1', :type=>'hidden', :name=>'page'}],
		[:table, {:class=>'form'},
		  [:tr,
		      [:td, {:class=>'midashi'}, "€–Ú"],
		      [:td, {:class=>'nakami'},
			[[:input, {:size=>'must',
			      :value=>'default', :name=>'name'}]]]],
		    [:tr, [:td, {:class=>'msg', :colspan=>2}, "à–¾"]],
		    [:tr,
		      [:td, {:class=>'midashi'}, ''],
		      [:td, {:class=>'nakami'},
			[[:input, {:value=>" “Še ",
			      :type=>'submit', :class=>'submit'}]]]]]]],
	    "{{tableform
|€–Ú|{{input(name,default,must)}}|
|à–¾|
||{{submit( “Še )}}|
}}")
    end
  end
end
