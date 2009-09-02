# Copyright (C) 2009 AIST, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

=begin
$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

require 'qwik/act-backup'

module Qwik
  class Action
    def plg_rrefs
        rrefs = @site.rrefs(@req.base)
	wabisabi = []
	if rrefs
	  w = []
          rrefs.each{|key| 
	    page = @site[key]
	    if page
	      w.push([:span, {:class => "rref"}, [:a, {:href => "#{key}.html"}, page.get_title]])
	    else
	      rrefs.delete(key)
	    end
	  }
	  if w.size > 0
	    wabisabi = [:div, {:class => "rrefs"}] + w
	  end
	end
        return wabisabi
    end

    private
    def clear_rrefs(mykey)
      @site.each {|page|
	page.rrefs.delete(mykey) unless page.rrefs.nil?
      }
    end

    def create_rrefs(mykey)
      links = find_links_to_this_page(mykey)
      @site.rrefs(mykey).put(links) if links.size > 0
    end
    
    def find_links_to_this_page(mykey)
      links = []
      @site.each {|page|
        l = extract_wiki_links(page.get)
        if l.include?(mykey)
          links.push(page.key)
        end
      }
      links
    end

    def update_rrefs
      list = backup_list(@site,@req.base)
      # new page already has two pages at this point
      list = list.sort {|a,b| a[1] <=> b[1]}[-2..-1]
      if list
        links = list.map{|w|
          extract_wiki_links(w[0])
        }

        new_links = links[1] - links[0]
        deleted_links = links[0] - links[1]

        update_links(new_links,"add") 
        update_links(deleted_links,"delete") 
      end
    end

    def update_links(links, method)
      links.each {|key|
        rrefs = @site.rrefs(key)
	rrefs.send(method, @req.base) unless rrefs.nil?
      }
    end

    def extract_wiki_links(wiki)
      links = []
      wabisabi = wiki_to_wabisabi(wiki)
      wabisabi.each_tag(:a) {|e|
        href = e.attr[:href]
        if (!href.nil? and !href.empty?)
          key = href_to_key(href)
         links.push(key) if !key.nil?
       end
      }
      return links
    end

    def wiki_to_wabisabi(wiki)
      tokens = Qwik::TextTokenizer.tokenize(wiki)
      return Qwik::TextParser.make_tree(tokens)
    end

    def href_to_key(href)
      #fix me! this is from site-reslove.rb#resolve_ref
      return nil if /^(?:http|https|ftp|file):\/\// =~ href
      return nil if href.include?('?')    # ignore command link
      return nil if href[0] == ?/ # already resolved
      return nil if /\.html\z/ !~ href    # ignore not html file
      key = href.sub(/\.html\z/, '')
      page = @site.get_by_title(key)
      if page && page.key != key
        key = page.key
      end
      return key
    end    
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActRRefs < Test::Unit::TestCase
    include TestSession

    def test_plg_rrefs
      t_add_user
      #test empty rrefs
      ok_wi([],'{{rrefs}}')

      page = @site['_PageAttribute']
      page.store('{{rrefs}}')

      ## assertion for a new page  
      #create page contatins a link to page2
      res = session('POST /test/.new?t=page1')
      res = session('/test/page1.save?contents=%5b%5bpage2%5d%5d')

      #create page2
      res = session('POST /test/.new?t=page2')
      res = session('/test/page2.save?contents=page2')

      #load page2
      res = session('/test/page2.html')

      #check if page2 has a rref to page1
      ok_xp([:div, {:class => "rrefs"}, [:span, {:class => "rref"}, [:a, {:href => "page1.html"}, "page1"]]],'//div[@class="rrefs"]/')


      ## assertion for adding a link to existing page 
      #ensure to differ backup epoch time of page2
      sleep(1)

      #modify page2 to add a link to page1
      res = session('/test/page2.edit')
      md5hex = session_md5(res.body)
      res = session('/test/page2.save?contents=page2%5b%5bpage1%5d%5d&md5hex=' + md5hex)
      ok_in(['Page is saved.'],'title')

      #check if page1's rrefs has page2
# comment outed due to cache issue.
#      ok_eq("page2" + $/, @site["page1"].rrefs.get)

      #load page1
      res = session('/test/page1.html')

      #check if page1 has a rref to page2
      ok_xp([:div, {:class => "rrefs"}, [:span, {:class => "rref"}, [:a, {:href => "page2.html"}, "page2"]]],'//div[@class="rrefs"]/')

      ## assetion for deleting a link to page
      #ensure to differ backup epoch time of page2
      sleep(1)

      #modify page2 to delete a link to page1
      res = session('/test/page2.edit')
      md5hex = session_md5(res.body)
      res = session('/test/page2.save?contents=page2&md5hex=' + md5hex)
      ok_in(['Page is saved.'],'title')

      #check if page1's rrefs has no content
# comment outed due to cache issue.
#      ok_eq("",@site["page1"].rrefs.get)

      ## assetion for deleting page1
      res = session('/test/page1.edit')
      md5hex = session_md5(res.body)
      res = session('/test/page1.save?contents=&md5hex=' + md5hex)
      ok_in(['Page is deleted.'],'title')
      
      #check if page2's rrefs has no content
# comment outed due to cache issue.
#      ok_eq("",@site["page2"].rrefs.get)
    end

#=begin
    # check exclusive rrefs update
    # this test takes too long to run as regression
    # please uncomment when needed to test
    def test_multi_pages_update
      t_add_user

     
      # number of pages to update at once.
      # This number should be even.
      # Adequate number is upto the test environment.
      num = 300

      #create pages0~num
      0.upto(num){|i|
        t = "page#{i}"
        res = session("POST /test/.new?t=#{t}")
	if ((i&0x1) == 0x1) #odd pages have a link to page0
          res = session("/test/#{t}.save?contents=%5b%5bpage0%5d%5d")
	else #even pages have no links
          res = session("/test/#{t}.save?contents=#{t}")
	end
      }

      #update page1~num
      1.upto(num) {|i|
	  p = "page#{i}"
	  res = session("/test/#{p}.edit")
      }
      sleep(1)

      ths = []
      1.upto(num) {|i|
        ths[i] = Thread.new {
	  p = "page#{i}"
	  if ((i&0x1) == 0x1) #odd pages: remove a link to page0
	    res = session("/test/#{p}.save?contents=page0")
	  else #even pages: add a link to page0
	    res = session("/test/#{p}.save?contents=%5b%5bpage0%5d%5d")
	  end
        }
      }
      1.upto(num){|i|
        ths[i].join
      }

      #check if page0's rrefs has num/2 pages
      r = @site["page0"].rrefs.get.sort
      ok_eq(num/2,r.to_a.size)
    end
#=end

    private
    def session_md5(body)
      md5hex = nil
      body.each_tag(:input) {|e|
        if e.attr[:name] == "md5hex"
          md5hex = e.attr[:value]
	end
      }
      return md5hex
    end
  end
end
=end
