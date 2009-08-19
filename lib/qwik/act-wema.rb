# -*- coding: shift_jis -*-
# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

# Thanks to Mr. Kan Fushihara

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/act-monitor'

module Qwik
  $wema_debug = false
  $wema_redirect = true

  class Action
    D_PluginWema = {
      :dt => 'Post-it plugin',
      :dd => 'You can put post-it notes on the page.',
      :dc => "* How to
 {{wema}}
{{wema}}

Embed this wema plugin to your page.
Click 'New Post-it' link, then you see a small window.
Enter some text and save it.
You can move the small window and click set for setting the position.
* Thanks
I start development from [[wema|http://wema.sourceforge.jp/]]
by Mr. Kan Fushihara.  Thank you very much.
"
    }

    D_PluginWema_ja = {
      :dt => '附箋機能 ',
      :dd => '附箋をはることができます。',
      :dc => '* 使用法
 {{wema}}
{{wema}}

ページ中に上記のようにwemaプラグインをうめこみます。
「New Post-it」というリンクを押すと、小さなWindowが表示されます。
なにかテキストをいれ、セーブしてください。
Windowを動かして、「set」を押すと位置をセットします。
* 感謝
伏原幹氏による「[[wema|http://wema.sourceforge.jp/]]」を元に開発いたし
ました。どうもありがとうございます。
'
    }

    # Show only if there is already wema.
    def plg_wema_compat
      return if @site[@req.base].nil?
      return if defined?(@wema_generated)
      wp = WemaPage.new(@site, @site[@req.base])
      wemas = wp.get_wemas
      if wemas.empty?
	# create wema link.
	return [:a, {:href=>'PluginWema.describe'}, _('Post-it')]
      end
      @wema_generated = true
      return WemaHtmlGenerator.generate(wemas, @req.base)
    end

    def plg_wema
      return if @site[@req.base].nil?
      return if defined?(@wema_generated)
      wp = WemaPage.new(@site, @site[@req.base])
      wemas = wp.get_wemas
      @wema_generated = true
      return WemaHtmlGenerator.generate(wemas, @req.base)
    end

    def ext_wema
      c_require_post
      c_require_login

      wp = WemaPage.new(@site, @site[@req.base])
      redirect = "#{@req.base}.html"
      redirect = nil if $wema_debug

      mode = @req.query['mode']
      wid  = @req.query['id']		# wema id
      connected = @req.query['ln']
      left = @req.query['l']
      top  = @req.query['t']
      fg   = @req.query['tc']
      bg   = @req.query['bg']
      text = @req.query['body']

      mode = 'delete' if mode == 'edit' && text.empty?

      case mode
      when 'edit'
	if wid.nil? || wid.empty?	# create new
	  wema = wp.create_new
	  msg = _('New post-it is created.')
	else
	  id = wid.sub(/\Aid/, '').to_i
	  wp.get_wemas
	  wema = wp[id]
	  msg = _('Edit done.')
	end

	if wema
	  wema.set(connected, left, top, fg, bg, text)
	  c_make_log('wemaedit') # WEMAEDIT
	  #c_monitor('wemaedit') # WEMAEDIT
	end
	return wema_jump(msg, redirect)

      when 'delete'
	if wid.nil? || wid.empty?
	  return wema_jump(_('No action.'), redirect)
	end

	id = wid.sub(/\Aid/, '').to_i
	wp.get_wemas
	wema = wp[id]
	wp.delete(id)
	c_make_log('wemadelete') # WEMADELETE
	#c_monitor('wemadelete') # WEMADELETE
	return wema_jump(_('Delete a Post-it.'), redirect)

      when 'setpos'
	wid = nil if wid.empty?
	return c_nerror('wid is nil') if wid.nil?
	  
	id = wid.sub(/\Aid/, '').to_i
	wp.get_wemas
	wema = wp[id]
	return c_nerror('can not get wema') if wid.nil?
	wema.setpos(left, top)

	#c_make_log('wemasetpos') # too many...
	#c_monitor('wemasetpos')
	return wema_jump(_('Set position.'), redirect)

      else
	return c_nerror("Unknown mode: [#{mode}]")

      end
    end

    def wema_jump(msg, url)
      return c_nredirect(msg, url) if $wema_redirect
      return c_notice(msg, url)
    end
  end

  class WemaPage
    include Enumerable

    def initialize(site, page)
      @site = site
      @page = page
      @pagename = @page.key
      @wemas = []
    end
    attr_reader :site, :pagename

    def get_wemas
      @wemas = get_list.map {|id|
	Wema.new(self, id)
      }
      return @wemas
    end

    def [](id)
      @wemas.each {|wema|
	return wema if wema.id == id
      }
      return nil
    end

    def create_new
      return create(get_new_id)
    end

    def delete(k)
      self[k].delete
      @wemas[k] = nil
    end

    private

    def get_new_id
      list = get_list
      return 1 if list.empty?
      return list.max + 1
    end

    def create(id)
      return Wema.new(self, id)
    end

    def get_list
      list = []
      @site.to_a(true).each {|page|	# true means get all pages.
	if /\A_#{@pagename}_wema_([0-9]+)\z/ =~ page.key
	  list << $1.to_i
	end
      }
      list
    end

    def get_lines
      lines = []
      @wemas.each {|wema|
	connected = wema.connected
	if connected && ! connected.empty?
	  lines << [wema.id, connected]
	end
      }
      lines
    end
  end

  class Wema
    def initialize(wemapage, id)
      @wemapage, @id = wemapage, id
      @site = @wemapage.site
      pagename = key(id)
      @page = @site[pagename]
      @page = @site.create(pagename) if @page.nil?
      @connected = @x = @y = @fg = @bg = @text = nil
      parse(@page.load)
    end
    attr_reader :id, :connected, :x, :y, :fg, :bg, :text

    def get_data
      data = {
	:id	=> @id,
	:connected => @connected,
	:x	=> @x,
	:y	=> @y,
	:fg	=> @fg,
	:bg	=> @bg,
	:text	=> @text,
      }
      return data
    end

    def set(connected, x, y, fg, bg, text)
      set_px(x) {|a| @x = a }
      set_px(y) {|a| @y = a }
      set_color(fg) {|a| @fg = a }
      set_color(bg) {|a| @bg = a }
      set_text(text) {|a| @text = a }
      set_str(connected) {|a| @connected = a }
      store
    end

    def setpos(x, y)
      set(nil, x, y, nil, nil, nil)
    end

    def get_id
      return "id#{@id}"
    end

    def delete
      @site.delete(key(id))
    end

    private

    def key(id)
      return "_#{@wemapage.pagename}_wema_#{id}"
    end

    def parse(str)
      lines = str.to_a
      f = lines.shift # first line
      return if f.nil?
      f.chomp!
      dummy, @connected, @x, @y, @fg, @bg = f.split(',')
      @text = lines.join('')
    end

    def store
      str = [nil, @connected, @x, @y, @fg, @bg].join(',')+"\n"
      str << @text.to_s
      @page.store(str)
    end

    private

    def set_px(a)
      return if is_nil?(a)
      yield a.sub(/px$/, '').to_i
    end

    def set_color(a)
      return if is_nil?(a)
      return unless /\A[\#a-z0-9]+\z/ =~ a
      yield a
    end

    def set_text(a)
      return if is_nil?(a)
      yield a.delete("\r").chomp+"\n"
    end

    def set_str(a)
      return if is_nil?(a)
      return unless /\A[a-z0-9]+\z/ =~ a
      yield a
    end

    def is_nil?(a)
      return a.nil? || ! a.is_a?(String) || a.empty?
    end
  end

  class WemaHtmlGenerator
    def self.generate(wemas, pagename)
      ar = [:div]
      ar << load_css		# At the first, load CSS.
      ar << make_menu		# Then, make menu.
      wemas.each {|wema|
	ar << get_div(wema)	# Create all divs for wemas.
      }
      ar << editor_html(pagename)	# Create an editor.
      ar << load_js		# At the last, load JavaScript.
      return ar
    end

    private

    def self.load_css
      return [:style, "@import '.theme/css/wema.css';"]
    end

    def self.make_menu
      return [:span, {:class=>'attribute'}, 'Post-it', ': ',
	[:a, {:href=>'javascript:wema_editor_show()'}, 'New Post-it'],
	' (', [:a, {:href=>'javascript:wema_help_show()'}, 'Help'], ')']
    end

    def self.load_js
      [:script, {:type=>'text/javascript', :src=>'.theme/js/wema.js'}, '']
    end

    # ============================== wema window
    def self.get_div(wema)
      k = wema.get_id

      text = wema.text || ''

      tokens = TextTokenizer.tokenize(text, true)
      h = TextParser.make_tree(tokens)

      h = resolve_href(h)

      h << '' if h.length == 0

      fg = wema.fg
      fg = '#000' if fg.nil? || fg.empty?
      bg = wema.bg
      bg = '#fff' if bg.nil? || bg.empty?

      x = wema.x
      y = wema.y

      div = [:div, {:id=>k, :class=>'wema',
	  :style=>"left:#{x}px;top:#{y}px;color:#{fg};background:#{bg};",
	  :wema_tc=>wema.fg,
	  :wema_bg=>wema.bg,
	  :wema_ln=>wema.connected,
	  :wema_d=>wema.text},
	[:div, {:class=>'menubar'}, [:span, {:class=>'handle'}, k],
	  [:span, {:class=>'cmd'},
	    [:a, {:href=>"javascript:wema_setpos('#{k}')"}, 'set'],
	    [:a, {:href=>"javascript:wema_edit('#{k}')"}, 'edit'],
	    [:a, {:href=>"javascript:wema_link('#{k}')"}, 'link']]],
	[:div, {:class=>'cont'}, h]]
      return div
    end

    def self.resolve_href(wabisabi)
      wabisabi.each_tag(:a){|w|
	ww = resolve_ref(w)
	w = ww ? ww : [w]
	w
      }
    end

    def self.resolve_ref(w)
      attr = w[1]
      return nil if attr.nil? || !attr.is_a?(Hash)
      href = attr[:href].to_s

      if /^(?:http|https|ftp|file):\/\// =~ href	# external link
	w.set_attr :class=>'external', :rel=>'nofollow',
	  :href=>".redirect?url=#{href}"
	return [w]
      end

      return nil
    end

    # ============================== editor window
    def self.editor_html(pagename)
      action = "#{pagename}.wema"
      return [:div, {:id=>'editor', :class=>'wema'},
	[:div, {:class=>'menubar'},
	  [:span, {:class=>'handle'}, 'editor'],
	  [:span, {:class=>'close'},
	    [:a, {:href=>'javascript:wema_editor_hide()'}, 'X']]],
	[:div, {:class=>'cont'},
	  [:form, {:method=>'POST', :action=>action,
	      :id=>'frm', :name=>'frm'},
	    [:p, {:class=>'save'},
	      [:input, {:type=>'submit', :value=>'Save'}]],
	    [:textarea, {:name=>'body', :cols=>'40', :rows=>'7'}, ''],
	    font_color,
	    bg_color,
	    [:p, 'Draw Line: ', text('ln')],
	    [:p, 'x:', text('l'), ' y:', text('t')],
	    param('id', ''),
	    param('mode', 'edit')]]]
    end

    def self.font_color
      ar = ['Text color: ', [:input, {:id=>'tc', :name=>'tc'}]]
      ar += ['#000', '#600', '#060', '#006'].map {|c| radio_color('tc', c) }
      return [:p, ar]
    end

    def self.bg_color
      ar = ['Background'+': ', [:input, {:id=>'bg', :name=>'bg'}]]
      ar += ['#fff', '#fcc', '#cfc', '#ccf', '#ffc', '#000'].map {|c|
	radio_color('bg', c)
      }
      return [:p, ar]
    end

    def self.radio_color(name, color)
      return [:a, {:href=>"javascript:wema_set_color('#{name}', '#{color}')",
	  :class=>'color',
	  :style=>"color:#{color};background:#{color};"}, '[_]']
    end

    def self.param(*a)
      return text(*a) if $wema_debug
      return hidden(*a)
    end

    def self.text(a='', b=nil)
      h = {}
      h.update(:name=>a) if a
      h.update(:value=>b) if b
      return [:input, h]
    end

    def self.hidden(a='', b=nil)
      h = {:type=>'hidden'}
      h.update(:name=>a) if a
      h.update(:value=>b) if b
      return [:input, h]
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestExtWema < Test::Unit::TestCase
    include TestSession

    def test_act_wema
      t_add_user

      page = @site['_PageAttribute']
      page.store '{{wema}}'

      page = @site.create_new

      res = session '/test/1.wema'
      ok_title 'Please input POST'

      res = session 'POST /test/1.wema'
      assert_text 'Unknown mode: []', 'title'

      res = session 'POST /test/1.wema?mode=edit&body='
      ok_title 'No action.'

      res = session 'POST /test/1.wema?mode=edit&body=t'
      ok_title 'New post-it is created.'
      page = @site['_1_wema_1']
      eq ",,,,,\nt\n", page.load

      res = session 'POST /test/1.wema?mode=edit&id=id1&body=t2'
      ok_title 'Edit done.'
      page = @site['_1_wema_1']
      eq ",,,,,\nt2\n", page.load

      res = session 'POST /test/1.wema?mode=setpos&id=id1&l=1&t=2'
      ok_title 'Set position.'
      page = @site['_1_wema_1']
      eq ",,1,2,,\nt2\n", page.load

      res = session '/test/1.html'
      ok_title '1'
      ok_in ['t2'], "//div[@class='wema']/p"
      ok_in [:p, 't2'], "//div[@class='wema']/div[@class='cont']"

      res = session 'POST /test/1.wema?mode=edit&id=id1&body=* t3'
      ok_title 'Edit done.'
      page = @site['_1_wema_1']
      eq ",,1,2,,\n* t3\n", page.load

      res = session '/test/1.html'
      ok_in [:h2, 't3'], "//div[@class='wema']/div[@class='cont']"

      res = session 'POST /test/1.wema?mode=edit&id=id1&body={{recent}}'
      ok_title 'Edit done.'
      page = @site['_1_wema_1']
      eq ",,1,2,,\n{{recent}}\n", page.load

      res = session '/test/1.html'
      ok_in [:plugin, {:method=>'recent', :param=>''}],
	"//div[@class='wema']/div[@class='cont']"

      res = session 'POST /test/1.wema?mode=edit&id=id1&body=http://e.com/'
      ok_title 'Edit done.'
      page = @site['_1_wema_1']
      eq ",,1,2,,\nhttp://e.com/\n", page.load

      res = session '/test/1.html'
      ok_xp [:a, {:href=>'.redirect?url=http://e.com/',
	  :rel=>'nofollow', :class=>'external'}, 'http://e.com/'],
	"//div[@class='wema']/p/a"

      res = session 'POST /test/1.wema?mode=edit&id=id1&body='
      ok_title 'Delete a Post-it.'
      page = @site['_1_wema_1']
# comment outed due to cache issue.
#      eq nil, page
    end

    def test_act_wema_without_login
      t_add_user

      page = @site.create_new

      res = session('POST /test/1.wema?mode=edit&body=t') {|req|
	req.cookies.delete('user')
	req.cookies.delete('pass')
      }
      ok_title 'Login'
      eq false, @site.exist?('_1_wema_1')
    end
  end
end
