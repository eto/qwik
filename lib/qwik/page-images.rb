# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/page-files'

module Qwik
  class PageFiles
    IMAGE_EXT = %w(jpg jpeg png gif bmp ico ppm)
    CONVERT_PATH = '/usr/bin/convert'
    THUMB_SIZE = 100
    SCREEN_WIDTH  = 1024
    SCREEN_HEIGHT = 768

    def image_list
      return self.select {|file|
	PageFiles.is_image?(file.path.ext)
      }
    end

    def each_image
      image_list.each {|file|
	yield(file)
      }
    end

    def self.is_image?(ext)
      return true if IMAGE_EXT.include?(ext.downcase)
      return false
    end

    def generate_all_thumb
      self.each_image {|file|
	generate_thumb(file)
      }
    end

    def generate_thumb(file)
      generate_scaled(file, '.thumb', THUMB_SIZE, THUMB_SIZE)
    end

    def generate_all_screen
      self.each_image {|file|
	generate_screen(file)
      }
    end

    def generate_screen(file)
      generate_scaled(file, '.screen', SCREEN_WIDTH, SCREEN_HEIGHT)
    end

    def generate_scaled(file, scaled_dir, w, h)
      return if $test

      sc_dir = self.path(scaled_dir)
      sc_dir.check_directory

      org = self.path(file)
      #scaled = sc_dir+file
      scaled = sc_dir + Filename.encode(file)
      if ! scaled.exist?
	convert = CONVERT_PATH
	return nil if ! convert.path.exist?
	geom = "#{w}x#{h}"
	cmd = "#{convert} -size #{geom} \"#{org}\" -resize #{geom} \"#{scaled}\""
	#cmd = "#{convert} -size #{geom} #{org} -resize #{geom} #{scaled}"
	#p cmd
	system cmd
      end
    end

=begin
# Excerpt from man convert

       To make a thumbnail of a JPEG image, use:

           convert -size 120x120 cockatoo.jpg -resize 120x120
                   +profile '*' thumbnail.jpg

       In  this example, '-size 120x120' gives a hint to the JPEG decoder that
       the image is going to be downscaled to  120x120,  allowing  it  to  run
       faster  by avoiding returning full-resolution images to ImageMagick for
       the subsequent resizing operation.   The  output  image.   It  will  be
       scaled  so  its  largest  dimension  is  120 pixels.  The that might be
       present in the input and aren't needed in the thumbnail.
=end

  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  require 'qwik/test-module-session'
  $test = true
end

if defined?($test) && $test
  class TestPageImages < Test::Unit::TestCase
    include TestSession

    def setup
    end

    def teardown
    end

    def test_all
      dir = './.test/'.path
      dir.setup
      files = Qwik::PageFiles.new(dir.to_s, '1')

      png = TEST_PNG_DATA
      files.fput('1.jpg', png)	# content is PNG, but use it as .jpg
      files.fput('2.jpg', png)

      # test_image_list
      eq(['1.jpg', '2.jpg'], files.image_list)

      # test_each_image
      files.each_image {|file|
	assert_match(/jpg\z/, file)
      }

      return if $0 != __FILE__		# Only for separated test.

      org_debug = $test
      $test = false

      # test_generate_thumb
      files.generate_thumb('1.jpg')
      ok_eq(true, files.exist?('.thumb/1.jpg'))
      ok_eq(false, files.exist?('.thumb/2.jpg'))

      # test_generate_all_thumb
      files.generate_all_thumb
      ok_eq(true, files.exist?('.thumb/1.jpg'))
      ok_eq(true, files.exist?('.thumb/2.jpg'))

      # test_generate_screen
      files.generate_screen('1.jpg')
      ok_eq(true, files.exist?('.screen/1.jpg'))
      ok_eq(false, files.exist?('.screen/2.jpg'))

      # test_generate_all_screen
      files.generate_all_screen
      ok_eq(true, files.exist?('.screen/1.jpg'))
      ok_eq(true, files.exist?('.screen/2.jpg'))

      $test = org_debug

      dir.teardown
    end

    def test_is_image?
      c = Qwik::PageFiles
      ok_eq(true, c.is_image?('jpg'))
      ok_eq(true, c.is_image?('jpeg'))
      ok_eq(true, c.is_image?('JPG'))
      ok_eq(true, c.is_image?('png'))
      ok_eq(true, c.is_image?('gif'))
      ok_eq(true, c.is_image?('bmp'))
      ok_eq(true, c.is_image?('ico'))
      ok_eq(true, c.is_image?('ppm'))
      ok_eq(false, c.is_image?('pdf'))
    end
  end
end
