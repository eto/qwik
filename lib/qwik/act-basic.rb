$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    D_plugin_basic = {
      :dt => 'Basic plugins',
      :dd => 'Simple and Basic plugins.',
      :dc => '* Description
** BR plugin
You can break a line by using <br> element.
 This is {{br}} a test.
This is {{br}} a test.
** Open with new window plugin
You can make a link to show the page in a new window.
 {{window(http://qwik.jp/)}}
{{window(http://qwik.jp/)}}
** Show last modified plugin
You can show last modified by this plugin.
 {{last_modified}}
{{last_modified}}
** Information only for a group
You can specify content only for guests or for members.
{{only_guest
You are a guest.
}}
{{only_member
You are a member.
}}
 {{only_guest
 You are a guest.
 }}
 {{only_member
 You are a member.
 }}
** Comment out plugin
You can comment out the content.
 {{com
 You can not see this line.
 You can not see this line also.
 }}
{{com
You can not see this line.
You can not see this line also.
}}
'
    }

    Dja_plugin_basic = {
      :dt => '基本プラグイン',
      :dd => '基本的なプラグインの説明です。',
      :dc => '* 説明
** BRプラグイン
改行します。
 This is {{br}} a test.
This is {{br}} a test.
** 新規ウィンドウで表示
新しいウィンドウを作って、そこで表示させます。
 {{window(http://qwik.jp/)}}
{{window(http://qwik.jp/)}}
** 最終更新プラグイン
最終更新日時を表示します。
 {{last_modified}}
{{last_modified}}
** 特定グループ向け表示
ゲストだけに表示する部分、グループだけに表示する部分を指定できます。
{{only_guest
あなたはゲストです。
}}
{{only_member
あなたはメンバーです。
}}
 {{only_guest
 あなたはゲストです。
 }}
 {{only_member
 あなたはメンバーです。
 }}
** コメントアウト・プラグイン
ある領域をコメントアウトします。
 {{com
 この行は見えない。
 この行も見えない。
 }}
{{com
この行は見えない。
この行も見えない。
}}
'
    }

    # ==============================
    def plg_qwik_null
      return ''
    end

    def plg_qwik_test
      return 'test'
    end

    # ==============================
    def plg_br
      return [:br]
    end

    # ==============================
    def plg_window(url, text=nil)
      text = url if text.nil?
      return [:a, {:href=>url, :target=>'_blank'}, text]
    end

    # ==============================
    def plg_com(*args)	# commentout
      #str = yield if block_given?
      return nil	# ignore all
    end

    # ============================== adminmenu
    def plg_menu(cmd, msg=nil)
      return if ! @req.user
      return if ! defined?(@req.base) || @req.base.nil?
      return plg_act('new', cmd) if cmd == 'newpage'
      return plg_ext(cmd) if cmd == 'edit' || cmd == 'wysiwyg'
      return nil
    end

    def plg_act(act, msg=act)
      return [:a, {:href=>".#{act}"}, _(msg)]
    end

    def plg_ext(ext, msg=ext)
      return [:a, {:href=>"#{@req.base}.#{ext}"}, _(msg)]
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActBasic < Test::Unit::TestCase
    include TestSession

    def test_all
      # test_null
      ok_wi [''], '{{qwik_null}}'

      # test_test
      ok_wi ['test'], '{{qwik_test}}'

      # test_br
      ok_wi([:br], '{{br}}')

      # test_window
      ok_wi([:a, {:target=>'_blank', :href=>'url'}, 't'], '{{window(url,t)}}')
      ok_wi([:a, {:target=>'_blank', :href=>'url'}, 'url'], '{{window(url)}}')

      # test_admin_menu
      ok_wi([:a, {:href=>'.new'}, 'newpage'], '{{menu(newpage)}}')
      ok_wi([:a, {:href=>'1.edit'}, 'edit'], '{{menu(edit)}}')
      ok_wi([], '{{menu(nosuchmenu)}}')
      # test for not logined mode
      #ok_wi('', '{{menu(newpage)}}', nil)
      #ok_wi('', '{{menu(edit)}}', nil)
      #ok_wi('', '{{menu(nosuchmenu)}}', nil)
    end
  end
end
