# -*- coding: shift_jis -*-
# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/act-describe'

module Qwik
  class Action
    D_PluginBasic = {
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
** My group
You can see your group list.
 {{my_group}}
{{my_group}}
** Plugin list plugin
プラグインの一覧を表示します。
 {{plugin_list}}
{{plugin_list}}
'
    }

    D_PluginBasic_ja = {
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
** 自分のグループ
自分が所属しているグループの一覧を表示します。
 {{my_group}}
{{my_group}}
** プラグインリスト・プラグイン
プラグインの一覧を表示します。
 {{plugin_list}}
{{plugin_list}}
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
    def plg_pre
      content = yield
      return [:pre, content]
    end

    # ==============================
    def plg_window(url, text=nil)
      text = url if text.nil?
      a = [:a, {:href=>url, :class=>'external', :target=>'_blank'}, text]
      # FIXME: Recognize the url is external or not.
      return a
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

    # ============================== page attribute
    def page_attribute(ext, msg, base=@req.base)
      return [:span, {:class=>'attribute'},
	  [:a, {:href=>base+'.'+ext}, msg]]
    end

    def plg_last_modified
      return if ! defined?(@req.base) || @req.base.nil?
      page = @site[@req.base]
      return if page.nil?
      date = page.mtime
      return [:span, {:class=>'attribute'}, _('Last modified'), ': ',
	[:em, date.ymd]]
    end

    def plg_generate_time
      return nil if @req.user.nil?
      return [:span, {:class=>'attribute'}, _('Generation time'), ': ',
	[:em, "__qwik_page_generate_time__", _('seconds')]]
    end

    # ============================== member control
    def plg_only_guest
      return nil if @req.user
      s = yield
      return if s.nil?
      return c_res(s)
    end

    def plg_only_member
      return nil if @req.user.nil?
      s = yield
      return if s.nil?
      return c_res(s)
    end

    # ============================== group
    def plg_my_group
      return nil if @req.user.nil?
      farm = @memory.farm
      group_list = farm.get_my_group(@req.user)
      ul = [:ul]
      group_list.each {|name|
	ul << [:li, [:a, {:href=>"/#{name}/"}, name]]
      }
      return ul
    end

    # ============================== meta function
    def plg_plugin_list
      desc = descriptions_hash
      plg_desc = plugin_descriptions(desc)

      ul = [:ul]
      plugin_list.each {|plugin_name|
	if plg_desc[plugin_name]
	  desc_link = plg_desc[plugin_name].first
	  ul << [:li, [:a, {:href=>"#{desc_link}.describe"}, plugin_name]]
	else
	  ul << [:li, plugin_name]
	end
      }
      return ul
    end

    IGNORE_PLUGINS = [/\Aring_/, /\Amodulobe_/]
    def plugin_list
      return self.methods.grep(/\Aplg_/).map {|name|
	name.sub(/\Aplg_/) {''}
      }.reject {|name|
	IGNORE_PLUGINS.any? {|re| re =~ name }
      }.sort
    end

    def descriptions_hash
      desc = {}
      description_list.each {|name|
	desc[name] = self.class.const_get("D_#{name}")[:dc]
      }
      return desc
    end

    def plugin_descriptions(desc)
      plg_desc = {}
      desc.each {|k, v|
	v.each {|line|
	  if /\{\{([a-z_]+)/ =~ line
	    name = $1
	    plg_desc[name] = [] if ! plg_desc[name]
	    if ! plg_desc[name].include? k
	      plg_desc[name] << k
	    end
	  end
	}
      }
      return plg_desc
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

      # test_pre
      ok_wi [:pre, "t\n"], '{{pre
t
}}'

      # test_window
      ok_wi [:a, {:class=>"external", :target=>'_blank', :href=>'url'}, 't'],
	'{{window(url,t)}}'
      ok_wi [:a, {:class=>"external", :target=>'_blank', :href=>'url'}, 'url'],
	'{{window(url)}}'

      # test_admin_menu
      ok_wi([:a, {:href=>'.new'}, 'newpage'], '{{menu(newpage)}}')
      ok_wi([:a, {:href=>'1.edit'}, 'edit'], '{{menu(edit)}}')
      ok_wi([], '{{menu(nosuchmenu)}}')
      # test for not logined mode
      #ok_wi('', '{{menu(newpage)}}', nil)
      #ok_wi('', '{{menu(edit)}}', nil)
      #ok_wi('', '{{menu(nosuchmenu)}}', nil)

      # test_meta_plugin
      #ok_wi ['test'], '{{plugin_list}}'
      w = @action.plg_plugin_list
      eq :ul, w[0]
    end

    def test_page_attribute
      # test_last_modified
      ok_wi(/Last modified: /, '{{last_modified}}')

      # test_generate_time
      ok_wi(/Generation time: /, '{{generate_time}}')

      # test_only_member_or_guest
      t_site_open
      ok_wi([:p, 'm'], "{{only_member\nm\n}}")
      assert_path([], "{{only_member\nm\n}}", nil, "//div[@class='section']")
      ok_wi([], "{{only_guest\ng\n}}")
      assert_path([:p, 'g'], "{{only_guest\ng\n}}",
		  nil, "//div[@class='section']")
    end
  end
end
