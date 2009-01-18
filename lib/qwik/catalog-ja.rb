# -*- coding: shift_jis -*-
# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

module Qwik; end

class Qwik::CatalogFactory
  def self.catalog_ja
    {
      # for test
      'hello' => 'こんにちは',

      # Error
      'Error' => 'エラー',
      'Failed' => '失敗',

      # act-comment.rb
      'No message.' => 'メッセージがありません',

      # act-povray.rb, act-textarea.rb
      'No text.' => 'テキストがありません',

      # action.rb
      'No such site.' => '対応するサイトがありません',
      'No corresponding site.' => '対応するサイトはありません',
      'Please send mail to make a site' =>
      'qwikWebのサイトを作るには、まずメールを送る必要があります。',
      'Login' => 'ログイン',
      'Access here and see how to.' => 'にアクセスして、使い方をご覧下さい。',
      'Please log in.' => 'ログインしてください',
      'Members Only' => 'メンバー専用', # and act-getpass.rb
      'You are now logged in with this user id.' =>
      'あなたは今このユーザID でログインしています',
      'You are not logged in yet.' =>
      'あなたはまだログインしていません', # FIXME: not found.
      'If you would like to log in on another account,' =>
      '別のユーザID でログインしなおしたい場合は、',
      'please log out first.' => 'まずログアウトしてください',
      ': Access here, and log in again.' =>
      'してから再度アクセスしてください。', # FIXME: not found.
      'You need to log in to use this function.' =>
      'この機能を利用するにはログインする必要があります。',
       'Go back' => '戻る',
      'Please input POST' => 'POST入力が必要',
      'This function requires POST input.' =>
      'この操作はPOST入力で行う必要があります。',
      'Page not found.' => 'ページが見つかりません',
      'Push create if you would like to create the page.' =>
      'ページを作成したい場合は、新規作成を押してください', # act-new.rb

      'Incorrect path arguments.' => '変なパスがついてます',
      'Path arguments are not acceptable.' =>
      'なにか変なパスがついちゃってます。',

      'Not found.' => 'ありません',
      'Access here.' => 'こちらをご覧ください。',

      # act-album
      'Show album in full screen.' => 'アルバムをフルスクリーンで見る', # FIXME: not found

      # act-archive
      'Site archive' => 'サイトアーカイブ',

      # act-attach
      'Files' => '添付ファイル',
      'Delete' => '消去',
      'Download' => 'ダウンロード', # act-files.rb
      'No such file.' => 'ファイルが見つかりません',
      'There is a file with the same file name.' =>
      '同名のファイルが存在しています', # FIXME: not found
      'Can not use Japanese characters for file name' =>
      '日本語のファイル名は使えません', # FIXME: not found
      'Maximum size exceeded.' => 'ファイルサイズの限界を超えています。',
      'Maximum size' => '最大容量',
      'File size' => 'ファイルサイズ',
      'The file is saved.' => 'ファイルをセーブしました。',
      'File attachment completed' => 'ファイルを添付しました',
      'Attach file' => 'ファイル添付',
      'Attach a file' => 'ファイルを添付します',
      'Confirm file deletion' => 'ファイル消去確認画面',
      "Push 'Delete' to delete a file" =>
      '「消去する」を押すと，本当にファイルを消去します．',
      'Delete' => '消去する',
      'Already deleted.' => 'すでに消去されているようです',
      'Failed to delete.' => 'ファイル消去に失敗しました。謎。',
      'The file has been deleted.' => '消去しました',
      'File list' => '現在添付されているファイル',
      # other
      '->' => '→',
      'Attach' => '添付する',	# FIXME: not found

      # act-backup
      'This is the first page.' => 'これは最初のページです。',
      'Difference from the previous page' => '前回からの差分',
      'Original data' => '元データ',
      '<-' => '←',
      'Newest' => '最新',
      'Backup list' => 'バックアップ一覧',

      # act-basic-plugin
#      'New page' => '新規作成',
#      'Edit' => '編集',
      'newpage' => '新規作成',
      'edit' => '編集',
      'wysiwyg' => 'その場で編集',
      'Last modified' => '最終更新',
      'Generation time' => '生成時間',
      'seconds' => '秒',

      # act-edit
      'Site Menu' => 'サイトメニュー',
      'Site Configuration' => 'サイト設定',
      'Group members' => 'グループメンバー',
      'Site Archive' => 'サイトアーカイブ',
      'Mailing List Configuration' => 'メーリングリスト設定',

      'Functions' => '機能の説明',
      'Page List' => 'ページ一覧',
      'Recent Changes' => '更新履歴',
      ' ago' => '前',
      'more...' => 'もっと前の情報',
      'min.' => '分',
      'hour' => '時間',
      'day' => '日',
      'month' => 'ヶ月',
      'year' => '年',
      'century' => '世紀',

      # act-comment
      'User' => 'ユーザ名',
      'Message' => 'メッセージ',
      'Message has been added.' => 'メッセージを追加しました',

      # act-config
      'Site config'	=> 'サイト設定',
      'Site Configuration' => 'サイト設定',

      # act-chronology
      'Time walker' => '時間旅行',
      'Chronology' => '年表',

      # act-day
      'One day' => '一日',

      # act-describe
      'Function' => '機能説明',
      'Functions list' => '機能一覧',

      # act-edit.rb
      'Page is deleted.' => 'ページを削除しました',
      'Password does not match.' => 'パスワードが一致しませんでした。',
      'Password' => 'パスワード',
      'Please find a line like that above, then input password in parentheses.' =>
      'このような行を探して、括弧の中にパスワードを入力してください。',

      'Page edit conflict' => '更新が衝突しました。',
      'Please save the following content to your text editor.' =>
      '下記の内容をテキストエディタなどに保存し、',
      'Newest page' => '最新のページ',
      ': see this page and re-edit again.' => 'を参照後に再編集してください。',
      'Page is saved.' => 'ページを保存しました。',
      'Save' => '保存',
      'Attach' => '添付',

      'Edit' => '編集',
      'Attach Files' => 'ファイル添付',
      'Attach many files' => 'もっとたくさん添付する',

      'Help' => 'ヘルプ',
      'How to qwikWeb' => 'qwikWebの使い方',

      'Site administration' => 'サイト管理',

      'Header' => '見出し',
      'List' => '箇条書 ',
      'Ordered list' => '順序リスト ',
      'Block quote' => '引用 ',
      'Word' => '定義 ',
      'Definition' => '言葉の定義 ',
      'Table' => '表 ',
      'Emphasis' => '強調',
      'Stronger' => 'もっと強調',
      'Link' => 'リンク',
      'more help' => 'もっと詳しい書式',

      'Text Format' => '書式一覧',
      'History' => '履歴',
      'Backup' => 'バックアップ',
      'Time machine' => 'タイムマシーン',
      'Page functions' => 'ページの機能 ',
#      'Experimental functions' => '実験中の機能 ',

      # act-getpass
      'Invalid mail address' => 'パスワード形式エラー',
      'Get Password' => 'パスワード入手',
      'Send Password' => 'パスワード送信',
      'You will receive the password by e-mail.' => 'パスワードをメールで送ります',
      'Please input your mail address.' => 'メールアドレスを入力してください',
      'Mail address' => 'メールアドレス',
      'Go back to Login screen' => 'ログイン画面にもどる',

      'Send' => '送信',
      'Send' => '送信',

      'You input this e-mail address as user ID.' =>
      'あなたはユーザIDとしてこのメールアドレスを入力しました',
      'This user with this ID is not a member of this group.' =>
      'このユーザIDは、このグループには含まれていません',
      'Only the member of this group can get a password.' =>
      'このグループのメンバーは、パスワードを取得できます。',

      'Your password:' => 'パスワード :',
      'This is your user name and password: ' =>
      'このサイトにおけるユーザ名とパスワードです : ',
      'Username' => 'ユーザ名',
      'Password' => 'パスワード',
      'Please access login page' =>
      'ログインページにアクセスしてください :',

      'You can input the user name and password from this URL automatically.' =>
      '下記URLにアクセスすると、自動的にユーザー名とパスワードを入力します。',
      'The mail address format is wrong.' =>
      'メールアドレスの形式が間違ってます。',
      'Please confirm the input again.' => 'もう一度入力を確認してください。',
      'Please access again.' => '再度アクセスしてください。',
      'Send Password Error' => 'メール送信エラー',
      'Send failed because of system error.' =>
      'システムエラーのため、パスワード送信に失敗しました。',
      'Please contact the administrator.' => 'システム管理者にご連絡下さい。',

      'Send Password done' => 'パスワード送信完了',
      'I send the password to this mail address.' =>
      'パスワードを以下のメールアドレスに送信しました。',
      'Please check your mailbox.' => 'メールボックスを確認してください',

      # act-group
      'Member list' => 'メンバー一覧',

      # act-hcomment
      'Name' => 'お名前',
      'Comment' => 'コメント',
      'Anonymous' => '名無しさん',
      'Add a comment.' => 'コメントを追加しました',
      'Submit' => '投稿',
      'Page collision is detected.' => '更新が衝突しました',
      'Go back and input again.' => '元のページに戻り、再度入力してください。',

      # act-history
      'Time machine' => 'タイムマシーン',
      'Move this' => 'これを動かして下さい',

      # act-license
      'You can use the files on this site under [[Creative Commons by 2.1|http://creativecommons.org/licenses/by/2.1/jp/]] license.' =>
      'ここに置かれたファイルは、[[クリエイティブ・コモンズ 帰属 2.1|http://creativecommons.org/licenses/by/2.1/jp/]]ライセンスの下に利用できます。',
      'You can use the files on this site under [[Creative Commons Attribution-ShareAlike 2.5|http://creativecommons.org/licenses/by-sa/2.5/]] license.' =>
      'ここに置かれたファイルは、[[クリエイティブ・コモンズ 帰属 - 同一条件許諾 2.5|http://creativecommons.org/licenses/by-sa/2.5/]]ライセンスの下に利用できます。',
      'The files you uploaded will be under [[Creative Commons Attribution-ShareAlike 2.5|http://creativecommons.org/licenses/by-sa/2.5/]] license.' =>
      'ここにアップロードされたファイルは、[[クリエイティブ・コモンズ 帰属 - 同一条件許諾 2.5|http://creativecommons.org/licenses/by-sa/2.5/]]ライセンスの下に置かれます。',

      # act-login
      'Log out' => 'ログアウト',
      'Log in by Session' => 'Sessionによるログイン', # FIXME: not found
      'Success' => '成功',
      'Go next' => '次へ',
      'Session ID Authentication' => 'Session ID 認証', # FIXME: not found
      'or, Access here.' => 'または、こちらをご利用下さい。',
      'Log in using Basic Authentication.' => 'Basic認証でログインしました。',
      'Log in by Basic Authentication.' => 'Basic認証でログイン',
      'Logging in by Basic Authentication.' => 'Basic認証でログインします。',
      'Log in by cookie.' => 'cookieによるログイン',
      'You are already logged in by cookie.' => '現在cookieでログインしています。',
      'You can log in by TypeKey.' => 'TypeKeyでもログインできます。', # FIXME: not found
      'Login Error' => 'ログインエラー',
      'Invalid ID (E-mail) or Password.' =>
      'ユーザID(E-mail)もしくはパスワードが違います',

      'Already logged in.' => 'ログイン済み',

      'Please confirm the mail again.' =>
      '入力に間違いがないかどうかもう一度メールをご確認ください。',

      # FIXME: not found
      '(Please do not use copy and paste. Please input the password from the keyboard again.)' =>
      '(コピー&ペーストだとエラーになる場合があります。その場合はお手数ですがキーボードから入力してみてください)',
      'Can not log out.' => 'ログアウトできません',
      'You can not log out in Basic Authentication mode.' =>
      'Basic認証の場合はログアウトできません。',
      'Please close browser and access again.' =>
      '一旦ブラウザを閉じて、再度アクセスしてください。',
      'Terminal Number is deleted.' => '端末番号を削除しました',
      'Basic Authentication' => 'Basic認証',
      'For mobile phone users' => '携帯電話の方はこちらへ',
      'Log out done.' => 'ログアウト完了',
      'Confirm' => '確認',
      'Push "Log out".' =>
      '「ログアウトする」を押すと、本当にログアウトします。',
      'Log out' => 'ログアウトする',

      'Log in to ' => 'ログインします : ',
      'Please input ID (E-mail) and password.' =>
      'ユーザIDとパスワードを入力してください',
      'ID' => 'ユーザID',
      'Password' => 'パスワード',

      'If you have no password,' => 'パスワードをお持ちでない方は',
      'Access here' => 'こちらをご覧下さい',
      'If you have no password' => 'パスワードをまだ持ってない?',
      'For mobile phone users, please use' => # FIXME: not found
      '携帯電話の方は、こちらをご利用下さい',
      'You can also use TypeKey' => 'TypeKeyも使えます', # FIXME: not found
      'Log in by TypeKey' => 'TypeKeyでログイン',
      'Please send mail address for authentication.' =>
      '認証のため、メールアドレスを送信してください',

      # act-member
      'Add a member' => 'メンバー追加',
      'Mail address to add' => '追加するメールアドレス',
      'Add' => '追加',
      'Invalid Mail' => '無効なメールアドレス',
      'Already exists' => 'すでに存在しています',
      'Member added' => 'メンバーは追加されました',
      'Member list' => 'メンバー一覧',
      'Member' => 'メンバー',

      # act-mlsubmitform
      'Mlcommit' => '投稿する。',

      # act-pagelist
      'Recent change' => '最新の更新',

      # act-plan
      'Plan' => '予定',
      'New plan' => '新しい予定',
      'Create a new plan' => '新しい予定の登録',
      'Please input like this' => 'このように入力してください',
      'Already exists.' => 'すでにありました',

      # act-schedule
      'Schedule' => 'スケジュール',
      'Date' => '日付',
      'Schedule edit done.' => 'スケジュールを入力しました。',

      # act-slogin
      'Session ID is registered.' => 'Session IDを登録しました。', # FIXME: not found

      # act-style
      'Access Failed' => 'アクセスできませんでした',

      # act-map
      'Show map in full screen.' => '地図をフルスクリーンで見る',

      # act-mcomment
      'Failed' => '失敗しました',

      # act-mdlb
      'Please specify file.' => 'ファイルを指定してください。',
      'Please contact the administrator.' => '管理者に連絡してください。',
      'The file is saved with this filename.' =>
      'このファイル名でセーブされました。',
      'The image is also saved.' =>
      '画像ファイルもセーブされました。',
      'Model file' => 'モデルファイル',
      'Image file' => '画像ファイル',

      # act-mdblb-model
#      'Title' => 'タイトル',
      'Author' => '作者',
#      'Comment' => 'コメント',
      'Download' => 'ダウンロード',

      # act-new
      'Push create.' => '新規作成を押してください。',
      'New page' => '新規作成',
      'Title' => 'タイトル',
      'PageKey' => 'ページキー',
      'Already exists' => 'すでに存在しています',
      ' already exists.' => 'はすでに存在しています。',
      'Please specify another title.' => '違うタイトルを指定してください。',
      'Created.' => '作成しました',
      'Edit new page' => '新規ページを編集',

      # etc.
      'Show history' => '過去の変遷を辿る',
      'Show backup' => 'いままでの履歴',

      # act-presen
      'Presentation mode' => 'プレゼンモード',
      'Presentation mode' => 'プレゼンモード',
      # other
      'Present' => 'プレゼン',
      'presentation' => 'プレゼンテーション',

      # act-search
      'Search' => '検索',
      'Search result' => '検索結果',
      'No match.' => '見つかりませんでした。',

      # act-sendpass
      'Succeeded.' => '成功しました',
      'Failed.' => '失敗しました',
      'Wrong format.' => '形式が違います',
      'Not a member.' => 'メンバーではありません',
      'You can send password for the members.' =>
      'メンバーにパスワードを送信することができます。',
      'Please select members to send password.' =>
      'パスワードを送るメンバーを選択してください。',

      # act-table-edit
      'You can only use a table.' => 'tableしか使えません。',
      'You can only use text.' => 'textしか使えません。',
      'Update' => '更新',
      'Edit done.' => '編集完了',

      # act-textarea
      'Edit text done.' => 'テキストを編集しました',

      # act-takahashi
      'Show in full screen.' => 'フルスクリーンで見る', # FIXME: not found

      # act-toc
      'contents' => '目次',
      'Contents' => '目次',

      # act-typekey
      'Cannot use.' => '使えません。',
      'There is no site token for TypeKey.' =>
      'TypeKey用のサイトトークンがありません。',
      'Verify failed.' => '認証できませんでした。',
      'Time out.' => '時間切れです。',

      # act-wysiwyg
      'Edit in this page' => 'その場で編集',
      'Auto-save' => '自動保存',
#       'This is an experimental function.' => 'この機能はまだ実験中です。',
#       'The contents will be translated to html.' =>
#       'ページの内容は、全てHTMLに変換されます。',
#       'Please use this function only if you understand what will happen.' =>
#       '何が起るのかを理解されている場合のみ、お使い下さい。',

      # act-wema
      'How to use post-its' => '附箋の使い方',
      'New post-it is created.' => '付箋を新規に作成しました',
      'Edit done.' => '編集しました',
      'No action.' => '何もしませんでした',
      'Delete a Post-it.' => '付箋を消去しました',
      'Set position.' => '位置をセットしました',
      'Post-it' => '附箋',
      'New Post-it' => '新規附箋',
      'Help' => '使い方',
      'Draw Line' => '線を引く',
      'Text color' => '文字色',
      'Background' => '背景色',

      # act-site-backup
      'Site backup' => 'サイトバックアップ',

      # act-files
      'Attached files total:' => '添付ファイル合計:',
      'Exceeded limit.' => '最大容量を超えました',
      '%s left' => '残り%s',
      'Total file size exceeded.' => '総ファイルサイズの限界を超えています。',
      'Reaching limit.' => '容量が少なくなってきています。',
      'Maximum total size' => '添付ファイルの最大',
      'Current total size' => '現在の添付ファイルの合計',


      # Add you catalog here.
      '' => '',
      '' => '',
      '' => '',
      '' => '',
      '' => '',
      '' => '',
      '' => '',
      '' => '',
    }
  end
end
