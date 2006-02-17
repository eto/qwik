$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'
require 'qwik/test-common'
require 'qwik/act-style'

class CheckExtCss < Test::Unit::TestCase
  include TestSession

  def test_dummy
  end

  def nutest_all
    # test_extcss_nosuch
    res = session('/.css/http://nosuchhostname/q.css')
    ok_title('Access Failed')

    # test_extcss_hatena
    res = session('/.css/http://d.hatena.ne.jp/theme/clover/clover.css')
    if @res.body.is_a?(Array)
      ok_title('Access Failed')
    else
      #ok_eq(true, 1000 < @res.body.length)
    end
  end
end
