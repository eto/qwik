#
# Copyright (C) 2002-2004 Satoru Takabayashi <satoru@namazu.org> 
# Copyright (C) 2003-2006 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/group'

module QuickML
  class Group
    private

    def rewrite_body (mail)
      # body header
      header = generate_header(@address, @added_members) if member_added?

      # body footer
      footer = generate_footer

      if mail.multipart?
	parts = mail.parts
	sub_mail = Mail.new
	sub_mail.read(parts.first)
	cte = sub_mail['Content-Transfer-Encoding']
	if sub_mail.content_type == 'text/plain' and cte.nil? or cte.empty? or cte =~ /^[78]bit$/
	  sub_mail.body = header + sub_mail.body if header
	  sub_mail.body += footer
	end
	parts[0] = sub_mail.to_s
	mail.body = Mail.join_parts(parts, mail.boundary)
	return mail.body
      end

      cte = mail['Content-Transfer-Encoding']
      if mail.plain_text_body? and cte.nil? or cte.empty? or cte =~ /^[78]bit$/
	mail.body = header + mail.body if header
	mail.body += footer
	return mail.body
      end

      return mail.body	# abandon
    end

    def generate_header(address, added_members)
      header = "ML: #{address}\n"
      header << generate_new_member_list(added_members)
      header << "\n"
      return header
    end

    def generate_new_member_list(added_members)
      return added_members.map {|address|
	_("New Member: %s\n", MailAddress.obfuscate(address))
      }.join
    end

    def generate_footer(member_list_p = false)
      pu = page_url
      sf = site_footer

      footer = ''
      footer << "\n-- \n"
      footer << _('archive')+"-> " + pu + " \n"
      footer << "ML-> #{@address}\n"
      if sf && ! sf.empty?
	footer << "\n" + sf
      end
      if member_added?
	footer << generate_unsubscribe_info(@address)
      end
      if member_added? || member_list_p
	footer << "\n" + generate_member_list(@address, @members.list)
      end
      if total_file_size_exceeded?
        footer << generate_total_file_size_exceeded_info
      elsif total_file_size_reaching?
        footer << generate_total_file_size_reaching_info
      end
      return footer
    end

    def generate_unsubscribe_info(address)
      return "\n" +
        _("How to unsubscribe from the ML:\n") +
        _("- Just send an empty message to <%s>.\n", address) +
        _("- Alternatively, if you cannot send an empty message for some reason,\n") +
        _("  please send a message just saying 'unsubscribe' to <%s>.\n", address) +
        _("  (e.g., hotmail's advertisement, signature, etc.)\n") #'
    end

    def generate_member_list(address, list)
      return _("Members of <%s>:\n", address) + list + "\n"
    end

    def generate_total_file_size_exceeded_info
        return "\n" + 
	_('WARNING: Total attached file size exceeded.')  + " " +
	_('Files are not attached on the web.') + "\n"
    end

    def generate_total_file_size_reaching_info
	return "\n" +
	_("WARNING: Total attached file size is reaching to the limit.") +
	" "  +
	_("%s left", (@config[:max_total_file_size] - @site.files_total).byte_format) +
	"\n"
    end
    
  end
end

if $0 == __FILE__
  require 'qwik/test-module-ml'
  $test = true
end

if defined?($test) && $test
  class TestGroupMail < Test::Unit::TestCase
    include TestModuleML

    def setup_group
      return QuickML::Group.new(@ml_config, 'test@example.com')
    end

    def test_all
      group = setup_group

      # test_generate_header
      t_make_public(QuickML::Group, :generate_header)
      ok_eq("ML: test@example.com\n\n",
	    group.generate_header('test@example.com', []))
      ok_eq("ML: test@example.com\nNew Member: user@e...\n\n",
	    group.generate_header('test@example.com', ['user@example.net']))

      # test_generate_footer
      t_make_public(QuickML::Group, :generate_footer)
      ok_eq("
-- 
archive-> http://example.com/test/ 
ML-> test@example.com
",
	    group.generate_footer)

      # test_generate_member_list
      t_make_public(QuickML::Group, :generate_member_list)
      ok_eq("Members of <test@example.com>:\nlist\n",
	    group.generate_member_list('test@example.com', 'list'))

      # test_generate_unsubscribe_info
      t_make_public(QuickML::Group, :generate_unsubscribe_info)
      ok_eq("\nHow to unsubscribe from the ML:\n- Just send an empty message to <test@example.com>.\n- Alternatively, if you cannot send an empty message for some reason,\n  please send a message just saying 'unsubscribe' to <test@example.com>.\n  (e.g., hotmail's advertisement, signature, etc.)\n",
	    group.generate_unsubscribe_info('test@example.com'))

    end

    def test_footer_with_file_limits
      group = setup_group

      t_make_readable(QuickML::Group,:groupsite)
      groupsite = group.groupsite

      t_make_writable(QuickML::GroupSite,:total_file_size_exceeded)
      t_make_writable(QuickML::GroupSite,:total_file_size_reaching)

      # test if generate_footer generates warning message 
      # when total file size exceeded
      groupsite.total_file_size_exceeded = true
      ok_eq("
-- 
archive-> http://example.com/test/ 
ML-> test@example.com

WARNING: Total attached file size exceeded. Files are not attached on the web.
" , group.generate_footer)

      # test if generate_footer generates warning message 
      # when total file size reaching to the limit
      groupsite.total_file_size_exceeded = false
      groupsite.total_file_size_reaching = true
      ok_eq("
-- 
archive-> http://example.com/test/ 
ML-> test@example.com

WARNING: Total attached file size is reaching to the limit. #{(@config[:max_total_file_size]-@site.files.total).byte_format} left
", group.generate_footer)

    end
  end
end
