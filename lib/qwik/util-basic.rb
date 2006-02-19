$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'
require 'qwik/util-escape'

class Hash
  def to_query_string
    ar = []
    self.each {|k, v|
      if k && v
	ar << "#{k.to_s.escape}=#{v.to_s.escape}"
      end
    }
    return ar.sort.join('&')
  end
end

if $0 == __FILE__
  require 'test/unit'
  $test = true
end

if defined?($test) && $test
  class TestUtilBasic < Test::Unit::TestCase
    def test_all
      # test_hash_to_query_string
      assert_equal 'k=v', {:k=>'v'}.to_query_string
      assert_equal 'k1=v1&k2=v2', {:k1=>'v1', :k2=>'v2'}.to_query_string
    end
  end
end
