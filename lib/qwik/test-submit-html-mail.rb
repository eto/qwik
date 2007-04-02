# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/test-module-ml'

class TestSubmitHtmlMail < Test::Unit::TestCase
  include TestModuleML

  def test_all
    qml = QuickML::Group.new(@ml_config, 'test@example.com')
    qml.setup_test_config
    mail = post_mail(qml) {
"Date: Mon, 1 Aug 2005 11:06:12 +0900
To: test@example.com
From: bob@example.net
Subject: HtmlMail
Content-Type: multipart/alternative;
 boundary=\"============_-1089260510==_ma============\"

--============_-1089260510==_ma============
Content-Type: text/plain; charset='iso-2022-jp'
Content-Transfer-Encoding: 7bit

Ç≈Ç∑ÅB
--============_-1089260510==_ma============
Content-Type: text/html; charset='iso-2022-jp'
Content-Transfer-Encoding: 7bit

<!doctype html public \"-//W3C//DTD W3 HTML//EN\">
<html><head><style type=\"text/css\"><!--
blockquote, dl, ul, ol, li { padding-top: 0 ; padding-bottom: 0 }
 --></style><title>George Legady</title></head><body>
<div>Ç≈Ç∑ÅB<br>
</div>
</body>
</html>
--============_-1089260510==_ma============--
" }

    ok_eq("============_-1089260510==_ma============", mail.boundary)

    mail1 = QuickML::Mail.new
    mail1.read(mail.parts[1])
    ok_eq('text/html', mail1.content_type)

    page = @site['HtmlMail']
    ok_eq('HtmlMail', page.get_title)
    ok_eq("* HtmlMail\n{{mail(bob@example.net,0)\nÇ≈Ç∑ÅB\n}}\n", page.load)
  end
end
