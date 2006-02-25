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
  require 'qwik/testunit'
  $test = true
end

if defined?($test) && $test
  class TestEscape < Test::Unit::TestCase
    def test_all
      # test_escape
      ok_eq('A', 'A'.escape)
      ok_eq("+", ' '.escape)
      ok_eq('%2B', "+".escape)
      ok_eq('%21', "!".escape)
      ok_eq("ABC%82%A0%82%A2%82%A4+%2B%23", "ABC‚ ‚¢‚¤ +#".escape)

      # test_unescape
      ok_eq('A', '%41'.unescape)
      ok_eq(' ', "+".unescape)
      ok_eq("!", '%21'.unescape)
      ok_eq("ABC‚ ‚¢‚¤ +#", "ABC%82%A0%82%A2%82%A4+%2B%23".unescape)

      # test_escapeHTML
      ok_eq("&lt;", "<".escapeHTML)
      ok_eq("&gt;", ">".escapeHTML)
      ok_eq("&amp;", "&".escapeHTML)
      ok_eq("&lt;a href=&quot;http://e.com/&quot;&gt;e.com&lt;/a&gt;",
	    '<a href="http://e.com/">e.com</a>'.escapeHTML)

      # test_unescapeHTML
      ok_eq("<", "&lt;".unescapeHTML)
      ok_eq(">", "&gt;".unescapeHTML)
      ok_eq("&", "&amp;".unescapeHTML)
      ok_eq("<a href='http://e.com/'>e.com</a>",
	    "&lt;a href=&quot;http://e.com/&quot;&gt;e.com&lt;/a&gt;".unescapeHTML)
    end
  end
end
