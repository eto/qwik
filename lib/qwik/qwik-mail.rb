#
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '..' unless $LOAD_PATH.include?('..')

module Qwik
  # FIXME: This class is too ad hoc.
  class Mail
    def initialize(from=nil, to=nil, subject=nil, content=nil)
      @from, @to, @subject, @content = from, to, subject, content
    end
    attr_accessor :from, :to, :subject, :content
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  $test = true
end

if defined?($test) && $test
  class TestQwikMail < Test::Unit::TestCase
    def test_all
      mail = Qwik::Mail.new('from', 'to', 'subject', 'content')
      ok_eq('from', mail.from)
      ok_eq('to', mail.to)
      ok_eq('subject', mail.subject)
      ok_eq('content', mail.content)
    end
  end
end
