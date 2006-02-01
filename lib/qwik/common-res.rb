#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'
require 'qwik/parser'
require 'qwik/resolve'
require 'qwik/page-generate'

module Qwik
  class Action
    def p_error(msg)
      return [:div, {:class=>'error'}, [:strong, _('Error'), ':'], ' ', msg]
    end

    def c_get_superpage(k)
      return @site.get_superpage(k)
    end

    # ==================== generate from string
    def c_tokenize(str)
      tokens = TextTokenizer.tokenize(str)
      return tokens
    end

    def c_parse(str)
      tokens = TextTokenizer.tokenize(str)
      tree = TextParser.make_tree(tokens)
      return tree
    end

    def c_res(str)
      tokens = TextTokenizer.tokenize(str)
      tree = TextParser.make_tree(tokens)
      w = Resolver.resolve(@site, self, tree)
      return w
    end

    # ==================== generate for page
    def c_page_res(pagename)
      page = @site[pagename]
      return nil if page.nil?
      tree = page.get_tree
      w = Resolver.resolve(@site, self, tree)
      return w
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActGenerate < Test::Unit::TestCase
    include TestSession

    def test_all
      res = session

      a = @action

      # test_p_error
      ok_eq([:div, {:class=>'error'}, [:strong, 'Error', ':'], ' ', 'e'],
	    a.p_error('e'))

      # test_c_tokenize
      ok_eq([[:text, "a"], [:text, "b"]], a.c_tokenize("a\nb"))

      # test_c_parse
      ok_eq([[:p, 'a', "\n", 'b']], a.c_parse("a\nb"))

      # test_c_page_res
      page = @site.create_new
      page.store('* t')
      ok_eq([[:h2, 't']], a.c_page_res('1'))

      page = @site.create_new
      page.store('[[1]]')
      ok_eq([[:p, [:a, {:href=>'1.html'}, 't']]], a.c_page_res('2'))
      # uum....
    end
  end
end
