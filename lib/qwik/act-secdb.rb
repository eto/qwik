#
# Copyright (C) 2005 Masashi Miyamura
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '../../lib' unless $LOAD_PATH.include?('../../lib')

module Qwik
  class Action
    D_secdb = {
      :dt => 'Show a table of each section data',
      :dd => 'You can create a table from data embedded as CSV format in each section.',
      :dc => "
The first section is recognized as variable names (column names).
* Examples
You can embbed your data in a page.

** Date,Type A,Type B, Type C
*** Country,Population
** 2019-01-01,100,200,300

*** Japan,12000
*** USA,26000

You can create a table of Section \"**\" (default).
 {{secdb}}
,Date,Type A,Type B,Type C
,2019-01-01,100,200,300

You can specify which section you use (e.g. \"***\").
 {{secdb(***)}}
,Country,Population
,Japan,12000
,USA,26000

Also you can specify another \"data embedded\" page.
 {{secdb(**, FrontPage)}}

Enjoy!
" }

    def plg_secdb(mark = '**', pagename = nil)
      pagename = @req.base if pagename.nil?
      pagename = pagename.to_s

      org_base = @req.base
      @req.base = pagename

      page = @site[pagename]
      if page.nil?
        @req.base = org_base
        return nil
      end
      db_data = page.get_secdb(mark.to_s)

      if db_data.nil?
        @req.base = org_base
        return [:div, [:p, [:strong, '#{pagename} has no data.']]]
      end

      table = [:table, {:class=>'secdb'}]
      thead = [:tr]
      db_data.shift.each{|name| thead << [:th, name]}
      table << thead
      db_data.each do |value|
        trow = [:tr]
        value.each{|v| trow << [:td, v]}
        table << trow
      end

      @req.base = org_base
      return table
    end # def plg_secdb
  end # class Action

  class Page
    def get_secdb(mark = '**')
      require 'csv' # CSV.parse_line()

      return nil if mark.nil? or mark.empty?
      mark = Regexp.escape(mark)

      body = self.get_body

      db_data = []
      body.split("\n").each do |line|
        line = line.rstrip
        datum = nil
        if (/^#{mark}\s/ =~ line)
          str = $'
          datum = CSV.parse_line(str)
        end
        db_data << datum unless datum.nil?
      end

      return db_data unless db_data.empty?
      return nil
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-common'
  $test = true
end

if defined?($test) && $test
  class TestPageMethod < Test::Unit::TestCase
    include TestSession

    def test_get_secdb
      page = @site.create_new
      page.store("* Title
* T1: Data header,A,B,C
** T2: Data header,a,b,c
* T1: Data line1,100,101,102
** T2: Data line1,10,11,12
** T2: Data line2,20,21,22
* T1: Data line2,200,201,202
This is not a data line.
**** CSV,\"4, 5\",3,2,1
" )

      ok_eq([['T1: Data header', 'A', 'B', 'C'],
              ['T1: Data line1', '100', '101', '102'],
              ['T1: Data line2', '200', '201', '202'],],
            page.get_secdb('*'))

      ok_eq([['T2: Data header', 'a', 'b', 'c'],
              ['T2: Data line1', '10', '11', '12'],
              ['T2: Data line2', '20', '21', '22'],],
            page.get_secdb('**'))
      ok_eq(nil, page.get_secdb('***'))
      ok_eq([['CSV', '4, 5', '3', '2', '1']], page.get_secdb('****'))
    end
  end

  class TestActSecdb < Test::Unit::TestCase
    include TestSession

    def test_plg_secdb
      t_add_user

      page1 = @site.create('1')
      page1.store('* title
{{secdb}}
** A,B,C
*** A1,B1,C1
** 1,2,3
** (i),(ii),(iii)
This is not a data line.
> ** Neither, this is.
*** alpha,beta,gamma
*** psi,phi,NA
')

      page2 = @site.create('2')
      page2.store("* title
{{secdb(\"***\", \"1\")}}
")

      res = session('/test/1.html')
      ok_xp([:table, {:class=>'secdb'},
              [:tr, [:th, 'A'], [:th, 'B'], [:th, 'C']],
              [:tr, [:td, '1'], [:td, '2'], [:td, '3']],
              [:tr, [:td, '(i)'], [:td, '(ii)'], [:td, '(iii)']]],
            '//table')

      res = session('/test/2.html')
      ok_xp([:table, {:class=>'secdb'},
              [:tr, [:th, 'A1'], [:th, 'B1'], [:th, 'C1']],
              [:tr, [:td, 'alpha'], [:td, 'beta'], [:td, 'gamma']],
              [:tr, [:td, 'psi'], [:td, 'phi'], [:td, 'NA']]],
            '//table')
    end
  end
end
