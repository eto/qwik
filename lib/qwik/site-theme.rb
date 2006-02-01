#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'
require 'qwik/site'
require 'qwik/site-config'

module Qwik
  class Site
    # act-theme
    def theme
      return self.siteconfig['theme']
    end

    def theme_path
      ac = @sitename+'.css'
      if self.attach.exist?(ac)
	return '/'+@sitename+'/.css/'+ac
      end

      t = self.theme
      if /\Ahttp:\/\// =~ t
	return '/.css/'+t
      end

      return ".theme/#{t}/#{t}.css"
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-module-session'
  require 'qwik/farm'
  $test = true
end

if defined?($test) && $test
  class TestSiteTheme < Test::Unit::TestCase
    include TestSession

    def test_all
      site = @memory.farm.get_top_site

      # test_theme
      ok_eq('qwikgreen', site.theme)

      # test_theme_path
      ok_eq('.theme/qwikgreen/qwikgreen.css', site.theme_path)

      page = site['_SiteConfig']
      page.store(':theme:t')

      ok_eq('t', site.theme)
      ok_eq('.theme/t/t.css', site.theme_path)
    end
  end
end
