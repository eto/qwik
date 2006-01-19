#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '..' unless $LOAD_PATH.include?('..')
require 'qwik/act-ring-common'
require 'qwik/act-ring-user'

module Qwik
  class Action

# http://ring.sfc.ne.jp/.ring_new?id=gotz@1996.sfc.ne.jp&mail=gotz@gotz.jp 
# ログインID
# 学籍番号
# 卒業年
# 名前
# 読み
# 電子メール

    def pre_act_ring_new
      id   = @req.query['id']
      mail = @req.query['mail']

      # We need the id and mail.
      if id.nil? || mail.nil?
	return c_nerror('No id nor mail') {
	  'No id nor mail'
	}
      end

      res = ring_new_create_account(id, mail)
      if res == 'exist'
	return c_nerror('Already exist') {
	  'Already exist'
	}
      end

      div = [:div,
	[:p, 'id is ', id],
	[:p, 'mail is ', mail]]

      return c_notice(_r(:NEW_CREATED)) { div }
    end

    def ring_new_create_account(id, mail)
      message = _r(:NEW_FROM_SFCNEJP)

      host_mail = 'info@ring.sfc.ne.jp'	# dummy
      page = c_get_superpage(RING_INVITE_MEMBER)
      page = @site.create('_'+RING_INVITE_MEMBER) if page.nil?
      now = @req.start_time

      guest_mail = id
      member = @site.member
      return 'exist' if member.exist_qwik_members?(guest_mail)
      member.add(guest_mail, host_mail)
      page.wikidb.add(guest_mail, '', host_mail, message, now.to_i)
      #ring_invite_sendmail(host_mail, guest_mail, '', message)
      return nil
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestActRingNew < Test::Unit::TestCase
    include TestSession

    def test_act_ring_new
      #t_add_user	# before login

      res = session('/test/.ring_new') {|req|
	req.cookies.clear	# before login
      }
      ok_xp([:title, 'No id nor mail'], '//title')

      res = session("/test/.ring_new?id=d@1990.sfc.ne.jp&mail=d@g.jp")
      ok_xp([:title, "アカウントが作成されました。"], '//title')

      invite_member_page = @site['_'+Qwik::Action::RING_INVITE_MEMBER]
      ok_eq(",d@1990.sfc.ne.jp,,info@ring.sfc.ne.jp,sfc.ne.jpよりの登録です。,0\n", invite_member_page.load)

      member_page = @site['_SiteMember']
      ok_eq(",d@1990.sfc.ne.jp,info@ring.sfc.ne.jp\n", member_page.load)
   end
  end
end
