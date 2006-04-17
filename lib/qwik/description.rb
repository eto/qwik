module Qwik
  class Action
    D_QwikWeb = {
      :dt => 'How to qwikWeb',
      :dd => 'How you can use qwikWeb',
#You can see brief descriptions of qwikWeb functions.
      :dc => "
'''qwikWeb''' is a group communication system that integrate
WikiWikiWeb and mailing list.

Please see [[qwikWeb|http://qwik.jp/qwikWeb.html]] to the detail.

You can see the list of qwikWeb functions below.
"
    }

    D_SiteManagement = {
      :dt => 'Site management',
      :dd => 'Site management menu.',
      :dc => '
* Site management function
You can access site management pages from the right side of edit page.
You can aceess the same pages here.
- [[Config|_SiteConfig]] Site configuration page
- [[Chronology|.chronology]] You can see the chronology of this site.
- [[Members|_GroupMembers]] You can add or delete the members of this group.
-- Please enter a mail address in each line.  (Do not use comma separated values form.)
-- \'\'\'Warning:\'\'\' If you delete your mail from this page, you can not login this site again.
- {{zip}} You can get a site archive.
-- The archive includes the static HTML pages. You can place the HTML pages onto a web site.
* Site pages configuration
You can edit menus, such as sidemenu, from here.
- [[AdminMenu|_AdminMenu]] On the top of this page.
- [[SideMenu|_SideMenu]] On the side of this page.
- [[PageAttribute|_PageAttribute]] As the page attribute.
- [[EditorFooter|_EditorFooter]] The footer of edit page.
You can also edit several configurations.
- [[_SiteTheme]] You can attach your own css file to this page.
- [[_InterWikiName]] Inter wiki link.
- [[_IsbnLink]] Used for isbn plugin.
- [[_BookSearch]] Used for book search plugin.
- [[_LoginMessage]] If you created this page, you\'ll see message in Login page.

These pages are inherited from the parent pages.
If you edited the pages, the content is copied from the parent pages.
Even if the parent pages are edited, the changes will not be appeared.

If so, please save the content of the current page to your editor,
erase the page.  Then you\'ll see the content of the parent page.
After that, please re-edit the page.

* Etc.
- [[SandBox]]
- [[SiteLog|_SiteLogView]]
Please see [[qwikWeb|http://qwik.jp/qwikWeb.html]] for detail.
'
    }

    D_TextFormatSimple = {
      :dt => 'TextFormat',
      :dd => 'You can see brief description of text format.',
      :dc => "* Text Format
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
      :dd => 'You can see the text format of qwikWeb.',
      :dc => "* Text Format
Please also access the [[simplified text format|TextFormatSimple.describe]].
* Header
- You can describe header by placing '*' on the beginning of the lin.
- You can use '*' from one to five.  The stars are translate fromo h2 to h6.
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
You can specify the page title by using '*' on the first line of the page.
The header acts as the page title.
You can link the page by using the page title.

For example, you can link to the TextFormat page by [[TextFormat]].
And you can also use [[‘Ž®ˆê——Ú×”Å]] to link the page.

But usually, please use page ID to link the page.
Because if you use page title to linke the page,
the page link will be disconnected.
If you use page ID to link the page, the page title will be appear
instead of the page ID.
* List
- You can use unordered list by using '-' on the begining of the line.
- You can use '-' from one to three times.  You can use nested list.
- You can use ordered list by using '+' also.
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
- The blank lines are becomes the separator between paragraphs.
 For example,
 you can describe several lines
 by using several lines.
For example,
you can describe several lines
by using several lines.
* Horizontal rules
- You can describe a horizontal rule by usign '===='.
 There is a separator between this word
 ====
 and this word.
There is a separator between this word
====
and this word.
* Pre-formated text
You can describe pre-formated text by using ' ' or 'tab'.
 This is a
 pre formatted text.
You can also use '{{{' and
'}}}' for specifing pre-formated text.
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
You can describe a quote by using '>'.
 > This is a quote.
> This is a quote.
* Word description
You can describe a word description by using ':'.
 :Wiki:A writable Web system.
 :QuickML:An easy to use mailing list system.
:Wiki:A writable Web system.
:QuickML:An easy to use mailing list system.
* Table
You can use a table by using ',' or '|'.
 ,Data 1-1,Data 1-2,Data 1-3
 ,Data 2-1,Data 2-2,Data 2-3
,Data 1-1,Data 1-2,Data 1-3
,Data 2-1,Data 2-2,Data 2-3
* Inline Elements
You can specify inline elements.
- You can use emphasis a text enclosing by \"''\".
- You can make strong a text enclosing by \"'''\".
- You can make it strike out by enclosing \"=='\".
 This is \'\'emphasis text\'\'.
 This is \'\'\'strong text\'\'\'.
 This is ==stroke out text==.
This is \'\'emphasis text\'\'.
This is \'\'\'strong text\'\'\'.
This is ==stroke out text==.
* Link
You can make a link to a page by using '[[' and ']]'.

 For example, this is a link to [[FrontPage]].
For example, this is a link to [[FrontPage]].
* Create a new page
You can create a new page by follwing new page link.
* Delete a page.
You can delete a page by saving the page with null string.
* Link to a URL
You can link a URL by describing the URL in the text.
 You can access qwikWeb homepage from http://qwik.jp/ .
You can access qwikWeb homepage from http://qwik.jp/ .

And also, you can specify the link by using '[[' and ']]'.
 You can use it by alias like this [[qwik|http://qwik.jp/]].
You can use it by alias like this [[qwik|http://qwik.jp/]].

If the suffix of the link is one of jpg, jpeg, png and gif,
the images will be embeded to the page.
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
