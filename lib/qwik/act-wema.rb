$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'
require 'qwik/act-monitor'

module Qwik
  $wema_debug = false
  $wema_redirect = true

  class Action
    D_plugin_wema = {
      :dt => 'Post-it plugin',
      :dd => 'You can put post-it notes on the page.',
      :dc => "* How to
From the page attribute, please click 'New Post-it' link.
You can see a small window.  Enter some text and save it.
You can move the small window and click set for setting the position.
"
    }

    Dja_plugin_wema = {
      :dt => '附箋機能 ',
      :dd => '附箋をはることができます。',
      :dc => '* 使用法
ページの下に、「New Post-it」というリンクがあるので、押してください。
小さなWindowが表示さます。なにかテキストをいれ、セーブしてください。
Windowを動かして、「set」を押すと位置をセットします。
'
    }

    def plg_wema
      page = @site[@req.base]
      return unless defined?(page)
      return if page.nil?
      return if defined?(@wema_generated)
      @wema_generated = true
      wp = WemaPage.new(@site, page)
      gen = WemaHtmlGenerator.new(self, wp)
      return gen.generate
    end

    def ext_wema
      c_require_post

      page = @site[@req.base]
      wp = WemaPage.new(@site, page)
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
	  wema = wp[id]
	  msg = _('Edit done.')
	end

	wema.set(connected, left, top, fg, bg, text)
	c_make_log('wemaedit') # WEMAEDIT
	#c_monitor('wemaedit') # WEMAEDIT
	return wema_jump(msg, redirect)

      when 'delete'
	if wid.nil? || wid.empty?
	  return wema_jump(_('No action.'), redirect)
	end

	id = wid.sub(/\Aid/, '').to_i
	wema = wp[id]
	wp.delete(id)
	c_make_log('wemadelete') # WEMADELETE
	#c_monitor('wemadelete') # WEMADELETE
	return wema_jump(_('Delete a Post-it.'), redirect)

      when 'setpos'
	wid = nil if wid.empty?
	return c_nerror('wid is nil') if wid.nil?
	  
	id = wid.sub(/\Aid/, '').to_i
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

    def hash(ha)
      return nil if ha.nil? || ha.length == 0
      return [:dl, ha.sort.map {|k, v| [[:dt, k], [:dd, v]] }.flatten]
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
    attr_reader :site, :pagename, :wemas

    def touch
      @page.touch
    end

    def create_new
      return create(get_new_id)
    end

    def get_new_id
      list = get_list
      return 1 if list.empty?
      list.max + 1
    end

    def create(id)
      Wema.new(self, id)
    end

    def delete(k)
      self[k].delete
      @wemas[k] = nil
    end

    def get_list
      list = []
      @site.to_a(true).each {|page| # true means get all
	if /\A_#{@pagename}_wema_([0-9]+)\z/ =~ page.key
	  list << $1.to_i
	end
      }
      list
    end

    def [](id)
      get_wemas
      @wemas.each {|wema|
	return wema if wema.id == id
      }
      nil
    end

    def get_wemas
      @wemas = get_list.map {|id|
	Wema.new(self, id)
      }
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

    def get_id
      return "id#{@id}"
    end

    def key(id)
      return "_#{@wemapage.pagename}_wema_#{id}"
    end

    def delete
      @site.delete(key(id))
    end

    def parse(str)
      lines = str.to_a
      f = lines.shift # first line
      return if f.nil?
      f.chomp!
      dummy, @connected, @x, @y, @fg, @bg = f.split(',')
      @text = lines.join('')
    end

    def set(connected, x, y, fg, bg, text)
      set_px(x){|a| @x = a }
      set_px(y){|a| @y = a }
      set_color(fg){|a| @fg = a }
      set_color(bg){|a| @bg = a }
      set_text(text){|a| @text = a }
      set_str(connected){|a| @connected = a }
      store
    end

    def store
      str = [nil, @connected, @x, @y, @fg, @bg].join(',')+"\n"
      str << @text.to_s
      @page.store(str)
    end

    def setpos(x, y)
      set(nil, x, y, nil, nil, nil)
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
    def initialize(action, wemapage)
      @action = action
      @wemapage = wemapage
      @site = @wemapage.site
    end

    def _(s)
      @action._(s)
    end

    def generate
      ar = [:div]

      # load the CSS first.
      ar << [:style, "@import '.theme/css/wema.css';"]

      ar << [:span, {:class=>'attribute'}, 'Post-it', ': ',
	[:a, {:href=>'javascript:wema_editor_show()'}, 'New Post-it'],
	' (', [:a, {:href=>'javascript:wema_help_show()'}, 'help'], ')']

      # make divs of the all wemas.
      @wemapage.get_wemas
      @wemapage.wemas.each {|wema|
	ar << get_div(wema)
      }

      ar << editor_html(@wemapage.pagename)

      # load JavaScript the last.
      ar << [:script, {:type=>'text/javascript', :src=>'.theme/js/wema.js'}, '']

      ar
    end

    # ============================== wema window
    def get_div(wema)
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

      [:div, {:id=>k, :class=>'wema',
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
    end

    def resolve_href(wabisabi)
      wabisabi.each_tag(:a){|w|
	ww = resolve_ref(w)
	w = ww ? ww : [w]
	w
      }
    end

    def resolve_ref(w)
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
    def editor_html(pagename)
      action = pagename+'.wema'
      [:div, {:id=>'editor', :class=>'wema'},
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
	    [:p, 'Draw Line'+': ', text('ln')],
	    [:p, 'x:', text('l'), ' y:', text('t')],
	    param('id', ''),
	    param('mode', 'edit')]]]
    end

    def font_color
      ar = ['Text color'+': ', [:input, {:id=>'tc', :name=>'tc'}]]
      ar += ['#000', '#600', '#060', '#006'].map {|c| radio_color('tc', c) }
      [:p, ar]
    end

    def bg_color
      ar = ['Background'+': ', [:input, {:id=>'bg', :name=>'bg'}]]
      ar += ['#fff', '#fcc', '#cfc', '#ccf', '#ffc', '#000'].map {|c|
	radio_color('bg', c)
      }
      [:p, ar]
    end

    def radio_color(name, color)
      [:a, {:href=>"javascript:wema_set_color('#{name}', '#{color}')",
	  :class=>'color',
	  :style=>"color:#{color};background:#{color};"}, '[_]']
    end

    def param(*a)
      return text(*a) if $wema_debug
      return hidden(*a)
    end

    def text(a='', b=nil)
      h = {}
      h.update(:name=>a) if a
      h.update(:value=>b) if b
      return [:input, h]
    end

    def hidden(a='', b=nil)
      h = {:type=>'hidden'}
      h.update(:name=>a) if a
      h.update(:value=>b) if b
      return [:input, h]
    end
    private :param, :text, :hidden
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
      page.store('{{wema}}')

      page = @site.create_new

      res = session '/test/1.wema'
      ok_title 'Need POST'

      res = session 'POST /test/1.wema'
      assert_text('Unknown mode: []', 'title')

      res = session 'POST /test/1.wema?mode=edit&body='
      ok_title 'No action.'

      res = session 'POST /test/1.wema?mode=edit&body=t'
      ok_title 'New post-it is created.'
      page = @site['_1_wema_1']
      ok_eq(",,,,,\nt\n", page.load)

      res = session 'POST /test/1.wema?mode=edit&id=id1&body=t2'
      ok_title 'Edit done.'
      page = @site['_1_wema_1']
      ok_eq(",,,,,\nt2\n", page.load)

      res = session 'POST /test/1.wema?mode=setpos&id=id1&l=1&t=2'
      ok_title 'Set position.'
      page = @site['_1_wema_1']
      ok_eq(",,1,2,,\nt2\n", page.load)

      res = session '/test/1.html'
      ok_title '1'
      ok_in(['t2'], "//div[@class='wema']/p")
      ok_in([:p, 't2'], "//div[@class='wema']/div[@class='cont']")

      res = session 'POST /test/1.wema?mode=edit&id=id1&body=* t3'
      ok_title 'Edit done.'
      page = @site['_1_wema_1']
      ok_eq(",,1,2,,\n* t3\n", page.load)

      res = session '/test/1.html'
      ok_in([:h2, 't3'], "//div[@class='wema']/div[@class='cont']")

      res = session 'POST /test/1.wema?mode=edit&id=id1&body={{recent}}'
      ok_title 'Edit done.'
      page = @site['_1_wema_1']
      ok_eq(",,1,2,,\n{{recent}}\n", page.load)

      res = session '/test/1.html'
      ok_in([:plugin, {:method=>'recent', :param=>''}],
	    "//div[@class='wema']/div[@class='cont']")

      res = session 'POST /test/1.wema?mode=edit&id=id1&body=http://e.com/'
      ok_title 'Edit done.'
      page = @site['_1_wema_1']
      ok_eq(",,1,2,,\nhttp://e.com/\n", page.load)

      res = session '/test/1.html'
      ok_xp([:a, {:href=>'.redirect?url=http://e.com/',
		:rel=>'nofollow', :class=>'external'}, 'http://e.com/'],
	    "//div[@class='wema']/p/a")

      res = session 'POST /test/1.wema?mode=edit&id=id1&body='
      ok_title 'Delete a Post-it.'
      page = @site['_1_wema_1']
      ok_eq(nil, page)
    end
  end
end
