# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/description'
require 'qwik/description-ja'
# FIXME: Load description files from all languages automatically.

module Qwik
  class Action
    NotNecessary_D_ExtDescribe = {
      :dt => 'Description of functions',
      :dd => 'You can see the description of each functions of qwikWeb.',
      :dc => "* Example
 [[QwikWeb.describe]]
[[QwikWeb.describe]]

You can see the list below.
"
    }

    NotNecessary_D_ExtDescribe_ja = {
      :dt => '機能説明',
      :dd => 'qwikWebの機能説明を見ることができます。',
      :dc => '* 例
 [[QwikWeb.describe]]
[[QwikWeb.describe]]

機能説明の一覧は、この下についてきます。
'
    }

    def notuse_plg_description_list_dl
      list = [:dl]
      self.description_list(@req.accept_language).each {|name|
	hash = description_get(name, @req.accept_language)
	list << [:dt, [:a, {:href=>"#{name}.describe"},
	    [:em, name], "  | ", [:strong, hash[:dt]]]]
	list << [:dd, hash[:dd]]
      }
      return [:div, {:class=>'description-list'}, list]
    end

    def plg_description_list
      list = [:ul]
      self.description_list(@req.accept_language).each {|name|
	hash = description_get(name, @req.accept_language)
	list << [:li, [:a, {:href=>"#{name}.describe"},
	    [:em, name], ' ', [:strong, hash[:dt]]], ' ', hash[:dd]]
      }
      return [:div, {:class=>'description-list'}, list]
    end

    def description_list(langs=nil)
      langs = [] if langs.nil?
      langs << '' if ! langs.include?('')
      list = []
      self.class.constants.each {|constname|
	langs.each {|lang|
	  if /\AD_([A-Za-z]+)_#{lang}\z/ =~ constname
	    if ! list.include?($1)
	      list << $1
	    end
	  elsif /\AD_([A-Za-z]+)\z/ =~ constname
	    if ! list.include?($1)
	      list << $1
	    end
	  end
	}
      }
      return list.sort
    end

    DEFAULT_DESCRIPTION = 'QwikWeb'

    def act_describe
      @req.base = DEFAULT_DESCRIPTION
      return ext_describe
    end

    def ext_describe
      hash = description_get(@req.base, @req.accept_language)
      return c_nerror('No such description') if hash.nil?
      content = "#{hash[:dd]}
#{hash[:dc]}
* #{_('Functions list')}
{{description_list}}
"
      @req.base = 'FrontPage'		# Fake.
      w = c_res(content)
      w = TDiaryResolver.resolve(@config, @site, self, w)
      #title = "#{_('Function')} | #{hash[:dt]}"
      title = hash[:dt]
      return c_surface(title, true) { w }
    end

    def description_get(name, langs=nil)
      langs = [] if langs.nil?
      langs << '' if ! langs.include?('')
      langs.each {|lang|
	lang.gsub!(/-/, '_')
	constname = "D_#{name}"
	constname = "D_#{name}_#{lang}" if ! lang.empty?
	if self.class.const_defined?(constname)
	  return self.class.const_get(constname)
	end
      }
      return nil
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActDescribe < Test::Unit::TestCase
    include TestSession

    def test_all
      t_add_user
      res = session '/test/QwikWeb.describe'
      ok_title 'How to qwikWeb'
#      ok_in [:p, 'You can see the description of each functions of qwikWeb.'],
#	'//div[@class="section"]'

      # test_description_list
      list = @action.description_list
      eq true, 0 < list.length
    end
  end
end
