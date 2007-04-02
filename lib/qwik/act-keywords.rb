# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

begin
  require 'MeCab'
  $have_mecab = true
rescue LoadError
  $have_mecab = false
end

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    D_PluginKeywords = {
      :dt => 'Show keywords plugin',
      :dd => 'You can see the list of keywords of the page.',
      :dc => "* Example
You see the keyword list of FrontPage.
 {{keywords}}
{{keywords}}
You see the keyword list of TextFormat.
 {{keywords(TextFormat)}}
{{keywords(TextFormat)}}

\'\'\'Warning:\'\'\' This plugin works only for Japanese document.
"
    }

    D_PluginKeywords_ja = {
      :dt => 'キーワード表示プラグイン',
      :dd => 'ページ内のキーワードの一覧が表示されます。',
      :dc => "* 例
FrontPageのキーワード一覧が表示されます。
 {{keywords}}
{{keywords}}
TextFormatページの一覧が表示されます。
 {{keywords(TextFormat)}}
{{keywords(TextFormat)}}
"
    }

    CLOUD_BASE_FONT_SIZE = 12
    CLOUD_MAX_FONT_SIZE = 40

    def plg_keywords(pagename=@req.base)
      return "no mecab" if ! $have_mecab

      page = @site[pagename]
      return if page.nil?

      content = page.get

      nodes = Action.nodes_get(content)

      hash = Hash.new { 0 }
      nodes.each {|surface, feature|
	hash[surface] += 1
      }
      w = hash.keys.sort.map {|surface|
	num = Math.sqrt(hash[surface]) * CLOUD_BASE_FONT_SIZE
	num = CLOUD_MAX_FONT_SIZE if CLOUD_MAX_FONT_SIZE < num
	fontsize = "%.2fpx" % num
	href = "#{surface.escape}.search"
	[:a, {:style=>"font-size:#{fontsize};",
	    :href=>href}, surface]
      }
      return [:div, {:class=>'keywords'}, *w]
    end

    PATTERN_SJIS = '[\x81-\x9f\xe0-\xef][\x40-\x7e\x80-\xfc]'
    PATTERN_EUC = '[\xa1-\xfe][\xa1-\xfe]'
    RE_SJIS = Regexp.new(PATTERN_SJIS, 0, 'n')
    RE_EUC = Regexp.new(PATTERN_EUC, 0, 'n')

    HIRAGANA = "[ぁ-んー～]"
    KANJI = "[亜-瑤]"

    def self.nodes_get(content)
      content.set_sjis
      euc_content = content.to_euc
      tagger = MeCab::Tagger.new([$0])
      n = tagger.parseToNode(euc_content)
      nodes = []
      while n.hasNode != 0
	surface = n.getSurface.set_euc.to_sjis
	feature = n.getFeature.set_euc.to_sjis
	if ! surface.empty? &&
	    RE_SJIS =~ surface &&
	    /\A([ぁ-んー～]+)\z/s !~ surface &&
	    /\A[．-→、。]/s !~ surface &&
	    /\A[，←]/s !~ surface
#	    /\A[　０-９→「」（）、。]/s !~ surface
	  nodes << [surface, feature]
	end
	n = n.next
      end
      return nodes
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
      $KCODE = 's'
end

if defined?($test) && $test
  class TestAction < Test::Unit::TestCase
    include TestSession

    def test_keywords
      c = Qwik::Action
#      eq ["あ"], c.nodes_get("あ")
#      eq ["これ", "は", "テスト", "です", "。"],
#	c.nodes_get("これはテストです。")
#      eq ["今日", "も", "し", "ない", "と", "ね"],
#	c.nodes_get("今日もしないとね")
#      eq ["太郎", "は", "この", "本", "を", "二郎", "を", "見", "た",
#	"女性", "に", "渡し", "た", "。"],
#	c.nodes_get("太郎はこの本を二郎を見た女性に渡した。")
    end

    def test_plg_keywords
      return unless $have_mecab

      page = @site.create('2')
      page.store("字")

      ok_wi [:div, {:class=>"keywords"},
	[:a, {:style=>"font-size:12.00px;", :href=>"%8E%9A.search"}, "字"]],
	"{{keywords(2)}}"
    end
  end
end
