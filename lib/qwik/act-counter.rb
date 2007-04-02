# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    D_PluginCounter = {
      :dt => 'Counter plugin',
      :dd => 'You can show a conter for the page.',
      :dc => '* Example
 {{counter}}
{{counter}}
'
    }

    D_PluginCounter_ja = {
      :dt => 'カウンター・プラグイン',
      :dd => 'アクセスカウンターを埋め込むことができます。',
      :dc => '* 例
 {{counter}}
{{counter}}
'
    }

    def plg_counter
      return [:div, {:class=>'counter'},
	[:iframe, {:src=>"#{@req.base}.counter",
	    :style=>'
margin:0;
padding:0;
width:5em;height:1em;
border: 0;
'}, '']]
    end

    def ext_counter
      couner_num = counter_increment_count
      new_counter_str = couner_num.to_s

      @res['Content-Type'] = 'text/html; charset=Shift_JIS'
      @res.body = [:html,
	[:head,
	  [:title, 'counter'],
	  [:style, '
* {
  padding: 0;
  margin: 0;
}
body {
  border: 0;
  font-family: Helvetica,Arial,Verdana,sans-serif;
  font-size: xx-small;
  text-align: right;
}
']],
	[:body, [:div, {:class=>'counter'}, new_counter_str]]]
      return nil
    end

    def counter_increment_count
      pagename = @req.base
      counter_pagename = "_counter_#{pagename}"

      counter_page = @site[counter_pagename]
      if counter_page.nil?
	counter_page = @site.create(counter_pagename)
	counter_page.store('0')
      end

      counter_str = counter_page.load
      md5 = counter_str.md5hex

      counter_num = counter_str.to_i
      counter_num += 1
      new_counter_str = counter_num.to_s

      #counter_page.store(counter_num.to_s)
      begin
	counter_page.put_with_md5(new_counter_str, md5)
      rescue PageCollisionError
	# Do nothing.
      end

      return counter_num
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActCounter < Test::Unit::TestCase
    include TestSession

    def test_all
      t_add_user

      page = @site.create_new
      page.store('{{counter}}')

      res = session('/test/1.html')
      ok_xp([:div, {:class=>'counter'},
	      [:iframe,
		{:style=>"\nmargin:0;\npadding:0;\nwidth:5em;height:1em;\nborder: 0;\n", :src=>'1.counter'}, '']],
	    "//span[@class='counter']")

      res = session('/test/1.counter')
      ok_xp([:div, {:class=>'counter'}, '1'],
	    "//div[@class='counter']")

      counter_page = @site['_counter_1']
      eq '1', counter_page.load

      res = session('/test/1.counter')
      ok_xp([:div, {:class=>'counter'}, '2'],
	    "//div[@class='counter']")
      eq '2', counter_page.load
    end
  end
end
