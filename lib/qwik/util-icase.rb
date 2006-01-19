#
# Copyright (C) 2002-2004 Satoru Takabayashi <satoru@namazu.org> 
# Copyright (C) 2003-2005 Kouichirou Eto
#     All rights reserved.
#     This is free software with ABSOLUTELY NO WARRANTY.
#
# You can redistribute it and/or modify it under the terms of 
# the GNU General Public License version 2.
#

$LOAD_PATH << '..' unless $LOAD_PATH.include?('..')

module QuickML
  # It preserves case information. but it accepts an
  # address case-insensitively for member management.
  class IcaseArray < Array
    def include? (item)
      if self.find {|x| x.downcase == item.downcase } 
	return true
      else
	return false
      end
    end

    def delete (item)
      self.replace(self.find_all {|x| x.downcase != item.downcase })
    end
  end

  class IcaseHash < Hash
    def include? (key)
      super(key.downcase)
    end

    def delete (key)
      super(key.downcase)
    end

    def [] (key)
      super(key.downcase)
    end	

    def []= (key, value)
      super(key.downcase, value)
    end	
  end
end

if $0 == __FILE__
  require 'qwik/test-module-ml'
  $test = true
end

if defined?($test) && $test
  class TestMLCoreUtils < Test::Unit::TestCase
    def test_iscase_array
      iar = QuickML::IcaseArray.new
      iar << 'T'
      ok_eq(true, iar.include?('T'))
      ok_eq(true, iar.include?('t'))
      iar.delete('t')
      ok_eq(false, iar.include?('t'))
    end

    def test_icase_hash
      ih = QuickML::IcaseHash.new
      ih['T'] = 1
      ok_eq(true, ih.include?('t'))
      ok_eq(1, ih['t'])
      ih.delete('t')
      ok_eq(false, ih.include?('t'))
    end
  end
end
