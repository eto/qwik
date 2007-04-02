# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Action
    def c_tdiary_resolve(w)
      w = TDiaryResolver.resolve(@config, @site, self, w)
      return w
    end

    def c_page_url
      page = @site[@req.base]
      return nil if page.nil?
      return page.url
    end
  end

  class TDiaryResolver
    def initialize(config, site, action)
      @config = config
      @site = site
      @action = action

      @global_id = 0

      t = @site.siteconfig['titlelink']
      @titlelink = (t == 'true')

      t = @site.siteconfig['emode_titlelink']
      @emode_titlelink = (t == 'true')
    end
    attr_reader :titlelink, :emode_titlelink	# for test

    def self.resolve(config, site, action, wabisabi)
      resolver = self.new(config, site, action)
      w = resolver.resolve(wabisabi)
      return w
    end

    def resolve(wabisabi)
      days = []
      section = []
      days << section
      wabisabi.each {|e|
	if is_title?(e)
	  if 0 < section.size
	    section = []
	    days << section
	  end
	end
	section << e
      }

      @global_id = 0
      ar = []
      days.each {|section|
	title = ''
	title = section.shift if is_title?(section[0])
	ar += tdiary_section(title, section)
      }
      ar
    end

    def encode_label(name)	# used at act-toc.rb
      if name.nil? || name.empty?
	@global_id += 1
	return @global_id.to_s
      end

      if /\A[A-Za-z0-9\-_:. ]+\z/ =~ name
	name.gsub!(/[^A-Za-z0-9\-_]+/, '_')
	name.squeeze!('_')
	name.chomp!('_')
	name.sub!(/\A_/, '')
	name = 'a' + name if /\A[A-Za-z]/ !~ name
	return name
      end

      if @emode_titlelink
	name = name+'<span class="e"><br></span>' # adhoc
	name = name.md5.base64
	name.gsub!(/=/, '')
	name.gsub!(/\+/, '-')
	name.gsub!(/\//, '_')
	return name
      end

      return name.md5hex
    end

    def self.get_title_name(e)	# used at act-toc.rb
      (1..e.length).each {|i|
	if e[i].is_a?(String)
	  return e[i].to_s.strip
	end
      }
      return ''
    end

    private

    def is_title?(e)
      e.is_a?(Array) && e[0] == :h2
    end

    def make_title_link(e)
      return e if e.length < 2

      name = TDiaryResolver.get_title_name(e)
      label = encode_label(name)

      url = @action.c_page_url
      href = "#{url}#"+label

      if (@titlelink || @emode_titlelink)
	m = "¡"
	e.insert(1, [:a, {:class=>'label', :href=>href, :name=>label}, m])
	return e 
      end

      e.insert(1, {:id=>label})
      e
    end

    def tdiary_section(title, section)
      title = make_title_link(title)
      return [
	[:div, {:class=>'day'},
	  title,
	  [:div, {:class=>'body'},
	    [:div, {:class=>'section'},
	      section],
	    [:"!--", 'section']],
	  [:"!--", 'body']],
	[:"!--", 'day']
      ]
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestTDiaryResolver < Test::Unit::TestCase
    include TestSession

    def ok_t(e, s)
      res = Qwik::TDiaryResolver.new(@config, @site, @action)
      ok_eq(e, res.make_title_link(s))
    end

    def test_basic
      res = session

      res = Qwik::TDiaryResolver.new(@config, @site, @action)

      Qwik::TDiaryResolver.instance_eval {
	public :is_title?
	public :encode_label
	public :tdiary_section
	public :make_title_link
      }

      # test_is_title?
      ok_eq(true,  res.is_title?([:h2, 't']))
      ok_eq(false, res.is_title?([:h3, 't']))

      # test_encode_label
      ok_eq('1',  res.encode_label(''))
      ok_eq('2',  res.encode_label(''))
      ok_eq('t',  res.encode_label('t'))
      ok_eq('3',  res.encode_label(''))

      ok_eq('t_t',  res.encode_label('t t'))
      ok_eq('t_t',  res.encode_label('t_t'))
      ok_eq('t-t',  res.encode_label('t-t'))
      ok_eq('930149ca7573114b0341159c94380421', res.encode_label("t!"))

      # test_tdiary_section
      t = res.tdiary_section([:h2, 't'], 'section')
      ok_eq([[:div, {:class=>'day'},
		       [:h2, {:id=>'t'}, 't'],
		       [:div, {:class=>'body'},
			 [:div, {:class=>'section'}, 'section'],
			 [:"!--", 'section']],
		       [:"!--", 'body']],
		     [:"!--", 'day']],
		   t)

      ok_eq([:div, {:class=>'day'},
		     [:h2, {:id=>'t'}, 't'],
		     [:div, {:class=>'body'},
		       [:div, {:class=>'section'}, 'section']]],
		   t.remove_comment.get_single)

      # test_make_title_link
      res = session

      ok_t([:h2, {:id=>'t'}, 't'], [:h2, 't'])

      config = @site['_SiteConfig']
      config.store(':titlelink:true')

      ok_t([:h2, [:a, {:href=>"FrontPage.html#t", :name=>'t',
		     :class=>'label'}, "¡"], 't'],
	       [:h2, 't'])

      ok_t([:h2, [:a, {:name=>'8f03c3a6dbec1d0f1a5af60947b7b052',
		     :class=>'label',
		     :href=>"FrontPage.html#8f03c3a6dbec1d0f1a5af60947b7b052"},
		   "¡"], "‚ "],
	       [:h2, "‚ "])
    end

    def test_emode
      res = session

      Qwik::TDiaryResolver.instance_eval {
	public :encode_label
      }

      config = @site['_SiteConfig']
      config.store(':emode_titlelink:true')
      res = Qwik::TDiaryResolver.new(@config, @site, @action)
      ok_eq('t',  res.encode_label('t'))
      ok_eq('zNC0vEuG7ZsGqzX0C5tyRQ',  res.encode_label("t!"))
      ok_eq('ZHQyWazgdpeYgxXBvfV-jA',  res.encode_label("‚ "))

      ok_t([:h2, [:a, {:href=>"FrontPage.html#t", :name=>'t',
		     :class=>'label'}, "¡"], 't'],
	       [:h2, 't'])
      ok_t([:h2, [:a, {:name=>'ZHQyWazgdpeYgxXBvfV-jA',
		     :class=>'label',
		     :href=>"FrontPage.html#ZHQyWazgdpeYgxXBvfV-jA"},
		   "¡"], "‚ "],
	       [:h2, "‚ "])
    end

    def ok_res(e, wabisabi)
      res = Qwik::TDiaryResolver.new(@config, @site, @action)
      w = res.resolve(wabisabi).remove_comment
      ok_eq(e, w)
    end

    def test_tdiary_resolve
      res = session
      ok_res([[:div, {:class=>'day'}, '',
		 [:div, {:class=>'body'}, [:div, {:class=>'section'}, []]]]],
	     '')
      ok_res([[:div, {:class=>'day'},
		 [:h2, {:id=>'t'}, 't'],
		 [:div, {:class=>'body'}, [:div, {:class=>'section'}, []]]]],
	     [[:h2, 't']])
      ok_res([[:div, {:class=>'day'},
		 [:h2, {:id=>'h2'},'h2'],
		 [:div, {:class=>'body'},
		   [:div, {:class=>'section'},
		     [[:p, 'text of h2'], [:h3, 'h3'], [:p, 'text of h3']]]]]],
	     [[:h2, 'h2'],
	       [:p, 'text of h2'],
	       [:h3, 'h3'],
	       [:p, 'text of h3']])
      ok_res([[:div, {:class=>'day'},
		 [:h2, {:id=>'h2'},'h2'],
		 [:div, {:class=>'body'},
		   [:div, {:class=>'section'}, [[:p, 'text of h2']]]]],
	       [:div, {:class=>'day'},
		 [:h2, {:id=>'h2_2'},'h2 2'],
		 [:div, {:class=>'body'},
		   [:div, {:class=>'section'}, [[:p, 'text of h2 2']]]]]],
	     [[:h2, 'h2'],
	       [:p, 'text of h2'],
	       [:h2, 'h2 2'],
	       [:p, 'text of h2 2']])

      # test_tdiary_resolve_with_titlelink
      config = @site['_SiteConfig']
      config.store(':titlelink:true')
      ok_res([[:div, {:class=>'day'},
		 [:h2, [:a, {:name=>'t', :class=>'label',
		       :href=>"FrontPage.html#t"}, "¡"], 't'],
		 [:div, {:class=>'body'}, [:div, {:class=>'section'}, []]]]],
	     [[:h2, 't']])
    end
  end
end
