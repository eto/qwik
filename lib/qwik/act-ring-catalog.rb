#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    def _r(text)
      catalog = ring_catalog
      t = catalog[text]
      return t if t

      # Try to reload.
      @memory[:ring_catalog] = ring_generate_catalog
      catalog = ring_catalog
      t = catalog[text]
      return t if t

      raise if @config.test	# Only for test.

      return text.to_s
    end

    def ring_catalog
      if @memory[:ring_catalog].nil?
	@memory[:ring_catalog] = ring_generate_catalog
      end
      return @memory[:ring_catalog]
    end

    def ring_generate_catalog
      catalog = {
	# test
	:TEST => "テスト",

	# common
	:RIGHT_ARROW => "→",
	:BULLET => "●",
	:USER => "ユーザ名",
	:YOUR_MAIL => "あなたのメール",
	:YOUR_USER => "あなたのユーザ名",
	:YOUR_NAME => "あなたの名前",
	:MAIL => "メール",
	:USER_NAME => "ユーザネーム",
	:MESSAGE => "メッセージ",
	:REALNAME => "本名",
	:THANKYOU => "どうもありがとうございました。",
	:CONFIRM_YOUR_INPUT => "もう一度入力を確認してください。",
	:GOBACK => "ブラウザの「戻るボタン」で入力画面に戻り、もう一度入力を確認してください。",

	# act-ring-invite.rb
	:INVITE_INPUT_GUEST_MAIL =>"招待したい人のメールアドレスを入力してください。",
	:INVITE_MESSAGE_DUMMY_TEXT => "SFC-Ringに招待します。",
	:INVITE_DESC => 'この文面と共に、招待する人に送られます。この文面と共に招待状一覧に表示されます。',
	:INVITE_DO_INVITE => " 招待する! ",
	:INVITE_NOSEND => "招待状は送られませんでした",
	:INVITE_INPUT_MAIL => "メールアドレスを入力してください",
	:INVITE_MAIL_IS_SENT => "招待状が送られました",
	:INVITE_SUBJECT => "SFC-Ringへのご招待",

	# act-ring-maker.rb
	:MAKER_USER_NAME_DESC => 'SFC-Ringで表示される名前です。アルファベット、ひらがな、かたかな、漢字などが使えます。記号、空白は使えません。例: katokan、カトカン、かとかん、加藤寛、などなど。',
	:NYUUGAKU_GAKUBU => "入学学部",
	:FACULTY_SS => "総合政策",
	:FACULTY_EI => "環境情報",
	:FACULTY_KI => "看護医療",
	:FACULTY_SM => "政策・メディア",
	:NYUUGAKU_NENDO => "入学年度",
	:MAKER_REGISTER => " 登録する! ",
	:MAKER_ALREADY_REGISTERD => "すでに登録されています。",
	:MAKER_GOBACK_AND_CONFIRM => "ブラウザの「戻るボタン」で入力画面に戻り、もう一度入力を確認してください。",
	:MAKER_NOT_REGISTERD => "登録されませんでした。",
	:MAKER_REGISTERD => "登録されました",
	:MAKER_THE_PAGE => "作ったページ",
	:MAKER_SEE => "を見る。",

	# act-ring-msg.rb
	:MSG_INPUT_HERE => "ここにメッセージを入力してください。",
	:MSG_INPUT_MESSAGE => "メッセージを入力してください",
	:MSG_MESSAGE_IS_ADDED => "メッセージを追加しました",

	# act-ring-new.rb
	:NEW_CREATED => "アカウントが作成されました。",
	:NEW_FROM_SFCNEJP => "sfc.ne.jpよりの登録です。",

	# act-ring-user.rb
	:USER_NAME => "名前",
	:USER_NYUGAKU => "入学",
	:USER_YEAR => "年",
      }
      return catalog
    end
    private :ring_generate_catalog
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActRingCatalog < Test::Unit::TestCase
    include TestSession

    def test_all
      res = session
      ok_eq("テスト", @action._r(:TEST))
    end
  end
end
