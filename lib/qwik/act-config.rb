# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    NotYet_D_site_config = {
      :dt => 'Site Config mode',
      :dd => 'You can edit site configurations.',
      :dc => "* Example
[[site.config]]
"
    }

    def notyet_ext_config
      method = "config_#{@req.base}"
      return c_nerror if ! self.respond_to?(method)
      return self.send(method)
    end

    SITE_CONFIG = '_SiteConfig'

    def config_site
      @req.base = SITE_CONFIG		# Fake.
      w = []
      w << [:h1, _('Site Configuration')]
      w = c_res(content)
      w = TDiaryResolver.resolve(@config, @site, self, w)
      title = _('Function')+' | '+hash[:dt]
      return c_surface(title, true) { w }
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestAction < Test::Unit::TestCase
    include TestSession

    def test_config
    end
  end
end
