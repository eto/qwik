$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    def ext_config
      method = "config_#{@req.base}"
      return c_nerror(_('Error')) if ! self.respond_to?(method)
      return self.send(method)
    end

    def config_site
      @req.base = '_SiteConfig'		# Fake.
      w = []
      w << [:h1, "SiteConfig"]
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
  class TestActDescribe < Test::Unit::TestCase
    include TestSession

    def test_all
      t_add_user
      res = session('/test/describe.describe')
      ok_title('Function | Description of functions')
      ok_in([:p, 'You can see the description of each functions of qwikWeb.'],
	    '//div[@class="section"]')

      # test_description_list
      list = @action.description_list
      eq(true, 0 < list.length)
#     eq(true, list.include?('describe'))
    end
  end
end
