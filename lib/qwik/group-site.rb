$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'
require 'qwik/config'
require 'qwik/server-memory'
require 'qwik/farm'
require 'qwik/site-plan'
require 'qwik/page-title'
require 'qwik/util-string'
require 'qwik/util-charset'
require 'qwik/util-filename'

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
  end

  class GroupSite
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
      raise 'site is not exist' if @site.nil?	# Check if the site is exist.
      @key = nil
    end
    attr_reader :key
    attr_reader :site

    def post(mail)
      # Parse page title.
      title = mail.get_unified_subject	# Get unified subject.
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
      content = GroupSite.make_content(@site, @key, mail, now)
      page.add(content)
    end

    def get_footer(now)
      return '' if @site.nil?
      footer = @site.get_footer(now)
      return footer
    end

    private

    def self.make_content(site, key, mail, now)
      content = ''
      mail.each_part {|sub_mail|
	if sub_mail.plain_text_body?
	  c = sub_mail.decoded_body.normalize_eol
	  c = c.set_mail_charset.to_page_charset
	  content << c
	else
	  filename = sub_mail.filename
	  decoded_body = sub_mail.decoded_body
	  if filename && decoded_body
	    msg = GroupSite.attach(site, key, filename, decoded_body)
	    content << msg
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
      mail = QuickML::Mail.generate { message }
      eq "{{mail(user@e.com,0)\ntest.\n}}\n",
	c.make_content(@site, nil, mail, Time.at(0))

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
  end
end
