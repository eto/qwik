class String
  # Copied from cgi.rb
  def escape
    return self.gsub(/([^ a-zA-Z0-9_.-]+)/n) {
      '%' + $1.unpack('H2' * $1.size).join('%').upcase
    }.tr(' ', "+")
  end

  def unescape
    return self.tr("+", ' ').gsub(/((?:%[0-9a-fA-F]{2})+)/n) {
      [$1.delete('%')].pack('H*')
    }
  end

  def unescapeHTML
    return self.gsub(/&(.*?);/n) {
      match = $1.dup
      case match
      when /\Aamp\z/ni	then "&"
      when /\Aquot\z/ni	then "'"
      when /\Agt\z/ni	then ">"
      when /\Alt\z/ni	then "<"
      else
	"&#{match};"
      end
    }
  end

  # Copied from gonzui-0.1
  # Use this method instead of WEBrick::HTMLUtils.escape for performance reason.
  EscapeTable = {
    "&" => "&amp;",
    '"' => "&quot;",
    '<' => "&lt;",
    '>' => "&gt;",
  }
  def escapeHTML
    string = self
    return string.gsub(/[&"<>]/n) {|x| EscapeTable[x] }
  end
end

if $0 == __FILE__
  require 'test/unit'
  $test = true
end

if defined?($test) && $test
  class TestEscape < Test::Unit::TestCase
    def test_all
      # test_escape
      assert_equal('A', 'A'.escape)
      assert_equal("+", ' '.escape)
      assert_equal('%2B', "+".escape)
      assert_equal('%21', "!".escape)
      assert_equal("ABC%82%A0%82%A2%82%A4+%2B%23", "ABC‚ ‚¢‚¤ +#".escape)

      # test_unescape
      assert_equal('A', '%41'.unescape)
      assert_equal(' ', "+".unescape)
      assert_equal("!", '%21'.unescape)
      assert_equal("ABC‚ ‚¢‚¤ +#", "ABC%82%A0%82%A2%82%A4+%2B%23".unescape)

      # test_escapeHTML
      assert_equal("&lt;", "<".escapeHTML)
      assert_equal("&gt;", ">".escapeHTML)
      assert_equal("&amp;", "&".escapeHTML)
      assert_equal("&lt;a href=&quot;http://e.com/&quot;&gt;e.com&lt;/a&gt;",
		   '<a href="http://e.com/">e.com</a>'.escapeHTML)

      # test_unescapeHTML
      assert_equal("<", "&lt;".unescapeHTML)
      assert_equal(">", "&gt;".unescapeHTML)
      assert_equal("&", "&amp;".unescapeHTML)
      assert_equal("<a href='http://e.com/'>e.com</a>",
		   "&lt;a href=&quot;http://e.com/&quot;&gt;e.com&lt;/a&gt;".unescapeHTML)
    end
  end
end
