# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    def plg_lang(lang)
      # lang should be only two letters length.
      return 'error' unless /\A[a-z][a-z]\z/ =~ lang

      alang = @req.accept_language[0]

      return '' unless alang && alang == lang

      s = yield
      return c_res(s)
    end

    def plg_lang_select
      pagebase = @req.base
      if /\A([0-9A-Za-z]+)_([a-z][a-z])\z/ =~ @req.base
	pagebase = $1
	lang = $2
      end

      list = []
      @req.accept_language.each {|lang|
	pagename_with_lang = "#{pagebase}_#{lang}"
	if @site.exist?(pagename_with_lang)
	  #list << pagename_with_lang
	  list << lang
	end
      }

      return nil if list.empty?

      list.unshift ''
      return list.map {|lang|
	page = "#{pagebase}"
	page = "#{pagebase}_#{lang}" if ! lang.empty?
	lang = "default" if lang.empty?
	[:a, {:href=>"#{page}.html"}, lang]
      }
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActLang < Test::Unit::TestCase
    include TestSession

    def test_lang
      ok_wi('error', "{{lang(nosuchlang)\na\n}}")
      ok_wi([""], "{{lang(ja)\nj\n}}")
     #ok_wi([], "{{lang(ja)\nj\n}}")
      ok_wi([:p, 'e'], "{{lang(en)\ne\n}}")

      ok_wi([:p, 'j'], "{{lang(ja)\nj\n}}") {|req|
	req.accept_language = ['ja']
      }
      ok_wi("", "{{lang(en)\ne\n}}") {|req|
	req.accept_language = ['ja']
      }
    end

    def test_lang_select
      ok_wi [], '{{lang_select}}'

      page = @site.create('1_en')
      ok_wi [[:a, {:href=>'1.html'}, 'default'],
	[:a, {:href=>'1_en.html'}, 'en']], '{{lang_select}}'
    end
  end
end
