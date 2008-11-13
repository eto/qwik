# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/util-time'
require 'qwik/parse-plugin'

module Qwik
  # ============================== exception
  class QwikError < StandardError; end
  class RequireLogin < QwikError; end
  class RequirePost < QwikError; end
  class PageNotFound < QwikError; end
  class RequireNoPathArgs < QwikError; end
  class RequireMember < QwikError; end
  class InvalidUserError < QwikError; end
  class BaseIsNotSitename < QwikError; end
  class NoCorrespondingPlugin < QwikError; end	# plugin

  class Action
    # ============================== response
    def c_set_status(status=200)
      @res.status = status
    end

    def c_set_contenttype(contenttype="text/html; charset=Shift_JIS")
      @res['Content-Type'] = contenttype
    end
    alias c_set_html c_set_contenttype

    def c_set_no_cache(pragma='no-cache', control='no-cache')
      @res['Pragma'] = pragma
      @res['Cache-Control'] = control
    end

    def c_set_location(location)
      @res['Location'] = location
    end

    def c_set_body(body)
      @res.body = body
    end

    # ============================== rewrite plugin
    def plugin_edit(plugin_name, plugin_num)
      # Get the original page.
      page = @site[@req.base]
      str = page.load
      md5 = str.md5hex

      # Split the page into paragraphs.
      paragraphs = Plugin.split(str)

      # Replace the content of the plugin.
      written = false
      new_paras = Plugin.rewrite(paragraphs, plugin_name, plugin_num) {|plugin|
	plugin_org_content = plugin[2] || ''
	plugin_altered_content = yield(plugin_org_content)
	plugin[2] = plugin_altered_content	# Destructive.
	written = true
	plugin
      }

      raise NoCorrespondingPlugin if ! written

      # Reconstruct the page from the lines.
      new_page_str = Plugin.join(new_paras)

      page.put_with_md5(new_page_str, md5)

      return nil
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestCommon < Test::Unit::TestCase
    include TestSession

    def test_response
      res = session

      # test_c_set_status
      @action.c_set_status(7743)
      ok_eq(7743, res.status)

      # test_c_set_contenttype
      @action.c_set_contenttype
      ok_eq("text/html; charset=Shift_JIS", res['Content-Type'])

      # test_c_set_no_cache
      @action.c_set_no_cache
      ok_eq('no-cache', res['Pragma'])
      ok_eq('no-cache', res['Cache-Control'])

      # test_c_set_body
      @action.c_set_body('body')
      ok_eq('body', res.body)
    end

    def nu_test_rewrite_plugin
      # This is tested in act-table.rb
    end
  end
end
