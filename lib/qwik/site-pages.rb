# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Site
    def db();		@pages.db;		end
    def backupdb();	@pages.backupdb;	end

    def last_page_time; @pages.last_page_time;	end
    def [](k)		@pages[k];		end
    def exist?(k)	@pages.exist?(k);	end
    def each(*a, &b)	@pages.each(*a, &b);	end
    def each_all(*a, &b) @pages.each_all(*a, &b);	end
    def to_a(*a)	@pages.to_a(*a);	end
    def create(k)	@pages.create(k);	end
    def create_new();	@pages.create_new;	end
    def get_new_id();	@pages.get_new_id;	end
    def delete(k)	@pages.delete(k);	end
    def title_list();	@pages.title_list;	end
    def date_list();	@pages.date_list;	end
#   def path(f)		@pages.path(f);		end
    def close();	@pages.close;		end
    def get_by_title(t)	@pages.get_by_title(t);	end

    def get_superpage(k)
      page = self[k]
      return page if page
      page = self["_#{k}"]
      return page if page
      return nil
    end
  end
end

if $0 == __FILE__
  require 'qwik/test-module-session'
  require 'qwik/farm'
  $test = true
end

if defined?($test) && $test
  class TestSitePages < Test::Unit::TestCase
    include TestSession

    def test_all
      # test_get_superpage
      eq nil, @site.get_superpage('t')		# Not found.
      page = @site.create '_t'
      eq '_t', @site.get_superpage('t').key	# There is a private page.
      page = @site.create 't'
      eq 't', @site.get_superpage('t').key	# There is a public page.

      # test_get_superpage_for_super_page
      eq '_SideMenu', @site.get_superpage('SideMenu').key
      page = @site.create 'SideMenu'
      eq 'SideMenu', @site.get_superpage('SideMenu').key
    end
  end
end
