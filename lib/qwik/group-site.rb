# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/config'
require 'qwik/server-memory'
require 'qwik/farm'
require 'qwik/site-plan'
require 'qwik/page-title'
require 'qwik/util-string'
require 'qwik/util-charset'
require 'qwik/util-filename'
require 'qwik/ml-gettext'

module QuickML
  class Group
    private

    def init_site
      @groupsite = GroupSite.new(@config, @name)
      @site = @groupsite.site
    end

    def site_post(mail, test=false)
      begin	# Do not raise exception when posting a message.
	@groupsite.post(mail)
	@logger.log("[#{@name}]: QwikPost: #{@groupsite.key}")
      rescue
	@logger.log("[#{@name}]: QwikPostError: "+$!.to_s+$!.backtrace.to_s)
      end
    end

    def page_url
      key = @groupsite.key
      base = ''
      base = "#{key}.html" if key
     #return "http://#{@config.ml_domain}/#{@name}/#{base}"
      return "#{@config.public_url}#{@name}/#{base}"
    end

    def site_footer
      # Do not raise exception when generating a footer.
      begin
	now = Time.now
	now = Time.at(0) if defined?($test) && $test
	return @groupsite.get_footer(now).set_page_charset.to_mail_charset
      rescue
	@logger.log("[#{@name}]: QwikFooterError: "+$!.to_s+$!.backtrace.to_s)
	return ''	# Do not raise error
      end
    end

    private
    def total_file_size_exceeded?
      @groupsite.total_file_size_exceeded
    end

    def total_file_size_reaching?
      @groupsite.total_file_size_reaching
    end
  end

  class GroupSite
    include GetText
    def initialize(ml_config, sitename, test=false)
      @ml_config = ml_config

      if test || defined?($test) && $test
	@config = $test_config
	@memory = $test_memory
      else

=begin
        hash = {:debug=>true}

	# FIXME: Web Config should be inherited from the web server.
        f = @ml_config[:config_file].path
        if f.exist?
          config = Qwik::Config.load_config_file(f.to_s)
          hash.update(config)
        end

	@config = Qwik::Config.new
	@config.update(hash)
=end
	@config = @ml_config
	@memory = Qwik::ServerMemory.new(@config)
      end

      @sitename = sitename
      @site = @memory.farm.get_site(@sitename)
      raise 'site does not exist' if @site.nil?	# Check if the site is exist.
      @key = nil
      @total_file_size_exceeded = false
      @total_file_size_reaching = false
    end
    attr_reader :key
    attr_reader :site
    attr_reader :total_file_size_exceeded
    attr_reader :total_file_size_reaching

    def post(mail)
      # Parse page title.
      title = mail.get_unified_subject(@sitename)	# Get unified subject.
      page_title, tags = Qwik::Page.parse_title(title)

      page = @site.get_by_title(page_title)
      if page.nil?			# Create a new page.
	if Qwik::Page.valid_as_pagekey?(page_title)
	  page = @site.create(page_title)	# CREATE
	else
	  page = @site.create_new	# CREATE
	end
	page.store('* '+title+"\n")	# Save title with tags.
      end
      @key = page.key			# @key will be used at site_url

      # Get body text.
      now = $quickml_debug ? Time.at(0) : Time.now
      content = make_content(@key, mail, now)
      page.add(content)
    end

    def get_footer(now)
      return '' if @site.nil?
      footer = @site.get_footer(now)
      return footer
    end

    private
    def make_content(key, mail, now)
      content = ''
      mail_default_charset = 'ISO-2022-JP'
      site_files_total = @site.files_total
      max_total_file_size = @config[:max_total_file_size].to_i
      max_total_warn_size = @config[:max_total_warn_size].to_i

      mail.each_part {|sub_mail|
	if sub_mail.plain_text_body?
	  c = sub_mail.decoded_body.normalize_eol
 	  charset = c.guess_charset || mail_default_charset
 	  c = c.set_charset(charset).to_page_charset
	  content << c
	else
	  filename = sub_mail.filename
	  decoded_body = sub_mail.decoded_body
	  if filename && decoded_body
	    if max_total_file_size < site_files_total
	      #do not attach file
	      content << _("\nFile '%s' was not attached.\n",filename)
	    else
	      msg = GroupSite.attach(@site, key, filename, decoded_body)
	      content << msg
	      site_files_total += decoded_body.size
	    end
	    if max_total_file_size < site_files_total
	      @total_file_size_exceeded = true
	    elsif (max_total_file_size - max_total_warn_size) < site_files_total
	      @total_file_size_reaching = true
	    end
	  end
	end
      }
      content.gsub!(/\n\n\z/, "\n")	# FIXME: Why truncate newlines?
      from = mail.mail_from
      time = now.to_i
      return "{{mail(#{from},#{time})
#{content}}}
"
    end

    def self.attach(site, key, filename, file_content)
      files = site.files(key)

      result_filename = files.fput(filename, file_content)
      result_filename = result_filename.to_page_charset

      addmessage = "\n{{file(#{filename})}}\n\n"
      if result_filename != filename
	addmessage = "\n{{file(#{result_filename})}}\n\n"
      end

      return addmessage
    end

    def self.file_with_num(filename, num)
      return "#{num}-#{filename}"
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-module-ml'
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  require 'qwik/group'

  class TestGroupSite < Test::Unit::TestCase
    include TestModuleML

    def setup_group
      return QuickML::Group.new(@ml_config, 'test@example.com')
    end

    def test_class_method
      c = QuickML::GroupSite

      # test_file_with_num
      eq '1-t', c.file_with_num('t', 1)
    end

    def test_all
      c = QuickML::GroupSite

      group = setup_group

      t_make_readable(QuickML::Group, :groupsite)
      groupsite = group.groupsite

      # test_key
      eq nil, groupsite.key

      # test_make_content
      message =
'Date: Mon, 3 Feb 2001 12:34:56 +0900
From: user@e.com
To: test@example.com
Subject: test

test.
'
      t_make_public(QuickML::GroupSite, :make_content)
      mail = QuickML::Mail.generate { message }
      eq "{{mail(user@e.com,0)\ntest.\n}}\n",
	groupsite.make_content(nil, mail, Time.at(0))

      # test_attach
      eq '
{{file(t.txt)}}

',
	c.attach(@site, 'FrontPage', 't.txt', 'test.')
      files = @site.files('FrontPage')
      eq true, files.exist?('t.txt')
      eq ['t.txt'], files.list

      # test_attach_again
      eq '
{{file(1-t.txt)}}

',
	c.attach(@site, 'FrontPage', 't.txt', 'test.')
      eq true, files.exist?('1-t.txt')
      eq ['1-t.txt', 't.txt'], files.list

      # test_page_url
      t_make_public(QuickML::Group, :page_url)
      eq 'http://example.com/test/', group.page_url
      groupsite.instance_eval {
	@key = 't'
      }
      eq 'http://example.com/test/t.html', group.page_url

      # test_attach
      eq '
{{file(‚ .txt)}}

',
	c.attach(@site, 'FrontPage', '‚ .txt', 'test.')
      eq true, files.exist?('t.txt')
      #eq true, files.exist?('=82=A0.txt')
      #eq ['1-t.txt', '=82=A0.txt', 't.txt'], files.list
    end

    def test_total_file_limit
      c = QuickML::GroupSite

      group = setup_group

      t_make_readable(QuickML::Group, :groupsite)
      groupsite = group.groupsite

      #attach 712B file named 'ruby.png'
      multi_part_message =
'Date: Tue, 13 Jan 2009 21:51:41 +0900
From: user@e.com
To: test@example.com
Subject: test
Content-Type: multipart/mixed;
 boundary="Multipart_Tue_Jan_13_21:58:38_2009-1"

--Multipart_Tue_Jan_13_21:58:38_2009-1
Content-Type: text/plain; charset=US-ASCII

ruby

--Multipart_Tue_Jan_13_21:58:38_2009-1
Content-Type: image/png
Content-Disposition: inline; filename="ruby.png"
Content-Transfer-Encoding: base64

iVBORw0KGgoAAAANSUhEUgAAAA4AAAAQCAIAAACp9tltAAAAAXNSR0IArs4c6QAAAoJJREFUKM8F
wUlPE1EAAOC3zXSWbtMylBbaAEUsEKlQIkSlogkxRm9eSLx78Z94NSR6MzEuF42JejUx0URNMFAo
RUJtEUqBCp1pO0unM+/5ffBxfum8XMaSbBsGkWSPUQqA03UoAIAQj1IAodE2cvfu4KU+Nf9gJdKv
Dgyn9GJRxhjqWvbmjWQq1S4UFMEXQhBalokwMXRdGRk53NoeXpg/2ipKStgxTCJJA5MTWu0QEeJZ
Fg6HWxjjqyFlLDcTHUsfbRQwxyWy06FEghN8Xq/Xn7mYXlyUlPB5rWZQhgDGsqoW3r1P5mbFcFgI
BXm/zChzTKu2vr726nU0PXr+p0o4jjCEvj5ZbVT3TU33q31G4xRh7FgWdT29dgQRKn74yDyPIESs
VrsF2MTt5cHhZGw8bRta8dNn5guKgaDV1Ox2+7j0GxMMAUPB5ODcyn3QqO++eL79dDW9fLdvPndQ
KNT/VuO5LLUsSD2CEIIQX4vF7NLmWWUfCgIRJUi7zW9fui4oN/7F4nF4ckwwRJ7LIlHUOv3XdRw+
qrSbWmBy+mCjdHLaCfqD2Xxejcc41xIJFDHjEEQMY8jzRrOpZi/NP3rYYsgR5UrjTFYiEYHDXlck
QCKAQ5B4jLV0LZGZmLyeq755ptfrtb09JEu0Y3WOagGZI4RxPLMJIE7PHbqVT4VDWy/fYp8ojWda
rjs1O+M2dey2RR5gjjKXmRigyFAiMze39/OX4490bNozrJGFK/rJMXJtwTVFHokEiBwQOYSnMN8q
7XQs2wTAJFhNj2KO7Hz/cXlmKqZVcM8UOSgxx/ZHSCSZKlf3BdHn2QaDQF/bQJQCKbS5W6lblNCA
ADFPoXIh8x8NLS3ZvcTDhQAAAABJRU5ErkJggg==

--Multipart_Tue_Jan_13_21:58:38_2009-1--
'

      default_max_total_file_size = @config[:max_total_file_size]
      default_max_total_warn_size = @config[:max_total_warn_size]

      @config[:max_total_file_size] = 800 #total file size limit
      @config[:max_total_warn_size] = 100 #warn if remaining is less than this

      t_make_writable(QuickML::GroupSite, :total_file_size_exceeded)
      t_make_writable(QuickML::GroupSite, :total_file_size_reaching)

      mail = QuickML::Mail.generate { multi_part_message }


      ##post first mail
      groupsite.post(mail)
      files = @site.files('test')

      #check if attached file is saved on the web
      eq ['ruby.png'], files.list

      #check if warning is on
      eq true,  groupsite.total_file_size_reaching

      ##post second mail
      groupsite.total_file_size_reaching = false
      groupsite.post(mail)

      # check if attached file is save on the web
      eq ['1-ruby.png','ruby.png'], files.list

      #check if total file size is exceeded the limit(800)
      eq true, groupsite.total_file_size_exceeded

      ##post second mail
      groupsite.total_file_size_exceeded = false
      groupsite.post(mail)

      #check if file is not attached
      eq ['1-ruby.png','ruby.png'], files.list

      #check if total file size is exceeded the limit(800)
      eq true, groupsite.total_file_size_exceeded


      #check if the warning message is inserted on the web
      eq "{{mail(user@e.com,0)\nruby\n\n\n{{file(ruby.png)}}\n}}\n{{mail(user@e.com,0)\nruby\n\n\n{{file(1-ruby.png)}}\n}}\n{{mail(user@e.com,0)\nruby\n\n\nFile 'ruby.png' was not attached.\n}}\n", @site['test'].get_body


      @config[:max_total_file_size] = default_max_total_file_size
      @config[:max_total_warn_size] = default_max_total_warn_size
    end
  end
end
