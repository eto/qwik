# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

require 'qwik/db-searchwords.rb'

module Qwik
  class Site
    COMMENT = /^#.*$/

=begin
    def init_site_search
      @search_words_db = SearchWordsDB.new(@path, @config)
    end

    def get_search_words
      @search_words_db.get_normalized
    end

    def delete_search_word(word)
      @search_words_db.delete(word)
    end
=end

    def search(query, obfuscate = true)
      queries = search_parse_query(query)
#      @search_words_db.put(queries)
      
      all_snippet_length = 120
      pre_snippet_length = all_snippet_length / queries.size / 2

      ar = []
      self.each {|page|
	str = page.load
	str = str.gsub(COMMENT, '')
	str = wiki_to_string(str)
	matched = true

	mds = []
	snippet = ""

	queries.each {|query|
	  regexp = Regexp.new(Regexp.escape(query),
                              Regexp::IGNORECASE|Regexp::MULTILINE)
	  md = regexp.match(str)
	  if ! md
	    matched = false
	    break
	  else
	    mds.push(md)
	  end
	}

	if matched
	  snippet = create_snippet(mds)
	  snippet = MailAddress.obfuscate_str(snippet) if obfuscate
	  ar << [page.key, snippet]
	end
      }

      ar
    end

    def search_parse_query(query)
      return query.strip.split.map{|e| e.downcase }.uniq
    end

    private

    def wiki_to_string(wiki)
      tokens = Qwik::TextTokenizer.tokenize(wiki, true)
      wabisabi = Qwik::TextParser.make_tree(tokens)
      return wabisabi.flatten.select{|a| a.class == String}.join(" ")
    end

    def create_snippet(mds)
      #sort as first hit keyword goes first
      mds = mds.sort {|i, j| i.begin(0) <=> j.begin(0) }
      max_width = 400

      # merge snippets of each search key
      #
      #        snip[s,      e] 
      #|============|1st key|=============|
      snip = [mds[0].begin(0), mds[0].end(0)]

      mds[1..-1].each {|md|
        #|=====|1st key|==...==|last key|========|a key|===..===|
        # snip[s,                      e]        ^
	#                                        |md.begin(0)
	#       <-------------------------.......----->
	#                     max_width
	#            this is the length of bytes, not characters
	if md.begin(0) < snip[0] + max_width
	  # extends snip end
          # snip[s,                                     e]
          #|====|1st key|==...==|last key|========|a key|===..===|
	  snip[1] = md.end(0) 
	end
      }

      #all md(MatchData) has same input string
      all_string = mds[0].string

      snippet = all_string[snip[0]...snip[1]]
      len = snippet.mb_length # character length
      rest = (max_width - len) / 2
      if 0 < rest
        # we have shot snippet, adding additional strings
	pre = all_string[0...snip[0]]
	post = all_string[snip[1]..-1]

        if rest < pre.size
	  pre = pre.mb_substring(-rest, pre.length)
	end

        if rest < post.size
	  post = post.mb_substring(0, rest)
	end
	snippet = pre + snippet + post
      end
      
      return snippet
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

    def test_dummy
    end

    def test_all
      res = session

      page = @site.create_new
      page.store('This is a test.')
      page = @site.create_new
      page.store('This is a test, too.')

      res = @site.search('test')
      ok_eq([['1', 'This is a test.'],
	      ['2', 'This is a test, too.']], res)

      # test_obfuscate
      page.store('user@example.com')
      res = @site.search('@')
      is [["2", "user@e..."]], res

      res = @site.search('@', false)
      is [["2", "user@example.com"]], res
    end

    def test_skip_sharp
      page = @site.create_new
      page.store('This is a test.')
      page = @site.create_new
      page.store('# This is a test start with sharp.')
      page = @site.create_new
      page.store("This is a test which have `#' in a middle of line.")
      page = @site.create_new
      page.store('This is a test, too.')

      res = @site.search('test')
      ok_eq([["1", "This is a test."],
             ["3", "This is a test which have `# '  in a middle of line."],
             ["4", "This is a test, too."]], res)
    end

  end
end
