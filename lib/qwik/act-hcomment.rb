#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '../../lib' unless $LOAD_PATH.include?('../../lib')

module Qwik
  class Action
    def plg_hcomment(style='0')
      action = @req.base+'.hcomment'

      style = style.to_i
      style = 0 if style != 1

      # @hcomment_num is global for an action.
      @hcomment_num = 0 if !defined?(@hcomment_num)
      @hcomment_num += 1
      num = @hcomment_num

      return [:div, {:class=>'hcomment'},
	[:form, {:method=>'POST', :action=>action},
	  _('Name'), ': ', [:input, {:name=>'name', :size=>10}], ' ',
	  _('Comment'), ': ', [:input, {:name=>'msg', :size=>50}], ' ',
	  [:input, {:type=>'submit', :name=>'comment', :value=>_('Submit')}],
	  [:input, {:type=>'hidden', :name=>'comment_no', :value=>num}],
	  [:input, {:type=>'hidden', :name=>'style', :value=>style}]]]
    end

    def ext_hcomment
      #c_require_login	# Guest can post.
      c_require_post

      date = @req.start_time.ymdx
      user = @req.query['name']
      user = _('Anonymous') if user.nil? || user.empty?
      msg = @req.query['msg']
      return c_nerror('no message') if msg.nil? || msg.empty?
      content = "- #{date} '''#{user}''' : #{msg}\n"

      comment_no = @req.query['comment_no'].to_i
      comment_no = 1 if comment_no < 1
      style = @req.query['style'].to_i
      style = 0 if style != 1

      page = @site[@req.base]
      str = page.load
      md5 = str.md5hex

      new_str, written = hcomment_add_to_page(str, comment_no, style, content)

      return c_nerror(_('Failed')) if !written

      begin
	page.put_with_md5(new_str, md5)
      rescue PageCollisionError
	return hcomment_error(_('Page collision detected.'))
      end

      c_make_log('hcomment') # COMMENT

      url = @req.base+'.html'
      return c_notice(_('Add a comment.'), url){
	[[:h2, _('Message is added.')],
	  [:p, [:a, {:href=>url}, _('Go back')]]]
      }
    end

    def hcomment_error(msg, url)
	return c_nerror(msg){
	  [[:h2, msg],
	    [:p, msg],
	    [:p, _('Go back and input again.')],
	    [:dl,
	      [:dt, _('Name')], [:dd, user],
	      [:dt, _('Comment')], [:dd, msg],
	    [:p, [:a, {:href=>url}, _('Go back')]]]]
      }
    end

    def hcomment_add_to_page(str, comment_no, style, content)
      new_str = ''
      num = 1
      written = false
      str.each {|line|
	if /\A\{\{hcomment/ =~ line && !written
	  if num == comment_no
	    new_str << content if style == 0 # new comment is on the bottom.
	    new_str << line
	    new_str << content if style == 1 # new comment is on the top.
	    written = true
	  else
	    new_str << line
	    num += 1
	  end
	else
	  new_str << line
	end
      }
      return new_str, written
    end

  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActHComment < Test::Unit::TestCase
    include TestSession

    def test_plg_hcomment
      ok_wi([:div, {:class=>'hcomment'},
	      [:form, {:action=>'1.hcomment', :method=>'POST'},
		'Name', ': ', [:input, {:size=>10, :name=>'name'}], ' ',
		'Comment', ': ', [:input, {:size=>50, :name=>'msg'}], ' ',
		[:input, {:value=>'Submit', :type=>'submit', :name=>'comment'}],
		[:input, {:value=>1, :type=>'hidden', :name=>'comment_no'}],
		[:input, {:value=>0, :type=>'hidden', :name=>'style'}]]],
	    '{{hcomment}}')
    end

    def test_ext_hcomment
      t_add_user

      page = @site.create_new
      page.store("{{hcomment}}\n")
      res = session('POST /test/1.hcomment?name=n&msg=m&comment_no=1&style=0')
      ok_eq("- 1970-01-01 09:00:00 '''n''' : m\n{{hcomment}}\n",
	    page.load)

      page.store("{{hcomment(1)}}\n")
      res = session('POST /test/1.hcomment?name=n&msg=m&comment_no=1&style=1')
      ok_eq("{{hcomment(1)}}\n- 1970-01-01 09:00:00 '''n''' : m\n",
	    page.load)
    end
  end
end
