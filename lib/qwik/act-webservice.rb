# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    D_PluginWebService = {
      :dt => 'Web service plugins',
      :dd => 'You can use several external Web services.',
      :dc => '
* Hatena Point plugin
 {{hatena_point(eto)}}
You can embed hatena point tag.
* Trackfeed plugin
You can use trackfeed by this plugin.
 {{trackfeed(yourid)}}
* Subscribe Bloglines plugin
You can show subscribe bloglines button.
 {{sub_bloglines}}
{{sub_bloglines}}

You can write a specific URL in the argument.
 {{sub_bloglines("http://www.ruby-lang.org/")}}
{{sub_bloglines("http://www.ruby-lang.org/")}}
* E Words plugin
You can show words description.
 {{e_words}}
{{e_words}}
* Google AdSense plugin
You can show an ad by Google AdSense.
 {{google_ad}}
{{google_ad}}
 {{google_ad_button}}
{{google_ad_button}}
You can select from the two sizes.
There is no way to use another size for now.
* Show translate link plugin
You can show an translation link.
 {{translate_ej}}
Specify translate English to Japanese link.
 {{translate_je}}
Specify translate Japanese to English link.
'
    }

    D_PluginWebService_ja = {
      :dt => 'Webサービス・プラグイン',
      :dd => 'Web上の各種サービスを利用するプラグインです。',
      :dc => '
* はてなポイント・プラグイン
 {{hatena_point(eto)}}
はてなポイント(投げ銭)のタグを埋込めます。
* Trackfeedプラグイン
トラックフィードを埋込めます。
 {{trackfeed(yourid)}}
* Bloglines講読プラグイン
Bloglinesで講読するリンクを表示します。
 {{sub_bloglines}}
{{sub_bloglines}}

特定のURLを指定することもできます。
 {{sub_bloglines("http://www.ruby-lang.org/")}}
{{sub_bloglines("http://www.ruby-lang.org/")}}
* E Wordsプラグイン
用語定義を表示させることができます。
 {{e_words}}
{{e_words}}
* Google AdSenseプラグイン
Google AdSenseを埋込めます。
 {{google_ad}}
{{google_ad}}
 {{google_ad_button}}
{{google_ad_button}}
二種類のサイズから選べます。
それ以外のサイズは、現在は未対応となっています。
* 翻訳プラグイン
翻訳ページに飛ぶリンクを表示します。
You can show an translation link.
 {{translate_ej}}
英語から日本語へ翻訳する。
 {{translate_je}}
日本語から英語へ翻訳する。
'
    }

    # ========== hatena point
    def plg_hatena_point(hatena_account)
      page = @site[@req.base]
      url = c_relative_to_absolute(page.url)
      rdf =[:'rdf:RDF',
	{:'xmlns:rdf'=>'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
	  :'xmlns:foaf'=>'http://xmlns.com/foaf/0.1/'},
	[:'rdf:Description',
	  {:'rdf:about'=>url},
	  [:'foaf:maker',
	    {:'rdf:parseType'=>'Resource'},
	    [:'foaf:holdsAccount',
	      [:'foaf:OnlineAccount',
		{:'foaf:accountName'=>hatena_account},
		[:'foaf:accountServiceHomepage',
		  {:'rdf:resource'=>'http://www.hatena.ne.jp/'}]]]]]]
      return [:span, {:class=>'hatena_point'}, rdf]
    end

    # ========== trackfeed
    def plg_trackfeed(id)
      return unless /\A[0-9a-f]+\z/ =~ id
      script = [:script, {:src=>"http://trackfeed.com/usr/#{id}.js"}, '']
      return script
    end

    # ========== Bloglines
    def plg_sub_bloglines(url=nil, icon='modern4')
      return unless /\A[a-z0-9]+\z/ =~ icon
      url = @site.site_url if url.nil?
      button = [:a, {:href=>"http://www.bloglines.com/sub/#{url}"},
	[:img, {:src=>"http://www.bloglines.com/images/sub_#{icon}.gif",
	    :border=>'0', :alt=>'subscribe Bloglines'}]]
      return button
    end

    # ========== E Words
    def plg_e_words
      return [:script, {:type=>'text/javascript',
	  :src=>'http://e-words.jp/embed.x'}, '']
    end

    # ========== Google AdSense
    def plg_google_ad(id=nil)
      id ||= 'pub-5746941487859743'
      str = <<'EOT'

google_ad_client = "#{id}";
google_alternate_color = 'eeeeee';
google_ad_width   = 120;
google_ad_height  = 240;
google_ad_format  = '120x240_as';
google_ad_channel ='2257701812';
google_ad_type = 'text_image';
google_color_border = 'ffffff';
google_color_bg   = 'ffffff';
google_color_link = '00cccc';
google_color_url  = '00cc66';
google_color_text = '000000';
EOT
      return google_ad(str)
    end

    def plg_google_ad_button(id=nil)
      id ||= 'pub-5746941487859743'
      str = <<'EOT'

google_ad_client = "#{id}";
google_alternate_color = 'eeeeee';
google_ad_width   = 125;
google_ad_height  = 125;
google_ad_format  = '125x125_as';
google_ad_channel ='2257701812';
google_ad_type = 'text_image';
google_color_border = 'ffffff';
google_color_bg   = 'ffffff';
google_color_link = '00cccc';
google_color_url  = '00cc66';
google_color_text = '000000';
EOT
      return google_ad(str)
    end

    def google_ad(str)
      str << '//'
      return [:div, {:style=>'text-align: center;'},
	[:script, {:type=>'text/javascript'}, [:'!--', str]],
	[:script, {:type=>'text/javascript',
	    :src=>'http://pagead2.googlesyndication.com/pagead/show_ads.js'},
	  '']]
    end

    # ========== Excite Translate
    def plg_translate_ej(msg=nil)
      return plg_translate('ej', msg)
    end

    def plg_translate_je(msg=nil)
      return plg_translate('je', msg)
    end

    def plg_translate(lang, message=nil)
      if lang == 'ej'
	lp = 'ENJA'
      elsif lang == 'je'
	lp = 'JAEN'
      else
	return nil
      end

      page = @site[@req.base]
      return if page.nil?
      full_url = c_relative_to_absolute(page.url)
     #base = 'http://www.excite.co.jp/world/english/web/'
      base = 'http://www.excite.co.jp/world/english/web/proceeding/'
      url = "#{base}?wb_lp=#{lp}&wb_url=#{full_url}"

      if message.nil?
	message = 'translate'
	if lang == 'ej'
	  message += ' (e->j)'
	elsif lang == 'je'
	  message += ' (j->e)'
	end
      end

      e = [:a, {:href=>url}, message]
      return e
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  require 'qwik/wabisabi-format-xml'
  $test = true
end

if defined?($test) && $test
  class TestActWebService < Test::Unit::TestCase
    include TestSession

    def test_plg_hatena_point
      t_add_user
      page = @site.create_new
      page.store('{{hatena_point(a)}}')
      res = session('/test/1.html')
      span = res.body.get_path("//span[@class='hatena_point']")
      rdf = span[2]
      ok_eq([:'rdf:RDF',
	      {:'xmlns:rdf'=>'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
		:'xmlns:foaf'=>'http://xmlns.com/foaf/0.1/'},
	      [:'rdf:Description',
		{:'rdf:about'=>'http://example.com/test/1.html'},
		[:'foaf:maker',
		  {:'rdf:parseType'=>'Resource'},
		  [:'foaf:holdsAccount',
		    [:'foaf:OnlineAccount',
		      {:'foaf:accountName'=>'a'},
		      [:'foaf:accountServiceHomepage',
			{:'rdf:resource'=>'http://www.hatena.ne.jp/'}]]]]]],
	    rdf)

=begin
<rdf:RDF
 xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
 xmlns:foaf='http://xmlns.com/foaf/0.1/'>
<rdf:Description 
 rdf:about="エントリーのPermalink あるいはウェブサイトのURL">
 <foaf:maker rdf:parseType='Resource'>
 <foaf:holdsAccount>
 <foaf:OnlineAccount 
 foaf:accountName="あなたのはてなアカウント名">
 <foaf:accountServiceHomepage 
	 rdf:resource='http://www.hatena.ne.jp/' />
 </foaf:OnlineAccount>
 </foaf:holdsAccount>
 </foaf:maker>
</rdf:Description>
</rdf:RDF>
=end
      str = rdf.rb_format_xml
      #puts str

      ok_eq(
"<rdf:RDF xmlns:foaf=\"http://xmlns.com/foaf/0.1/\" xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\"
><rdf:Description rdf:about=\"http://example.com/test/1.html\"
><foaf:maker rdf:parseType=\"Resource\"
><foaf:holdsAccount
><foaf:OnlineAccount foaf:accountName=\"a\"
><foaf:accountServiceHomepage rdf:resource=\"http://www.hatena.ne.jp/\"
/></foaf:OnlineAccount
></foaf:holdsAccount
></foaf:maker
></rdf:Description
></rdf:RDF
>",
	    str)
    end

    def test_trackfeed
      ok_wi([:script, {:src=>'http://trackfeed.com/usr/1.js'}, ''],
	    '{{trackfeed(1)}}')
    end

    def test_sub_bloglines
      ok_wi([:a, {:href=>'http://www.bloglines.com/sub/http://example.com/test/'}, [:img, {:src=>'http://www.bloglines.com/images/sub_modern4.gif', :border=>'0', :alt=>'subscribe Bloglines'}]], '{{sub_bloglines}}')
      ok_wi([:a, {:href=>'http://www.bloglines.com/sub/http://e.com/'}, [:img, {:src=>'http://www.bloglines.com/images/sub_modern4.gif', :border=>'0', :alt=>'subscribe Bloglines'}]], '{{sub_bloglines(http://e.com/)}}')
      ok_wi([:a, {:href=>'http://www.bloglines.com/sub/http://e.com/'}, [:img, {:src=>'http://www.bloglines.com/images/sub_modern3.gif', :border=>'0', :alt=>'subscribe Bloglines'}]], '{{sub_bloglines(http://e.com/,modern3)}}')
    end

    def test_e_words
      ok_wi([:script, {:src=>'http://e-words.jp/embed.x',
		:type=>'text/javascript'}, ''], '{{e_words}}')
    end

    def test_google_ad
      t_add_user
      page = @site.create_new
      page.store('{{google_ad}}')
      res = session('/test/1.html')
      ok_wi(/pagead2.googlesyndication.com/, '{{google_ad}}')
    end

    def test_translate
      ok_wi([:a, {:href=>'http://www.excite.co.jp/world/english/web/proceeding/?wb_lp=JAEN&wb_url=http://example.com/test/1.html'}, 'translate (j->e)'],
	    '{{translate_je}}')
      ok_wi([:a, {:href=>'http://www.excite.co.jp/world/english/web/proceeding/?wb_lp=JAEN&wb_url=http://example.com/test/1.html'}, 'English'],
	    '{{translate_je(English)}}')
      ok_wi([:a, {:href=>'http://www.excite.co.jp/world/english/web/proceeding/?wb_lp=ENJA&wb_url=http://example.com/test/1.html'}, 'translate (e->j)'],
	    '{{translate_ej}}')
    end
  end
end
