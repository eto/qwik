# -*- coding: shift_jis -*-
# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

module Qwik
  class Action
    D_QwikWeb = {
      :dt => 'How to qwikWeb',
      :dd => 'How to use qwikWeb',
#You can see brief descriptions of qwikWeb functions.
      :dc => "
'''qwikWeb''' is a group communication system that integrates
WikiWikiWeb and a mailing list.

Please see [[qwikWeb|http://qwik.jp/qwikWeb.html]] for details.

A list of qwikWeb functions is presented below.
"
    }

    D_SiteManagement = {
      :dt => 'Site management',
      :dd => 'Site management menu.',
      :dc => '
* Site management function
You can access site management pages from the right side of the edit page.
You can access the same pages here.
- [[Config|_SiteConfig]] Site configuration page
- [[Chronology|.chronology]] The site chronology is shown here.
- [[Members|_GroupMembers]] Add or delete members of this group.
-- Please enter a mail address on each line. (Do not use a comma-separated values format.)
-- \'\'\'Warning:\'\'\' You cannot log in to this site again if you delete your mail from this page.
- {{zip}} You can receive a site archive.
-- The archive includes the static HTML pages. You can place the HTML pages onto a web site.
* Site page configuration
You can edit menus, such as a sidemenu, from here.
- [[AdminMenu|_AdminMenu]] On the top of this page.
- [[SideMenu|_SideMenu]] On the side of this page.
- [[PageAttribute|_PageAttribute]] As the page attribute.
- [[EditorFooter|_EditorFooter]] The footer of the edit page.
You can also edit several configurations.
- [[_SiteTheme]] You can attach your own css file to this page.
- [[_InterWikiName]] Inter wiki link.
- [[_IsbnLink]] Used for the isbn plugin.
- [[_BookSearch]] Used for the book search plugin.
- [[_LoginMessage]] You will see a message on the Login page if you created this page.
These pages are inherited from the parent pages.
The contents are copied from the parent pages if you edited the pages.
Even if the parent pages are edited, the changes might not appear.
If so, please save the contents of the current page to your editor and
erase the page. Then you will see the contents of the parent page.
After that, please re-edit the page.
* etc.
- [[SandBox]]
- [[SiteLog|_SiteLogView]]
Please see [[qwikWeb|http://qwik.jp/qwikWeb.html]] for details.
'
    }

    D_TextFormatSimple = {
      :dt => 'TextFormat',
      :dd => 'You can view a brief description of the text format.',
      :dc => "* Text format
Please also access the [[full text format|TextFormat.describe]].
** Header 2
*** Header 3
**** Header 4
***** Header 5
- List level 1
-- List level 2
--- List level 3
+ Unordered list 1
++ Unordered list 2
+++ Unordered list 3
 Pre formatted text.
> This is a quote.
:Wiki:A writable Web system.
:QuickML:An easy to use mailing list system.
,Data 1-1,Data 1-2,Data 1-3
,Data 2-1,Data 2-2,Data 2-3
''emphasis text'', '''strong text''', ==stroke out text==
[[new|http://qwik.jp/.theme/new.png]]
[[FrontPage]]
[[Yahoo!|http://www.yahoo.co.jp/]]
{{recent(1)}}
{{{
** Header 2
*** Header 3
**** Header 4
***** Header 5
- List level 1
-- List level 2
--- List level 3
+ Unordered list 1
++ Unordered list 2
+++ Unordered list 3
 Pre formatted text.
> This is a quote.
:Wiki:A writable Web system.
:QuickML:An easy to use mailing list system.
,Data 1-1,Data 1-2,Data 1-3
,Data 2-1,Data 2-2,Data 2-3
''emphasis text'', '''strong text''', ==stroke out text==
[[new|http://qwik.jp/.theme/new.png]]
[[FrontPage]]
[[Yahoo!|http://www.yahoo.co.jp/]]
{{recent(1)}}
}}}
"
    }

    D_TextFormat = {
      :dt => 'TextFormat',
      :dd => 'The text format of qwikWeb can be viewed here.',
      :dc => "* Text format
Please also access the [[simplified text format|TextFormatSimple.describe]].
* Header
- You can describe header by placing '*' on the beginning of the line.
- You can use '*' from one to five. The stars are translated from h2 to h6.
 * Header 1
 ** Header 2
 *** Header 3
 **** Header 4
 ***** Header 5
* Header 1
** Header 2
*** Header 3
**** Header 4
***** Header 5
* Page Title
You can specify the page title using '*' on the first line of the page.
The header acts as the page title.
You can link the page using the page title.

For example, you can link to the TextFormat page using [[TextFormat]].
In addition, you can use [[書式一覧詳細版]] to link the page.

However, usually, please use the page ID to link the page.
If you use page title to link to the page,
the page link will be disconnected.
The page title will appear instead of the page ID
if you use page ID to link to the page.

* List
- You can use an unordered list using '-' on the beginning of the line.
- You can use '-' from one to three times. You can use a nested list.
- You can use an ordered list using '+' also.
 - List level 1
 -- List level 2
 --- List level 3
 + Unordered list 1
 ++ Unordered list 2
 +++ Unordered list 3
- List level 1
-- List level 2
--- List level 3
+ Unordered list 1
++ Unordered list 2
+++ Unordered list 3
* Paragraph
- You can describe normal paragraphs.
- The blank lines become separators between paragraphs.
 For example,
 you can describe several lines
 using several lines.
For example,
you can describe several lines
using several lines.
* Horizontal rules
- You can describe a horizontal rule using '===='.
 There is a separator between this word
 ====
 and this word.
There is a separator between this word
====
and this word.

* Pre-formatted text
You can describe pre-formatted text using ' ' or 'tab'.
 This is a
 pre-formatted text.
You can also use '{{{' and
'}}}' for specifying pre-formatted text.
 {{{
 void main()
 {
     printf(\"hello, world\n\");
 }
 }}}
{{{
void main()
{
    printf(\"hello, world\n\");
}
}}}
* Quote
You can describe a quote using '>'.
 > This is a quote.
> This is a quote.
* Word description
You can make a word description using ':'.
 :Wiki:A writable Web system.
 :QuickML:An easy-to-use mailing list system.
:Wiki:A writable Web system.
:QuickML:An easy-to-use mailing list system.
* Table
You can use a table using ',' or '|'.
 ,Data 1-1,Data 1-2,Data 1-3
 ,Data 2-1,Data 2-2,Data 2-3
,Data 1-1,Data 1-2,Data 1-3
,Data 2-1,Data 2-2,Data 2-3
* Inline Elements
You can specify inline elements.
- You can add emphasis to an enclosed text using 2 apostrophes.
- You can add stronger emphasis to an enclosed text using 3 apostrophes.
- You can add strike out an enclosed text using 3 equals signs.
 This is ''emphasis text''.
 This is '''bold text'''.
 This is ==stricken out text==.
This is ''emphasis text''.
This is '''bold text'''.
This is ==stricken out text==.
* Link
You can make a link to a page using '[[' and ']]'.
 For example, this is a link to [[FrontPage]].
For example, this is a link to [[FrontPage]].
* Create a new page
You can create a new page by following a new page link.
* Delete a page.
You can delete a page by saving the page with a null string.
* Link to a URL
You can link a URL by describing the URL in the text.
 You can access qwikWeb homepage from http://qwik.jp/ .
You can access qwikWeb homepage from http://qwik.jp/ .

Furthermore, you can specify the link using '[[' and ']]'.
 You can use it with an alias like this [[qwik|http://qwik.jp/]].
You can use it with an alias like this [[qwik|http://qwik.jp/]].

If the suffix of the link is jpg, jpeg, png, or gif,
the images will be embedded in the page.
 [[New!|http://img.yahoo.co.jp/images/new2.gif]]
[[New!|http://img.yahoo.co.jp/images/new2.gif]]
* InterWiki function.
You can describe a link to the other Wiki sites.
 - [[google:qwikWeb]]
 - [[isbn:4797318325]]
 - [[amazon:Wiki]]
- [[google:qwikWeb]]
- [[isbn:4797318325]]
- [[amazon:Wiki]]
"
    }
  end
end
