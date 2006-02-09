#
# Copyright (C) 2003-2006 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

module Qwik
  class Action
    Dja_album = {
      :dt => 'アルバム・プラグイン',
      :dd => '添付された画像ファイルを一度に見ることができます。',
      :dc => '* 例
 {{album}}
{{album}}

これは説明画面のため、ここにはアルバムは表示されません。

* 感謝
神原 啓介氏による「なめらかアルバム」機能を使用しております。
感謝いたします。
' }

    Dja_calc = {
      :dt => '計算プラグイン',
      :dd => '簡単な表計算を行うことができます。',
      :dc => "* 例
 {{calc
 ,$100	,CPU
 ,$100	,Memory
 ,$20.5	,Cable
 ,$250	,Graphic Card
 ,$250	,HDD
 ,$400	,Mother Board
 }}
{{calc
,$100	,CPU
,$100	,Memory
,$20.5	,Cable
,$250	,Graphic Card
,$250	,HDD
,$400	,Mother Board
}}
"
    }

    Dja_code = {
      :dt => 'コード・プラグイン',
      :dd => 'ページ中にコードをうめこむときに使えます。',
      :dc => "* 例

 {{code
 puts \"hello, world!\"
 puts \"hello, qwik users!\"
 }}
{{code
puts \"hello, world!\"
puts \"hello, qwik users!\"
}}

{{code
\#include <stdio.h>

void main(){
  printf(\"hello, world!\\n\");
}
}}
" }

    Dja_comment = {
      :dt => 'コメントプラグイン',
      :dd => 'コメント入力欄を表示します。',
      :dc => "
* 複数行コメントプラグイン
{{mcomment}}
 {{mcomment}}
複数行のコメントプラグインです。
 {{mcomment(1)}}
このように、(1)をつけると、新しいコメントが一番上につくようになります。
* Hiki風コメントプラグイン
{{hcomment}}
 {{hcomment}}
Hikiのコメントプラグインとほぼ同じ使い方です。
* 旧コメントプラグイン
{{comment}}
 {{comment}}
古い仕様のコメントプラグインです。
代りに、「mcomment」プラグインをお使いください。
" }

    Dja_describe = {
      :dt => '機能説明',
      :dd => 'qwikWebの機能説明を見ることができます。',
      :dc => '* 例
 [[isbn.describe]]
[[isbn.describe]]

機能説明の一覧は、この下についてきます。
'
    }

    Dja_embed_html = {
      :dt => 'html埋め込み機能 ',
      :dd => 'htmlをそのままはりこむことができます。',
      :dc => "* 例
 <html>
 s<sup>5</sup>
 </html>
<html>
s<sup>5</sup>
</html>
こんな感じ。
任意のタグが使えるわけではなく，使える要素は限られています．

<html>
<H3>見出し2</H3>
<H4>見出し3</H4>
<H5>見出し4</H5>
<H6>見出し5</H6>
<UL>
<LI>箇条書レベル1
<UL>
<LI>箇条書レベル2
<UL>
<LI>箇条書レベル3</LI></UL></LI></UL></LI></UL>
<OL>
<LI>順序リスト1
<OL>
<LI>順序リスト2
<OL>
<LI>順序リスト3</LI></OL></LI></OL></LI></OL><PRE>整形済みテキスト。</PRE>
<BLOCKQUOTE>
<P>引用。</P></BLOCKQUOTE>
<DL>
<DT>Wiki
<DD>書き込み可能なWebページ
<DT>QuickML
<DD>簡単に作れるメーリングリストシステム</DD></DL>
<TABLE>
<TBODY>
<TR>
<TD>項目1-1</TD>
<TD>項目1-2</TD>
<TD>項目1-3</TD></TR>
<TR>
<TD>項目2-1</TD>
<TD>項目2-2</TD>
<TD>項目2-3</TD></TR></TBODY></TABLE>
<P><EM>強調</EM>、<STRONG>さらに強調</STRONG>、<DEL>取り消し線</DEL> <A href=\"http://qwik.jp/.theme/new.png\">new</A> <A href=\"FrontPage.html\">FrontPage</A> <A href=\"http://www.yahoo.co.jp/\">Yahoo!</A></P>

<PLUGIN param=\"1\" method=\"recent\"></PLUGIN>
</html>

プラグインの指定方法が、ここだけ特殊ですね。
また、htmlプラグインの中では使えないプラグインもあります。
"
    }

    Dja_files = {
      :dt => 'ファイル添付機能 ',
      :dd => 'ページにファイルを添付できます。',
      :dc => '
* ページへのファイル添付
まず編集画面に行きます。
ページの一番下に、ファイル添付のためのフォームがあります。
「たくさん添付する」というリンクをたどると、たくさんのファイルを一度に
添付するためのフォーム画面にとびます。

添付をすると、ページの一番下に自動的にその添付ファイルへのリンクがつきます。
 {{file(\"somefile.txt\")}}
そのようにして、そのページから添付ファイルへアクセスできるようになります。

* ファイル一覧プラグイン
 {{show_files}}
ファイル一覧を表\示できます。
' }

    Dja_menu = {
      :dt => 'メニュープラグイン',
      :dd => 'プルダウン型メニューを作れます。',
      :dc => "* 例
{{hmenu
- [[Yahoo!|http://www.yahoo.co.jp/]]
-- [[map|http://map.yahoo.co.jp/]]
-- [[auctions|http://aunctions.yahoo.co.jp/]]
- [[Google|http://www.google.co.jp/]]
-- [[news|http://news.google.com/]]
-- [[map|http://map.google.com/]]
- [[qwik|http://qwik.jp/]]
-- [[hello|http://qwik.jp/HelloQwik/]]
}}

{{br}}
{{br}}
{{br}}
{{br}}
" }

    Dja_presen = {
      :dt => 'プレゼン・モード',
      :dd => 'プレゼン・モードで表示します。',
      :dc => '* 例
 [[FrontPage.presen]]
[[FrontPage.presen]]

このリンクをたどると、FrontPageをプレゼンモードで表示します。
 {{presen}}
そのページ自身をプレゼンモードにするリンクを表示したい場合は、
このプラグインをご利用下さい。
** プレゼンテーマ指定
 {{presen_theme(qwikblack)}}
このようにして、プレゼンテーマを指定できます。
* 感謝
プレゼンモードには、Eric Meyer氏によるs5を使用しております。感謝いたします。
' }

    Dja_qwikweb = {
      :dt => 'qwikWeb機能一覧',
      :dd => 'qwikWebの機能一覧です。',
      :dc => '
* 使い方
下記に、qwikWebの機能一覧を示します。
'
=begin
# :[[textformat.describe]]:書式一覧です。
# * 基本機能
# :[[FromMailingList]]:メーリングリストに送られたメールは、Subjectによって一ページにまとまります。
# :[[MailSuffix]]:メールの最後に、メールに対応するURLが付記されます。
# :[[AttachedImage]]:添付ファイルも適切に処理されます。画像以外の添付ファイルは、アイコンとして表示されます。
# * 見た目を変える
# :[[embed_html.describe]]:HTMLコードを直接そのままかくこともできます。
# :[[code.describe]]:プログラムのソースコードをはりたいときに。
# :[[aa.describe]]:アスキーアートをかきたいときに。
# * 様々なプラグイン
# :[[search.describe]]:検索機能もついてます。
# :[[files.describe]]:ページへのファイル添付機能。
# :[[include.describe]]:他のページのとりこみ。
# :[[comment.describe]]:コメントをつけられます。
# :[[calc.describe]]:簡単な表計算ができます。
# :[[ActSecurity]]:セキュリティにも気を配ってます。
# * 拡張されたWikiWikiWeb
# :[[wema.describe]]:ページに附箋をはることができます。
# :[[smil.describe]]:Webブラウザから、みんなでよってたかって一つの動画像を編集できる仕組みです。
# :[[編集履歴の参照|FrontPage.history]]:過去の履歴をインタラクティブに参照できます。
# * 使い方
# :[[qwikweb_howto_mobile.describe]]:携帯電話からの利用方法です。
# * インストール方法
# :[[qwikweb_config_httpd.describe]]:httpdの設定方法です。
# * qwikWebの開発に参加する
# :[[qwikweb_howto_plugin.describe]]:プラグインの作り方です。
# :[[ActException]]:デバッグもしやすくなってます。
# :[[sample.describe]]:自分でプラグインを作るのも簡単。
# * 利用例
# :[[Schedule]]:スケジュール調整に使ってみたり。
# :[[Class0106]]:授業記録として使ってみたり。
# :[[PresenInteraction2005]]:プレゼンで使ってみたり。
# * obsolete
# 今は使われなくなったが、様々な事情からまだ残っているプラグインです。
# 使わないでください。
# :[[ActComment]]:コメントをつけられます。
=end
    }

    Dja_qwikweb_plugins = {
      :dt => 'qwikWebプラグイン一覧',
      :dd => 'qwikWebのプラグイン一覧です。',
      :dc => '
* プラグイン
* プラグイン一覧
qwikWebの様々なプラグインを一覧します。

[[qwikWebFunctions]]もご覧ください。

* [[ActSchedule]]
簡単に日付と名前による表を作ることができて、
その表に○×をうめていくことができます。
スケジュール調整をするときに使えます。

# * [[table.describe]]
# テーブルをその場で編集することができます。

* [[ActPlan]]
予定表を作ることができます。

# * [[menu.describe]]
# 手軽にプルダウン型のメニューを作れます。

* [[ActMap]]
地図をうめこむことができます。

# * [[comment.describe]]
# 複数行書けるコメントプラグインです。

* [[ActCounter]]
カウンタープラグインです。

* [[ActHatenaPoint]]
はてなのアカウントを埋め込むことができます。

* [[ActSmil]]
ページにて、どのようにヴィデオを表示するかを指定することができます。

* [[ActInclude]]
他のページを取り込みます。

* [[ActHtml]]
HTMLプラグインを使うと、HTMLを直接埋め込めます。
しかし、使えるタグや要素には限られています。
'
    }

    Dja_qwikweb_install = {
      :dt => 'qwikWebのインストール方法',
      :dd => 'qwikWebのインストール方法です。',
      :dc => "
\'\'草稿です。\'\'

* 入手
- ダウンロードしてきてください。
- 解凍してください。

qwikWebと同じパッケージに、QuickMLのコードも含まれています。
そのためQuikMLを別途ダウンロードする必要はありません。
"
    }

    Dja_qwikweb_config = {
      :dt => 'qwikWebの設定方法',
      :dd => 'qwikWebの設定方法です。',
      :dc => "
\'\'草稿です。\'\'

* qwikWebの設定ファイル
qwikWebを実際に運用するためには、
下記のファイルを変更する必要があります。
- etc/config.txt

それぞれ、qwikWebの設定ファイル、QuickMLの設定ファイルです。

* qwikWebの設定
- etc/config.txt
qwikWebにおけるWiki部分の設定ファイルです。
エディタで etc/config.txt を開いてください。

「:」でわけられて記述されています。
それぞれの行が設定項目です。
ホスト名は必須です。

** Apacheとの共存
qwikWebは、標準ではWEBrickを使用し、ポート9190にてhttpdとして動きます。
そのため、
- http://localhost:9190/
にアクセスすると、qwikWebにそのままつながるはずです。

しかし、ポート80ではすでにApacheが動いており、その上で、
- http://localhost/wiki/
といったアドレスで運用したいこともあると思います。
その場合はApacheをリバスプロキシとして利用して、localhostのポート9190に
接続するという使い方になります。詳しい設定方法は、
[[qwikweb_config_httpd]]をご覧下さい。

* QuickMLの設定
- etc/config.txt
このファイルをエディタで開いてください。
設定を書き換えます。
"
    }

    Dja_qwikweb_config_httpd = {
      :dt => 'qwikWebにおけるhttpdの設定方法',
      :dd => 'qwikWebをインストールする際の、Apacheなどのhttpdの設定方法です。',
      :dc => '
* Apache下での利用
Port 80でApacheが動いている場合の設定方法です。すでにAapcheがポートを利用しているのでmod_proxy内の
機能であるリバースプロキシを利用してqwikで標準で使用しているPort 9190をPort 80にをリダイレクトします。

リバースプロキシに関しては以下の説明をご覧ください
-[[リバースプロキシとは IT用語辞典 e-Words|http://e-words.jp/w/E383AAE38390E383BCE382B9E38397E383ADE382ADE382B7.html]]
-[[フォワードプロキシとリバースプロキシ Apache HTTP サーバ|http://cvs.apache.jp/svn/httpd-docs/2.1/manual/mod/mod_proxy.html.ja.euc-jp#forwardreverse]]
例えば、www.example.comというマシンを管理していて、
http://www.example.com/ というURLにqwikWebを立ち上げたいと仮定します。

*Apache1.3の場合
エディタでhttpd.confを開きます。
*Proxy moduleを使えるようにする
/etc/apache/httpd.conf に変更を加え、Proxy moduleを有効にします。
 LoadModule proxy_module /usr/lib/apache/1.3/libproxy.so

*VirtualHostの設定
httpd.conf最後に以下の記述を足します。
 <VirtualHost www.example.com>
     ProxyPass	/	http://127.0.0.1:9190/
 </VirtualHost>
このようにすればOKです。
(このProxyPassを使った手法は、高林哲氏に教えていただきました。)

*他のディレクトリにqwikを設置したい場合
もし http://www.example.com/qwik/ というURLにしたい場合、http.confを以下のようにします。
 <VirtualHost www.example.com>
     ProxyPass	/.theme/	http://127.0.0.1:9190/.theme/
     ProxyPass	/qwik/	http://127.0.0.1:9190/
 </VirtualHost>
以上のようすることでhttp://www.example.com/qwik/でアクセスすることができます。
*Apache2の場合

*a2enmodでProxyモジュールを追加
Apache2の場合moduleの追加は\'\'a2enmod\'\'というコマンドを使います。このコマンドを
使いProxyモジュールを追加します。
 # a2enmod proxy
 Module proxy installed; run /etc/init.d/apache2 force-reload to enable.

*a2enmodでVirtualHostを有効に
同じくa2enmodでVirtualHostを有効にします
 # a2enmod proxy
 Module vhost_alias installed; run /etc/init.d/apache2 force-reload to enable.
これでApache2でVirtualHostディレクティブの設定が有効になります。
*mods-enabled以下にあるproxy.confを編集
proxyモジュールを追加するとapacheのmods-enabled/以下にproxy.conf,proxy.loadが追加されます。
Debianの場合、proxy.confは/etc/apache2/mods-enabled/以下においてあります。

エディタでproxy.confを開きます。以下のように記述をかきかえます。
{{{

<IfModule mod_proxy.c>

 ProxyRequests Off

 <Proxy *>
     Order deny,allow
     Allow from all
 </Proxy>

 <VirtualHost www.example.com>
     ProxyPass	/	http://127.0.0.1:9190/
 </VirtualHost>

</IfModule>

}}}
以上のように記述したらapacheを再起動させます。
*mod_proxyの詳細
mod_proxyに関する詳細は以下を参照してください
-[[mod_proxy - Apache HTTP サーバ|http://cvs.apache.jp/svn/httpd-docs/2.1/manual/mod/mod_proxy.html.ja.euc-jp]]
'
    }

    Dja_qwikweb_howto_mobile = {
      :dt => '携帯電話からの使い方',
      :dd => 'qwikWebは、携帯電話からでも使えます。',
      :dc => "
* 携帯電話

携帯電話からの利用もできますが、いろいろと制限があります。

* ドコモの場合

** iモード

ログイン画面にて、「携帯電話の方はこちら」というリンクがあります。ここ
からHTTP認証によるログインをすることができます。まずログインする前に、
パスワードを入手し、それを紙などにメモしておく必要があります。

パスワードが送られてくるメールには、「こちらのリンクを辿ると自動的にロ
グインします」というリンクがありますが、iモードではcookieが使えないた
め、そのリンクを辿ってもログインしませんので、御注意下さい。

** jigブラウザ

iアプリを使ったブラウザとして、jigブラウザがあります。

- http://jig.jp/

このjigブラウザはcookieに対応しているため、これを使えば普通にログイン
できます。まずさきほどと同様にパスワードをメモしておきます。次にjigブ
ラウザを立ち上げてから、ログイン画面からユーザ名とパスワードを入力しま
す。

* 他の会社

WINの携帯では、cookieに対応しているため、普通にログインできることを確
認しています。それ以外の会社につきましては、未確認です。

もし動作を確認されましたら、ぜひご連絡下さい。
→ info at qwik.jp
"
    }

    Dja_qwikweb_howto_plugin = {
      :dt => 'プラグインの作り方',
      :dd => 'qwikWebにおけるプラグインの作り方です。',
      :dc => '
* プラグインの作り方

この文章は，書きかけです．

qwikWebのプラグインがどのような仕組みでできているかを説明する。
(qwikWebのinstall方法は省略。とりあえず、普通に起動するところまで動か
してください。)

* act-sample.rb

lib/qwik/act-sample.rb というコードが、サンプルコードである。

{{code
module Qwik
  class Action
    def plg_hello
      [:strong, \"hello, world!\"]
    end

    def act_hello
      c_ok(\"hello, world!\"){\"hi, there.\"}
    end
  end
end
}}

このようなコードになっている。これが、それぞれプラグインとアクションの基本形となっている。

{{code
    def plg_hello
      [:strong, \"hello, world!\"]
    end
}}

このmethod定義によって、helloというプラグインを定義している。

 {{hello}}
{{hello}}

このように、Qwik::Actionというクラスにおいて、メソッド名の先頭に
\'\'plg_\'\'とついてものがプラグインとして機能する。

* わびさび方式

メソッドの中には配列が書かれているだけだが、これでHTMLをあらわしている。
 [:strong, \"hello, world!\"]
この指定は、下記のHTMLと同じ意味である。
 <strong>hello, world!</strong>

配列の先頭がシンボルだった場合は、そのシンボルによるタグ名でかこまれた
HTMLであるとしてあつかわれる。この配列によるHTML表記方式は高林哲氏が考
えたもので、「わびさび方式」と呼んでいる。

この表記方法にはたくさん利点がある。
- 終了タグを記載する必要がない。
- 常に自動的にsanitizeされる。sanitizeしたりしなかったりを気にする必要が無い。
- 単なる配列なので、後から変形させるのが容易。

欠点もある。
- 遅い。

最終的にXMLとして生成するのに若干時間がかかる。
この欠点をおぎなうために、西田氏によるCによるextがある。

「わびさび方式」に関連する内容として、高林氏の日記を参照してください。
-[[わびさび HTML 生成でサニタイズを確実に : いやな日記|http://namazu.org/~satoru/diary/20040824.html#p01]]

* アクション

* act-sample2.rb
# 重要なのは最初の3つのmethodである。

* プラグイン
まずは一つ目のmethod。
    def plg_tt(text)
      [:tt, text]
    end

これは、ttというプラグインを定義している。

 test {{tt(test)}} test
test {{tt(test)}} test

このように、真ん中のtestだけ等幅で表示される。つまり、真ん中のtestだけ、
<tt>というタグで囲まれて表示している。[:tt,text] という表記によって、
\"<tt>\#{text}</tt>\"と表記するのと同じ記述をしているわけだ。これがプラグ
インの最も基本的な形である。

* ブロックレベル・プラグイン

二つ目のmethod、これはquoteというプラグインを定義している。

    def plg_quote
      text = yield
      ar = []
      text.each {|line|
	ar << line
	ar << [:br]
      }
      [:blockquote,
	[:p, {:style=>\"font-size:smaller;\"}, *ar]]
    end

quoteプラグインは、先程と違い、ブロックレベル・プラグインである。

 {{quote
 一行目
 二行目
 }}
{{quote
一行目
二行目
}}

このように複数行の入力をとる。最初の text = yield で、プラグインに囲ま
れた文字列を取得する。その後、一行づつに分解し、<br/>をお尻につけなが
ら、追加しているそして最後にblockquoteタグとpタグで囲んでいる。ついで
にstyleも指定している。attributeはこのように、Hashで指定する。

qwikWebではこのように、xmlをArrayやHashなどだけの集合で指定している。
これは高林哲氏による「わびさび方式」をそのまま借りてきたものである。

* アクション

ここまでの二つはいわゆるプラグインであり、文中に埋め込んで使うものだっ
た。次に、アクションについて説明する。

    def act_hello
      c_ok(\"hello, world\"){\"hi, there.\"}
    end

これがアクション。

 http://127.0.0.1:9190/.hello

このURLにアクセスすると、なにかメッセージページがでてくる。タイトルが
hello, メッセージがhi, thereとでる。このようにドットで始まるURLは、
act_helloというメソッドの呼び出しに対応している。メソッドの中で実行さ
れた結果が、ページとして返ってくる。

実はqwikWebでは、通常のページ表示や編集画面も、全てこのアクションとい
う仕組みで作られている。FrontPage.htmlというURLは、FrontPageというペー
ジに対してhtmlというアクションを実行せよという意味になる。そこで、
FrontPageというページから文字列を読み込み、htmlに変換して出力している
というわけである。(本当はもうちょっと複雑なんだけどね。)
FrontPage.editは、FrontPageの編集画面を表示せよ、という意味になる。
qwikWebは、このようなアクションの連鎖だけで全ての処理を実現している。

* テストコード

コードの後半は何をやっているかというと、テストコードになっている。

      assert_wiki([:tt, \'t\'], \'{{tt(t)}}\')

例えばこのコードは、Wiki記法として｛｛tt(t)｝｝という風に記述すると、
その部分は結果的にこのようなhtmlへと変換される、ということをテストして
いる。

アクションも同様にテストしている。

      res = session(\'/test/.hello\')
      ok_title(\'hello, world\')

これは、.helloというアクションにアクセスして、そこで生成されたページか
らtitleというタグをもってくると、その中身はhello, worldというテキスト
になっている、ということをテストしている。assert_tagは、\'title\'という
タグを探してきて、その中のテキストを取得し、比較するというassertなわけ
だ。

titleタグであれば文中で一つしかないためこの方式で問題ないが、
通常はタグはたくさんあって、それをうまく指定するのは難しい。
そこで、XPathを使ってタグを指定する仕組みも用意している。

assert_xpathでは、XPathを使って検査したい部分を指定し、
その中身をわびさび方式のArrayと比較する。

このような仕組みを用意することによって、テストを自動化することに
成功している。

* 自動再読み込み

デバッグモード、-dオプション付きでqwikWebを起動すると、ファイルの自動
再読み込み機能がオンになる。この状態で任意のコードを編集し、セーブする
と、即座にそのファイルが再読み込みされ、そのコードが有効となる。(正確
には、一秒に一回チェックしている。ファイルが更新されてたら読むという動
作をしている。)

例えば、qwikwebを起動している最中に、先程のttタグのところを、例えば
bタグに変える。そうすると、コマンドラインに、reloadをしたというメッセー
ジが表示される。

 reload: \"/cygdrive/c/qwik/lib/qwik/act-sample.rb\"

それからブラウザでリロードすると、先程まではttタグだったところがbタグ
に変わっているのがわかるはずだ。

このようにサーバを再起動しなくてもコードの変更を反映させられるような仕
組みにしている。これによって、サーバを動作させながらプログラムを更新し
ていくことができる。

** 自分で作ってみる

自分自身のプラグインやアクションを作りたい場合は、最初は試しに
act-sample.rbを書き換えながらリロードしていくのがいいだろう。

自分なりのファイルがまとまったら、lib/qwikというdirectoryに、act-から
始まるファイルを作って置けばよい。qwikWebは、自動的にact-から始まるファ
イルをロードする。

Happy Hacking!
'
    }

    Dja_table = {
      :dt => 'テーブル編集プラグイン',
      :dd => 'ページ中でテーブルを編集できます。',
      :dc => "* 例
 {{table}}
{{table}}

ここに5x5のテーブルが見えます。
それぞれの項目は入力フィールドになっており、書き換えられます。
最後に「更新」を押すと、それらの入力が反映されます。

この画面は説明用の画面なので、編集できません。
" }

    Dja_sample = {
      :dt => 'サンプル・プラグイン',
      :dd => 'プラグインのサンプルです。',
      :dc => '
実装における参考として提供しているものです。

このプラグインは実装方法を知るための
サンプルとして提供しているものです。このプラグインを元に、
みなさま自由に自分なりのプラグインを作ってみてください。

詳しくは、こちらのURLをごらんください。
http://qwik.jp/HowToMakePlugin.html

* 例
** ハローワールド・プラグイン
{{hello}}
 {{hello}}
有名な「hello, world!」を画面に表示させることができます。
{{hello(\"qwik users\")}}
 {{hello(\"qwik users\")}}
引数をとることもできます。

** ハローワールド・アクション
[[.hello]]
 [[.hello]]
「hello, world!」と表示されます。

** 等幅プラグイン
{{tt(\"This is a test.\")}}
 {{tt(\"This is a test.\")}}
等幅を指定します。

** 引用プラグイン
{{quote
This is a text to quote.
}}
 {{quote
 This is a text to quote.
 }}
引用できます。
' }

    Dja_search = {
      :dt => '検索プラグイン',
      :dd => '検索窓を作れます。',
      :dc => "* 例
 {{search}}
{{search}}
" }

    Dja_typekey = {
      :dt => 'TypeKeyによるログイン',
      :dd => 'TypeKey認証でログインすることができます。',
      :dc => "* 使い方

ログイン画面にて、ユーザ名、パスワードを入力するフィールドの下に
「TypeKeyでログインする」というリンクがあります。
そのリンクをたどると、TypeKeyによる認証画面にとびます。
その画面からログインしてください。
実際にはTypeKeyでのアカウント名ではなく、
メールアドレスによって認証するため、
メールアドレスを通知する必要があります。
また、そのメールアドレスが、そのグループに登録されている
メールアドレスと一致している必要があります。
" }

    Dja_chronology = {
      :dt => '年表機能 ',
      :dd => "サイトのページがいつ作成され、編集されてきたのかを一覧できます。",
      :dc => '* 使い方
 [[.time_walker]]
[[.time_walker]]

このリンクをたどると年表が表示さます。
' }

    Dja_wysiwyg = {
      :dt => '見たまま編集モード ',
      :dd => 'ページを見たままの状態で編集できます。',
      :dc => "* 例
たとえば、[[edit FrontPage|FrontPage.wysiwyg]]からFrontPageを見たままの状態で編集する画面にとびます。

そのページから見たまま編集画面に飛ぶには、下記のプラグインを使います。
 {{wysiwyg}}
{{wysiwyg}}
" }

    Dja_textformat_simple = {
      :dt => '書式一覧',
      :dd => 'qwikWebの書式一覧簡略版です。',
      :dc => '* 書式一覧
詳細な説明は[[textformat.describeTextFormat]]をごらんください。
** 見出し2
*** 見出し3
**** 見出し4
***** 見出し5
- 箇条書レベル1
-- 箇条書レベル2
--- 箇条書レベル3
+ 順序リスト1
++ 順序リスト2
+++ 順序リスト3
 整形済みテキスト。
> 引用。
:Wiki:書き込み可能なWebページ
:QuickML:簡単に作れるメーリングリストシステム
,項目1-1,項目1-2,項目1-3
,項目2-1,項目2-2,項目2-3
\'\'強調\'\'、\'\'\'さらに強調\'\'\'、==取り消し線==
[[new|http://qwik.jp/.theme/new.png]]
[[FrontPage]]
[[Yahoo!|http://www.yahoo.co.jp/]]
{{recent(1)}}

{{{
** 見出し2
*** 見出し3
**** 見出し4
***** 見出し5
- 箇条書レベル1
-- 箇条書レベル2
--- 箇条書レベル3
+ 順序リスト1
++ 順序リスト2
+++ 順序リスト3
 整形済みテキスト。
> 引用。
:Wiki:書き込み可能なWebページ
:QuickML:簡単に作れるメーリングリストシステム
,項目1-1,項目1-2,項目1-3
,項目2-1,項目2-2,項目2-3
\'\'強調\'\'、\'\'\'さらに強調\'\'\'、==取り消し線==
[[new|http://qwik.jp/.theme/new.png]]
[[FrontPage]]
[[Yahoo!|http://www.yahoo.co.jp/]]
{{recent(1)}}
}}}
'
    }

    Dja_textformat = {
      :dt => '書式一覧詳細版',
      :dd => 'qwikWebの書式一覧です。',
      :dc => '* 書式一覧
簡略化した説明は[[textformat_simple.describe]]をご覧下さい。
* 見出し
- 「*」を行の先頭に書くと見出しになります。
- 「*」は1つから5つまで記述することができます。
それぞれ<H2>～<H6>に変換されます。
 * 見出し1
 ** 見出し2
 *** 見出し3
 **** 見出し4
 ***** 見出し5
* 見出し1
** 見出し2
*** 見出し3
**** 見出し4
***** 見出し5
* ページタイトル
ページの一番最初の行に「*」を一つで見出しを書くと、その見出しはページ
タイトルとして機能します。他のページからは、そのページタイトルを使って
リンクすることができます。
- [[TextFormat]]をご覧下さい。
- [[書式一覧詳細版]]をご覧下さい。
 - [[TextFormat]]をご覧下さい。
 - [[書式一覧詳細版]]をご覧下さい。
というように、同じ一つのページへのリンクにおいて、ページIDによるリンク
と、ページタイトルによるリンクを選ぶことができます。

前者のページIDを使ったリンクの場合、そのページのページタイトルが変更さ
れた場合、自動的にそのタイトルが反映されます。しかし、後者のページタイ
トルでリンクした場合、リンク先のページタイトルが変更された場合、リンク
切れになってしまいます。そのため、通常はページIDを用いたリンク方法をお
勧めします。

* 箇条書き
- 「-」を行の先頭に書くと箇条書きになります。
- 「-」は１つから３つまで記述することが可能で入れ子にすることもできます。
- 「+」を行の先頭に書くと番号付きの箇条書きになります。
 - 箇条書レベル1
 -- 箇条書レベル2
 --- 箇条書レベル3
 + 順序リスト1
 ++ 順序リスト2
 +++ 順序リスト3
- 箇条書レベル1
-- 箇条書レベル2
--- 箇条書レベル3
+ 順序リスト1
++ 順序リスト2
+++ 順序リスト3
* パラグラフ
- 連続した複数行は連結されて1つのパラグラフになります。
- 空行(改行のみ、またはスペース、タブだけの行)はパラグラフの区切りになります。
 例えば、
 こういう風に記述すると、これらの行は
 1つのパラグラフとして整形されます。
例えば、
こういう風に記述すると、これらの行は
1つのパラグラフとして整形されます。
* 水平線
- 「=」を行の先頭から4つ書くと水平線(区切り線)になります。
 この文章と、
 ====
 この文章は、区切られています。
この文章と、
====
この文章は、区切られています。
* 整形済みテキスト
- 行の先頭がスペースまたはタブで始まっていると、その行は整形済みとして扱われます。
 これは、
 整形済み
 テキストです。
大量の整形済みテキストを表示したい場合は「{{{」と「}}}」で囲みます。こんな感じです。
{{{
void main()
{
    printf(\"hello, world\\n\");
}
}}}
* 引用
「>」を行の先頭から書くと引用になります。
 > これは引用です。
> これは引用です。
* 用語解説
コロン「:」を行の先頭に書き、続けて用語:解説文とすると用語解説になります。
 :Wiki:書き込み可能なWebページ
 :QuickML:簡単に作れるメーリングリストシステム
:Wiki:書き込み可能なWebページ
:QuickML:簡単に作れるメーリングリストシステム
* 表
表(テーブル)は「,」または「|」で始め、コラム毎にその記号で区切ります。
 ,項目1-1,項目1-2,項目1-3
 ,項目2-1,項目2-2,項目2-3
,項目1-1,項目1-2,項目1-3
,項目2-1,項目2-2,項目2-3
* 文字要素の指定
文章中の一部分の文字要素を変化させます。
- 「\'」2個ではさんだ部分は強調されます。
- 「\'」3個ではさんだ部分はさらに強調されます。
- 「=」2個ではさんだ部分は取消線になります。
 このようにすると\'\'強調\'\'になります。
 そして、このようにすると\'\'\'さらに強調\'\'\'されます。
 ==なんとなく==取り消し線もサポートしています。
このようにすると\'\'強調\'\'になります。
そして、このようにすると\'\'\'さらに強調\'\'\'されます。
==なんとなく==取り消し線もサポートしています。
* リンク
- リンクしたいページ名を２つのカギカッコで囲むと、そのページへのリンクになります。
 例えば[[FrontPage]]とすると、入口ページへのリンクになります。
例えば[[FrontPage]]とすると、入口ページへのリンクになります。
* 新規ページの作成
「新規作成」をたどると、ページを作成できます。
* ページの削除
テキストを全部消去して保存すると、そのページを削除します。
* 任意のURLへのリンク
単語|URLを２つのカギカッコで囲むとを任意のURLへのリンクになります。
 [[qwik|http://qwik.jp/]]とかもできます。
[[qwik|http://qwik.jp/]]とかもできます。

このときURLの末尾がjpg,jpeg,png,gifだと、画像がページ中に埋め込まれます。
(指定した単語がALT要素に設定されます。)
 [[New!|http://img.yahoo.co.jp/images/new2.gif]]
[[New!|http://img.yahoo.co.jp/images/new2.gif]]

パラグラフ中にURLのようなものがあると、自動的にリンクとなります。
 qwikWebのホームページはhttp://qwik.jp/です。
qwikWebのホームページはhttp://qwik.jp/です。

* InterWiki
InterWikiとは、他のWikiページへ簡単にリンクをはる機能です。
またその拡張として、GoogleやAmazonなどに簡単にリンクをはる機能も提供します。
 - [[google:qwikWeb]]
 - [[isbn:4797318325]]
 - [[amazon:Wiki]]
- [[google:qwikWeb]]
- [[isbn:4797318325]]
- [[amazon:Wiki]]
'
    }

    Dja_theme_list = {
      :dt => 'テーマ一覧',
      :dd => '選択可能なテーマ一覧が表示されます。',
      :dc => '* 例
 {{theme_list}}
{{theme_list}}
選択可能なテーマ一覧です。

[[_SiteConfig]]ページにて、テーマを設定できます。
' }

    Dja_wema = {
      :dt => '附箋機能 ',
      :dd => '附箋をはることができます。',
      :dc => '* 使用法
ページの下に、「New Post-it」というリンクがあるので、押してください。
小さなWindowが表示さます。なにかテキストをいれ、セーブしてください。
Windowを動かして、「set」を押すと位置をセットします。
' }

  end
end
