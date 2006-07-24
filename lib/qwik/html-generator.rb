# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

module HtmlGeneratorUnit
  def a(arg=[], title=nil, &block)
    if arg.kind_of?(String)
      ha = {:href=>arg}
      ha.update(:title=>title) if title
      return make(:a, ha, &block)
    end
    make(:a, arg, &block)
  end

  def img(src='', alt='')
    make(:img, {:src=>src, :alt=>alt})
  end

  def text(name='', value=nil, size=nil, maxsize=nil)
    hash = {:name=>name, :value=>value, :size=>size, :maxsize=>maxsize}
    hash.delete_if {|k, v| v.nil? }
    make(:input, hash)
  end

  def password(name='', value=nil, size=nil)
    hash = {:type=>'password', :name=>name, :value=>value, :size=>size}
    hash.delete_if {|k, v| v.nil? }
    make(:input, hash)
  end

  def form(a=nil, b=nil, c=nil, &block)
    ar = []
    if a.is_a? Hash
      ar << a
    else
      ar << {:method=>a} if a
      ar << {:action=>b} if b
      ar << {:enctype=>c} if c
    end
    make(:form, ar, &block)
  end

  def hidden(a='', b=nil)
    ar = []
    if a.is_a? Hash
      ar << a
    else
      ar << {:type=>'hidden'}
      ar << {:name=>a}
      ar << {:value=>b} if b
    end
    make(:input, ar)
  end

  def select(name='', *args)
    ar = []
    args.each {|arg|
      ar << make(:option, {:name=>arg}){arg}
    }
    make(:select, {:name=>name}){ar}
  end

  def textarea(name='', cols=nil, rows=nil, &block)
    hash = {:name=>name, :cols=>cols, :rows=>rows}
    hash.delete_if {|k, v| v.nil? }
    make(:textarea, hash){
      block.call
    }
  end

  def submit(value=nil, name=nil)
    hash = {:type=>'submit', :name=>name, :value=>value}
    hash.delete_if {|k, v| v.nil? }
    make(:input, hash)
  end

  def radio(a='', b=nil, c=nil)
    ar = []
    if a.is_a? Hash
      a.update(:type=>'radio')
      ar << a
    else
      ar << {:type=>'radio'}
      ar << {:name=>a}
      ar << {:value=>b} if b
      ar << {:checkd=>'checkd'} if c
    end
    make(:input, ar)
  end

  def contenttype(content='')
    make(:meta, {'http-equiv'=>'Content-Type', :content=>content})
  end

  def stylesheet(url='', media=nil)
    hash = {:rel=>'stylesheet', :type=>'text/css', :href=>url, :media=>media}
    hash.delete_if {|k, v| v.nil? }
    make(:link, hash)
  end

  def refresh(sec=0, url='')
    make(:meta, {'http-equiv'=>'Refresh', :content=>"#{sec}; url=#{url}"})
  end
end
