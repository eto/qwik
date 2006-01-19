#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '..' unless $LOAD_PATH.include?('..')
require 'qwik/parse-plugin'

module Qwik
  class Action
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
  class TestCommonPluginEdit < Test::Unit::TestCase
    include TestSession

    def test_all
      # This is tested in act-table.rb
    end
  end
end
