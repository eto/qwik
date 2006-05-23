$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Site
    def search(query, obfuscate = true)
      querys = search_parse_query(query)

      ar = []
      self.each {|page|
	str = page.load
	str.each_with_index {|line, i|
	  matched = true

	  querys.each {|query|
	    regexp = Regexp.new(Regexp.escape(query), Regexp::IGNORECASE)
	    if ! regexp.match(line)
	      matched = false
	    end
	  }

	  if matched
	    line = MailAddress.obfuscate_str(line) if obfuscate
	    ar << [page.key, line, i]
	  end
	}
      }

      ar
    end

    def search_parse_query(query)
      return query.strip.split
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestSiteSearch < Test::Unit::TestCase
    include TestSession

    def test_all
      res = session

      page = @site.create_new
      page.store('This is a test.')
      page = @site.create_new
      page.store('This is a test, too.')

      res = @site.search('test')
      ok_eq([['1', 'This is a test.', 0],
	      ['2', 'This is a test, too.', 0]], res)

      # test_obfuscate
      page.store('user@example.com')
      res = @site.search('@')
      is [["2", "user@e...", 0]], res

      res = @site.search('@', false)
      is [["2", "user@example.com", 0]], res
    end
  end
end
