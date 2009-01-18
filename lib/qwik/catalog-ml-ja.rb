# -*- coding: shift_jis -*-
# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

module QuickML
  class CatalogFactory
    def self.catalog_ja
      {
	# Code convert setting.
	:charset => 'iso-2022-jp',
	:codeconv_method => :tojis,

	# for test
	'hello' => "こんにちは",

	# Original QuickML messages.
	"<%s> was removed from the mailing list:\n<%s>\n" =>
	"<%s> は\nメーリングリスト <%s> から削除されました。\n",

	"because the address was unreachable.\n" =>
	"メールが届かないためです。\n",

	"ML will be closed if no article is posted for %d days.\n\n" =>
	"このメーリングリストは %d日以内に投稿がないと消滅します。\n\n",

	"Time to close: %s.\n\n" =>
	"消滅予定日時: %s\n\n",

	'%Y-%m-%d %H:%M' =>
	"%Y年%m月%d日 %H時%M分",

	"You are not a member of the mailing list:\n<%s>\n" =>
	"あなたは <%s> メーリングリストのメンバーではありません。\n",

	"The original body is omitted to avoid spam trouble.\n" =>
	"メール本体はスパム対策のため省略されました。\n",

	"You are removed from the mailing list:\n<%s>\n" =>
	"あなたは <%s> メーリングリストから削除されました。\n",

	"by the request of <%s>.\n" =>
	"<%s> が削除をお願いしたためです。\n",

	"You have unsubscribed from the mailing list:\n<%s>.\n" =>
	"あなたは <%s> メーリングリストから退会しました。",


	"The following addresses cannot be added because <%s> mailing list reaches the maximum number of members (%d persons)\n\n" =>
	"<%s> メーリングリストはメンバーの最大人数 (%d人)\nに達したので以下のアドレスは追加できませんでした。\n\n",

	"Invalid mailing list name: <%s>\n" =>
	"<%s> は正しくないメーリングリスト名です。\n",

	"You can only use 0-9, a-z, A-Z,  `-' for mailing list name\n" =>
	"メーリングリスト名には 0-9, a-z, A-Z, 「-」だけが使えます。\n",

	"Sorry, your mail exceeds the length limitation.\n" =>
	"申し訳ありません。あなたのメールのサイズは制限を超えました。\n",

	"The max length is %s bytes.\n\n" =>
	"メールのサイズの制限は %s バイトです。\n\n",

	"[%s] Unsubscribe: %s" =>
	"[%s] 退会: %s",

	"[%s] ML will be closed soon" =>
	"[%s] メーリングリスト停止のご案内",

	"[%s] Removed: <%s>" =>
	"[%s] メンバー削除: <%s>",

	"Members of <%s>:\n" =>
	"<%s> のメンバー:\n",

	"How to unsubscribe from the ML:\n" =>
	"このMLを退会する方法:\n",

	"- Just send an empty message to <%s>.\n" =>
	"- 本文が空のメールを <%s> に送ってください\n",

	"- Alternatively, if you cannot send an empty message for some reason,\n" =>
	"- 本文が空のメールを送れない場合は、\n",

	"  please send a message just saying 'unsubscribe' to <%s>.\n" =>
	"  本文に「退会」とだけ書いたメールを <%s> に送ってください\n",

	"  (e.g., hotmail's advertisement, signature, etc.)\n" =>
	"  (署名やhotmailの広告などがついて空メールを送れない場合など)\n",

	"[QuickML] Error: %s" =>
	"[QuickML] エラー: %s",

	"New Member: %s\n" =>
	"新メンバー: %s\n",

	"Did you send a mail with a different address from the address registered in the mailing list?\n" =>
	"メーリングリストに登録したメールアドレスと異なるアドレスからメールを送信していませんか?\n",

	"Please check your 'From:' address.\n" =>
	"差出人のメールアドレスを確認してください。\n",

	"Info: %s\n" => 
	"使い方: %s\n",

	"----- Original Message -----\n" =>
	"----- 元のメッセージ -----\n",

	"[%s] Confirmation: %s" =>
	"[%s] 確認: %s",

	# qwikWeb messages.
	"First, please read the agreement of this service.\n" =>
	"まず下記の利用規約をお読み下さい。\n",

	"http://qwik.jp/qwikjpAgreementE.html\n" =>
	"http://qwik.jp/qwikjpAgreementJ.html\n",

	"You must agree with this agreement to use the service.\n" =>
	"このサービスを利用するには、利用規約を承認していただく必要があります。\n",

	"If you agree, then,\n" =>
	"もし承認する場合、\n",

	"Please simply reply to this mail to create ML <%s>.\n" =>
	"このメールに返信すると <%s> メーリングリストが作られます。\n",

	"WARNING: Total attached file size exceeded." =>
	"警告: 添付ファイルの合計サイズが最大容量を超えています。",

	'Files are not attached on the web.' =>
	"添付ファイルはWebに保存されません。",

	"WARNING: Total attached file size is reaching to the limit." =>
	"警告: 添付ファイルの合計サイズが最大容量に近づいています。",

	"%s left" =>
	"残り%s",

	"\nFile '%s' was not attached.\n" =>
	"\nファイル '%s' は保存されませんでした。\n",
      }
    end
  end
end
