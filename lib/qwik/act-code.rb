$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    def plg_code(lang=nil)
      b = ''
      b = yield if block_given?
      return [:div, {:class=>'code'},
	[:pre, b]]
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActCode < Test::Unit::TestCase
    include TestSession

    def test_code
      res = session
      ok_wi([:div, {:class=>'code'}, [:pre, "t\n"]], "{{code\nt\n}}")
    end
  end
end
