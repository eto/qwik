require 'md5'

$LOAD_PATH << 'compat' unless $LOAD_PATH.include? 'compat'
require 'base64'

$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'

class String
  def xchomp
    return self.chomp("\n").chomp("\r")
  end

  # Used from parser.rb
  def chompp
    return self.sub(/[\n\r]+\z/, "")
  end

  def normalize_eol
    return self.xchomp+"\n"
  end

  def normalize_newline
    return self.gsub("\r\n", "\n").gsub("\r", "\n")
  end

  def sub_str(pattern, replace)
    return sub(Regexp.new(Regexp.escape(pattern)), replace)
  end

  def md5
    return MD5.digest(self)
  end

  def md5hex
    return MD5.hexdigest(self)
  end

  def base64
    return Base64.encode64(self).chomp
  end
end

if $0 == __FILE__
  require 'test/unit'
  $test = true
end

if defined?($test) && $test
  class TestUtilString < Test::Unit::TestCase
    def test_string
      # test_xchomp
      assert_equal '', ''.xchomp
      assert_equal "", "\n".xchomp
      assert_equal "", "\r".xchomp
      assert_equal "", "\r\n".xchomp
      assert_equal "\n", "\n\r".xchomp
      assert_equal 't', 't'.xchomp
      assert_equal 't', "t\r".xchomp
      assert_equal 't', "t\n".xchomp

      # test_chompp
      assert_equal "", "\n\r".chompp
      assert_equal "", "\n\r\n\r".chompp

      # test_normalize_eol
      assert_equal "\n", "".normalize_eol
      assert_equal "\n", "\n".normalize_eol
      assert_equal "t\n", 't'.normalize_eol
      assert_equal "t\n", "t\n".normalize_eol

      # test_normalize_newline
      assert_equal "\n", "\n".normalize_newline
      assert_equal "\n", "\r".normalize_newline
      assert_equal "\n", "\r\n".normalize_newline
      assert_equal "\n\n", "\n\r".normalize_newline
      assert_equal "\na\n", "\ra\r".normalize_newline
      assert_equal "\na\n", "\r\na\r\n".normalize_newline
      assert_equal "\n\na\n\n", "\n\ra\n\r".normalize_newline

      # test_sub_str
      assert_equal 'a:b', 'a*b'.sub_str('*', ':')

      # test_md5
      assert_instance_of String, 't'.md5
      assert_equal 16, 't'.md5.length
      assert_equal "\343X\357\244\211\365\200b\361\r\3271ked\236", 't'.md5
      assert_instance_of String, 't'.md5hex
      assert_equal 32, 't'.md5hex.length
      assert_equal 'e358efa489f58062f10dd7316b65649e', 't'.md5hex
      assert_equal "dA==", 't'.base64
    end
  end
end
