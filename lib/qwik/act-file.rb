# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/page-images'

module Qwik
  class Action
    def plg_file(f=nil, alt=f, base=@req.base)
      return if f.nil?

      encoded = Filename.encode(f)
      href     = "#{base}.files/#{encoded}"
      download = "#{base}.download/#{encoded}"

      files = @site.files(base)
      if files.nil? || ! files.exist?(f)
	src = icon_path('broken')
	return [:div, {:class=>'ref'}, 
	  [:a, {:href=>href},
	    [:img, {:class=>'icon', :src=>src, :alt=>alt}],
	    [:br], alt]]
      end

      src = thumb_check(f)
      if src
	return [:div, {:class=>'ref'}, 
	  [:a, {:href=>href},
	    [:img, {:class=>'thumb', :src=>src, :alt=>alt}],
	    [:br], alt],
	  [:br],
	  [:a, {:href=>download}, 'download']
	]
      end

      ext = Filename.extname(f)
      src = icon_find(ext)
      if src
	return [:div, {:class=>'ref'}, 
	  [:a, {:href=>href},
	    [:img, {:class=>'icon', :src=>src, :alt=>alt}],
	    [:br], alt],
	  [:br],
	  [:a, {:href=>download}, 'download']
	]
      end

      return [:div, {:class=>'ref'},
	[:a, {:href=>href}, alt]]
    end

    def file_html(href, klass, src, alt, message)
      return [:div, {:class=>'ref'}, 
	[:a, {:href=>href},
	  [:img, {:class=>klass, :src=>src, :alt=>alt}],
	  [:br], message]]
    end

    def plg_imgfile(f=nil, alt=f, base=@req.base)
      return nil if f.nil?
      src = base+'.files/'+f
      return [:img, {:src=>src, :alt=>alt}]
    end

    # ============================== thumbnail
    def thumb_generate(f)
      files = @site.files(@req.base)
      files.generate_thumb(f)	# page-images.rb
      return @req.base+'.files/.thumb/'+f.to_s
    end

    def thumb_check(f)
      ext = Filename.extname(f)
      return thumb_generate(f) if PageFiles.is_image?(ext)
      return nil
    end

    # ============================== icon
    ICON_SUF_TABLE = {
      'tgz'	=> 'tar',
    }

    ICON_MIMETYPE_TABLE = {
      'application/octet-stream'	=> 'binary',
      'application/pdf'			=> 'pdf',
      'application/postscript'		=> 'ps',
      'application/zip'			=> 'compressed',
    }

    ICON_GENRE_TABLE = {
      'application'	=> 'a',
      'audio'		=> 'sound2',
      'image'		=> 'image2',
      'message'		=> 'text',
      'model'		=> 'sphere2',
      'multipart'	=> 'text',
      'text'		=> 'text',
      'video'		=> 'movie',
    }

    def icon_find(ext)
      mimetype = @res.get_mimetypes ext
      return icon_find_internal(mimetype, ext)
    end

    def icon_find_internal(mimetype, ext)
      ext.downcase!

      type = ICON_SUF_TABLE[ext]
      return icon_path(type) if type

      if mimetype
	type = ICON_MIMETYPE_TABLE[mimetype]
	if type
	  path = icon_path(type)
	  return path if path
	end

	genre, spec = mimetype.split('/')
	type = ICON_GENRE_TABLE[genre]
	if type
	  path = icon_path(type)
	  return path if path
	end
      end

      return icon_path('generic')
    end

    def icon_path(type)
      return icon_path_internal(@config.theme_dir.path+'i', type)
    end

    def icon_path_internal(path, type)
      file = "#{type}.gif"
      return nil unless (path+file).exist?
      return ".theme/i/#{file}"
    end

    # ============================== ref
    def plg_ref(f=nil, alt=f)
      return nil if f.nil?
      return [:div, {:class=>'ref'}, 
	[:a, {:href=>'.attach/'+f}, alt]]
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  require 'qwik/act-attach'
  $test = true
end

if defined?($test) && $test
  class TestActFile < Test::Unit::TestCase
    include TestSession

    def test_all
      ok_wi('', '')

      files = @site.files('1')

      if files.exist?('1x1.png')
	files.delete('1x1.png')
      end

      ok_wi([], '{{file}}')

      ok_wi([:div, {:class=>'ref'},
	      [:a, {:href=>'1.files/1x1.png'},
		[:img, {:alt=>'1x1.png', :class=>'icon',
		    :src=>'.theme/i/broken.gif'}],
		[:br], '1x1.png']],
	    '{{file(1x1.png)}}')

      png = TEST_PNG_DATA
      files.fput('1x1.png', png)
      ok_wi([:div, {:class=>'ref'},
	      [:a, {:href=>'1.files/1x1.png'},
		[:img, {:alt=>'1x1.png',
		    :class=>'thumb', :src=>'1.files/.thumb/1x1.png'}],
		[:br], '1x1.png'],
	      [:br],
	      [:a, {:href=>'1.download/1x1.png'}, 'download']],
	    '{{file(1x1.png)}}')

      files.delete('test.pdf') if files.exist?('test.pdf')
      pdf = 'PDF...dummy'
      files.fput('test.pdf', pdf)
      ok_wi([:div, {:class=>'ref'},
	      [:a, {:href=>'1.files/test.pdf'},
		[:img, {:alt=>'test.pdf',
		    :class=>'icon', :src=>'.theme/i/pdf.gif'}],
		[:br], 'test.pdf'],
	      [:br],
	      [:a, {:href=>'1.download/test.pdf'}, 'download']],
	    '{{file(test.pdf)}}')

      files.delete('test.txt') if files.exist?('test.txt')
      file = 'text file dummy'
      files.fput('test.txt', file)
      ok_wi([:div, {:class=>'ref'},
	      [:a, {:href=>'1.files/test.txt'},
		[:img, {:alt=>'test.txt',
		    :class=>'icon', :src=>'.theme/i/text.gif'}],
		[:br], 'test.txt'],
	      [:br],
	      [:a, {:href=>'1.download/test.txt'}, 'download']],
	    '{{file(test.txt)}}')

      if files.exist?('test.nosuchext')
	files.delete('test.nosuchext')
      end

      file = 'unknown file dummy'
      files.fput('test.nosuchext', file)
      ok_wi([:div, {:class=>'ref'},
	      [:a, {:href=>'1.files/test.nosuchext'},
		[:img,
		  {:alt=>'test.nosuchext',
		    :class=>'icon', :src=>'.theme/i/generic.gif'}],
		[:br], 'test.nosuchext'],
	      [:br],
	      [:a, {:href=>'1.download/test.nosuchext'}, 'download']],
	    '{{file(test.nosuchext)}}')
    end

    def test_bug
      eq '=7E', Qwik::Filename.encode('~')

      ok_wi [:div, {:class=>'ref'},
	[:a, {:href=>'1.files/=7E.txt'},
	  [:img, {:src=>'.theme/i/broken.gif', :alt=>'~.txt', :class=>'icon'}],
	  [:br],
	  '~.txt']], '{{file(~.txt)}}'
    end
  end

  class TestActIcon < Test::Unit::TestCase
    include TestSession

    def test_all
      res = session
      a = @action

      # test_icon_path
      ok_eq('.theme/i/broken.gif', a.icon_path('broken'))
      ok_eq('.theme/i/image2.gif', a.icon_path('image2'))

      # test_find_icon
      ok_eq('.theme/i/tar.gif',	a.icon_find('tgz'))
      ok_eq('.theme/i/text.gif',	a.icon_find('txt'))
      ok_eq('.theme/i/text.gif',	a.icon_find('css'))
      ok_eq('.theme/i/image2.gif',	a.icon_find('png'))
      ok_eq('.theme/i/image2.gif',	a.icon_find('gif'))
      ok_eq('.theme/i/pdf.gif',	a.icon_find('pdf'))
      ok_eq('.theme/i/ps.gif',	a.icon_find('ps'))
      ok_eq('.theme/i/compressed.gif',	a.icon_find('zip'))
      ok_eq('.theme/i/binary.gif',	a.icon_find('exe'))
      ok_eq('.theme/i/generic.gif',	a.icon_find('nosuchext'))
    end
  end

  class TestActRef < Test::Unit::TestCase
    include TestSession

    def test_ref_plugin
      attach = @site.attach
      attach.delete('1x1.png') if attach.exist?('1x1.png')

      ok_wi([], '{{ref}}')

      ok_wi([:div, {:class=>'ref'},
	      [:a, {:href=>'.attach/1x1.png'}, '1x1.png']],
	    '{{ref(1x1.png)}}')

      attach.delete('test.pdf') if attach.exist?('test.pdf')
      pdf = 'PDF...dummy'
      attach.fput('test.pdf', pdf)
      ok_wi([:div, {:class=>'ref'},
	      [:a, {:href=>'.attach/test.pdf'}, 'test.pdf']],
	    '{{ref(test.pdf)}}')

      attach.delete('test.txt') if attach.exist?('test.txt')
      file = 'text file dummy'
      attach.fput('test.txt', file)
      ok_wi([:div, {:class=>'ref'},
	      [:a, {:href=>'.attach/test.txt'}, 'test.txt']],
	    '{{ref(test.txt)}}')

      if attach.exist?('test.nosuchext')
	attach.delete('test.nosuchext')
      end
      file = 'unknown file dummy'
      attach.fput('test.nosuchext', file)
      ok_wi([:div, {:class=>'ref'},
	      [:a, {:href=>'.attach/test.nosuchext'}, 'test.nosuchext']],
	    '{{ref(test.nosuchext)}}')
    end
  end
end
