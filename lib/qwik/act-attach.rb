# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/act-file'

module Qwik
  class Action
    def act_attach
      if @req.query['c'] == 'del'
	c_require_member
	filename = @req.query['f']
	return attach_delete(filename) if @req.is_post?	# delete it
	return attach_delete_confirm(filename)	# confirm before delete
      end

      args = @req.path_args
      if 0 < args.length	# has target file
	filename = args.join('/')
	filename.set_url_charset
	filename = Filename.decode(filename)
	if ! @site.attach.exist?(filename)
	  return c_notfound(_('No such file'))
	end
	return attach_send_file(filename)	# send it
      end

      content = @req.query['content']
      return attach_put_file(filename, content) if content

      # show attach form and the list of files
      return attach_form_and_list
    end
    alias ext_attach act_attach

    def attach_send_file(filename)
      @res.set_content_type(Filename.extname(filename))
      file = @site.attach.path(filename)
      return c_simple_send(file.to_s)
    end

    def attach_put_file(filename, content)
      c_require_member
      c_require_post

      filename = content.filename
      basename = Action.get_basename(filename)
      basename.set_url_charset
      basename = Filename.decode(basename)
      res = basename
      res = @site.attach.fput(basename, content)

      attach_rewrite_page(res)

      backpage = '.attach'

      return c_notice(_('File attachment completed')) {
	[[:p, [:strong, res], ' : ', _('The file is saved.')],
	  [:p, [:a, {:href=>backpage}, _('Go back')]]]
      }
    end

    def self.get_basename(filename)
      basename = filename.sub(/\A.*[\/\\]([^\/\\]+)\z/) { $1 }
      return basename
    end

    def attach_rewrite_page(basename)
      page = @site[@req.base]
      v = page.load
      if /\{\{ref\}\}/ =~ v
	v.sub!(/\{\{ref\}\}/){ "{{ref(#{basename})}}" }	# only once
	page.store(v)
      end
    end

    def attach_form_and_list
      c_require_member

      div = []
      div << [:div, {:class=>'msg'},
	[:p, _('Attach a file')],
	attach_form]

      list = attach_file_list

      if list
	div << [:br]
	div << [:div, {:class=>'msg'},
	  [:p, _('File list')],
	  [:ul, list]]
      end

      return c_notice(_('Attach file')) { div }
    end

    def attach_form(a=nil)
      return [:form, {:action=>a, :method=>'post',
	  :enctype=>'multipart/form-data'},
	[:input, {:type=>'file', :name=>'content'}],
	[:br],
	[:input, {:type=>'submit', :value=>'attach'}]]
    end

    def attach_file_list
      base = c_relative_to_root('.attach')
      list = []
      @site.attach.each {|file|
	encoded = Filename.encode(file)
	list << [:li, [:a, {:href=>"#{base}/#{encoded}"}, file.to_page_charset],
	  [:span, {:class=>'delete'},
	    ' (', [:a, {:href=>"#{base}?c=del&f=#{encoded}"}, _('Delete')], ')']]
      }
      return nil if list.length == 0
      return list
    end

    def attach_delete_confirm(filename)
      return c_notice(_('Confirm file deletion')) {
	[:form, {:method=>'POST', :action=>'.attach'},
	  [:p, _("Push 'Delete' to delete a file")],
	  [:input, {:type=>'hidden', :name=>'c', :value=>'del'}],
	  [:input, {:type=>'hidden', :name=>'f', :value=>filename}],
	  [:p, [:input, {:type=>'submit', :value=>_('Delete')}]]]
      }
    end

    def attach_delete(filename)
      c_require_post
      url = '.attach'
      begin
	filename.set_url_charset
	filename = Filename.decode(filename)
	@site.attach.delete(filename)
      rescue FileNotExist
	return c_nerror(_('Already deleted.'), url)
      rescue FailedToDelete
	return c_nerror(_('Failed to delete.'), url)
      end
      return c_notice(_('The file has been deleted.')) {
	[:p, [:a, {:href=>url}, _('Go back')]]
      }
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActAttach < Test::Unit::TestCase
    include TestSession

    def test_attach
      # Only member can access attach form.
      res = session('/test/.attach')
      ok_title('Members Only')

      t_add_user

      # Check directory.
      ok_eq('.test/data/test', @site.path.to_s)
      attach_path = @site.path+'.attach'
      ok_eq('.test/data/test/.attach', attach_path.to_s)

      filename = 't.txt'
      file = attach_path+filename
      file.unlink if file.exist?

      # See form.
      res = session('/test/.attach')
      ok_title('Attach file')
      ok_xp([:form, {:method=>'post', :action=>nil,
		:enctype=>'multipart/form-data'},
	      [:input, {:type=>'file', :name=>'content'}],
	      [:br],
	      [:input, {:value=>'attach', :type=>'submit'}]],
	    "//div[@class='msg']/form")

      # Try to get a file.  But there is no file yet.
      res = session('/test/.attach/t.txt')
      ok_title('No such file')

      d = @dir+'.attach'
      d.erase_all_for_test if d.exist?

      # Put a file.
      res = session('POST /test/.attach') {|req|
	req.query.update('content'=>t_make_content('t.txt', 't'))
      }
      ok_title('File attachment completed')

      # Get the file.
      res = session('/test/.attach/t.txt')
      ok_eq('text/plain', res['Content-Type'])
      ok_eq('t', res.body)

      # Put a file with same file name again.
      # The file is saved as another filename.
      res = session('POST /test/.attach') {|req|
	req.query.update('content'=>t_make_content('t.txt', 't2'))
      }
      ok_title('File attachment completed')

      # Show the list of attached files.
      res = session('/test/.attach')
      ok_title('Attach file')
      ok_xp([:form, {:method=>'post', :action=>nil,
		:enctype=>'multipart/form-data'},
	      [:input, {:type=>'file', :name=>'content'}],
	      [:br],
	      [:input, {:value=>'attach', :type=>'submit'}]],
	    "//div[@class='msg']/form")
      ok_xp([:a, {:href=>'/test/.attach/1-t.txt'}, '1-t.txt'], '//ul/li/a[1]')
      ok_xp([:a, {:href=>'/test/.attach?c=del&f=1-t.txt'}, 'Delete'],
	    '//ul/li/a[2]')
      ok_xp([:a, {:href=>'/test/.attach/t.txt'}, 't.txt'], '//ul/li[2]/a[1]')
      ok_xp([:a, {:href=>'/test/.attach?c=del&f=t.txt'}, 'Delete'],
	    '//ul/li[2]/a[2]')

      # Show a form to delete the file.
      res = session('/test/.attach?c=del&f=t.txt')
      ok_title('Confirm file deletion')

      # Delete it.
      res = session('POST /test/.attach?c=del&f=t.txt')
      ok_title('The file has been deleted.')

      # Try to delete it again.  But the file is already deleted.
      res = session('POST /test/.attach?c=del&f=t.txt')
      ok_title('Already deleted.')

      # Try to get file agin.  But the file is already deleted.
      res = session('/test/.attach/t.txt')
      ok_title('No such file')
    end

    def test_attach_with_rewrite
      t_add_user

      file = @site.attach.path('t.txt')
      file.unlink if file.exist?

      # See the page.
      ok_wi([], '{{ref}}')

      page = @site['1']
      ok_eq('{{ref}}', page.load)

      # Put a file.
      res = session('POST /test/1.attach') {|req|
	req.query.update('content'=>t_make_content('t.txt', 't'))
      }
      ok_title('File attachment completed')
      ok_eq('{{ref(t.txt)}}', page.load)

      res = session('/test/1.html')
      ok_xp([:div, {:class=>"section"},
	      [[:div, {:class=>'ref'},
		  [:a, {:href=>'.attach/t.txt'}, 't.txt']]]],
	    "//div[@class='section']")
    end

    def test_attach_with_dir
      t_add_user

      d = @dir+'.attach'
      d.erase_all_for_test if d.exist?

      # Try to get a file.
      res = session('/test/.attach/.thumb/t.jpg')
      ok_title('No such file')

      thumb_dir = d+'.thumb'
      thumb_dir.check_directory
      thumb = thumb_dir+'t.jpg'
      thumb.put('dummy')

      res = session('/test/.attach/.thumb/t.jpg')
      ok_eq('dummy', res.body)
      ok_eq('image/jpeg', @res['Content-Type'])
    end

    def test_attach_to_page
      t_add_user

      page = @site.create_new
      page.store('t')

      # See form.
      res = session('/test/1.attach')
      ok_title('Attach file')
      ok_xp([:form, {:method=>'post', :action=>nil,
		:enctype=>'multipart/form-data'},
	      [:input, {:type=>'file', :name=>'content'}],
	      [:br],
	      [:input, {:value=>'attach', :type=>'submit'}]],
	    "//div[@class='msg']/form")
    end
  end
end
