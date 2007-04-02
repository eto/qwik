# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    def plg_notice
      msg = yield
      w = c_parse(msg)
      div = [:div, {:class=>'notice'}] + w
      return div
    end

    LICENSE = {
      'cc' => "You can use the files on this site under [[Creative Commons by 2.1|http://creativecommons.org/licenses/by/2.1/jp/]] license.",
      'cc-by-sa-2.5' => "You can use the files on this site under [[Creative Commons Attribution-ShareAlike 2.5|http://creativecommons.org/licenses/by-sa/2.5/]] license.",
      'upload-cc-by-sa-2.5' => "The files you uploaded will be under [[Creative Commons Attribution-ShareAlike 2.5|http://creativecommons.org/licenses/by-sa/2.5/]] license."
    }

    def plg_license(license)
      text = license_text(license)
      return if text.nil?
      w = c_parse(text)
      return [:div, {:class=>'license'}] + w
    end

    # TODO: Show CC icon.
    def license_text(license)
      msg = LICENSE[license]
      return '' if msg.nil?
      newmsg = _(msg)
      return newmsg
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActLicense < Test::Unit::TestCase
    include TestSession

    def test_all
      ok_wi([:div, {:class=>'notice'}, [:p, 't']], "{{notice\nt\n}}")

      # test_act_license
      ok_wi([:div, {:class=>'license'},
	      [:p, 'You can use the files on this site under ',
		[:a, {:href=>'http://creativecommons.org/licenses/by/2.1/jp/'},
		  'Creative Commons by 2.1'], ' license.']],
	    "{{license(cc)}}")

#      @action.plg_license('cc')
#      @action.plg_license('cc-by-sa-2.5')
#      @action.plg_license('upload-cc-by-sa-2.5')
    end
  end
end
