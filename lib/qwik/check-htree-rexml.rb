# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH << 'compat' unless $LOAD_PATH.include? 'compat'
require 'htree'

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/testunit'

class CheckHTree < Test::Unit::TestCase
  def test_htree_to_rexml
    str = '<p>あ</p>'
    ok_eq("\202\240", 'あ') # Kanji code is SJIS.
    h = HTree(str)

    x = ''
    h.display_xml(x)
    ok_eq("<p\n>\202\240</p\n>", x)

    r = h.to_rexml
    ok_eq("<p>\202\240</p>", r.to_s)
    #ok_eq("  <p>\202\240</p>", r.to_s(1))

    html = <<'EOT'
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd"><html><head id='header'><title>新規作成</title><link href="/.theme/base.css" rel='stylesheet' media="screen,tv" type="text/css"/><link href="/.theme/qwiksystem/qwiksystem.css" rel='stylesheet' media="screen,tv" type="text/css"/><meta name='ROBOTS' content="NOINDEX,NOFOLLOW"/><meta content="0; url=FirstPage.edit" http-equiv='Refresh'/></head><body><div class='container'><div class='header'><div><div><h1 id="view_title">新規作成</h1></div></div></div><div class="update day"><div class='form'><div class='msg' id='msg'><h2>新規作成</h2><p>新規ページを作成しました</p><p><a href="FirstPage.edit">新規ページを編集</a>してください。</p><p><a href="FirstPage.edit">FirstPage.edit</a></p></div></div></div><div class="update day"><div class='comment'></div></div></div></body></html>
EOT
    h = HTree(html)
    r = h.to_rexml
    e = <<'EOT'
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd"><html xmlns='http://www.w3.org/1999/xhtml'><head id='header'><title>新規作成</title><link href='/.theme/base.css' rel='stylesheet' type='text/css' media='screen,tv'/><link href='/.theme/qwiksystem/qwiksystem.css' rel='stylesheet' type='text/css' media='screen,tv'/><meta name='ROBOTS' content='NOINDEX,NOFOLLOW'/><meta content='0; url=FirstPage.edit' http-equiv='Refresh'/></head><body><div class='container'><div class='header'><div><div><h1 id='view_title'>新規作成</h1></div></div></div><div class='update day'><div class='form'><div class='msg' id='msg'><h2>新規作成</h2><p>新規ページを作成しました</p><p><a href='FirstPage.edit'>新規ページを編集</a>してください。</p><p><a href='FirstPage.edit'>FirstPage.edit</a></p></div></div></div><div class='update day'><div class='comment'/></div></div></body></html>
EOT
    ok_eq(e, r.to_s)

    e = <<'EOT'
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html xmlns='http://www.w3.org/1999/xhtml'>
  <head id='header'>
    <title>新規作成</title>
    <link href='/.theme/base.css' rel='stylesheet' type='text/css' media='screen,tv'/>
    <link href='/.theme/qwiksystem/qwiksystem.css' rel='stylesheet' type='text/css' media='screen,tv'/>
    <meta name='ROBOTS' content='NOINDEX,NOFOLLOW'/>
    <meta content='0; url=FirstPage.edit' http-equiv='Refresh'/>
  </head>
  <body>
    <div class='container'>
      <div class='header'>
        <div>
          <div>
            <h1 id='view_title'>新規作成</h1>
          </div>
        </div>
      </div>
      <div class='update day'>
        <div class='form'>
          <div class='msg' id='msg'>
            <h2>新規作成</h2>
            <p>新規ページを作成しました</p>
            <p>
              <a href='FirstPage.edit'>新規ページを編集</a>してください。</p>
            <p>
              <a href='FirstPage.edit'>FirstPage.edit</a>
            </p>
          </div>
        </div>
      </div>
      <div class='update day'>
        <div class='comment'/>
      </div>
    </div>
  </body>
</html>

EOT
    #ok_eq(e, r.to_s(0))
  end
end
