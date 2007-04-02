# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class Site
    def sitedb
      @sitedb = SiteDB.new(@config, self) unless defined? @sitedb
      return @sitedb
    end
  end

  class SiteDB
    def initialize(config, site)
      require 'sqlite'		# SQLite
      #require 'sqlite3'	# SQLite3
      file = "#{config.cache_dir.path.to_win_dir}/#{site.sitename}.db"
      @db = ::SQLite::Database.new(file, 0)
    # @db = ::SQLite3::Database.new(file)
    end

    def table_exist?(table)
      @db.table_info(table) {|row|
	return true
      }
      false
    end

    def quote(org)
      ::SQLite::Database.quote(org)
    end

    def encode(org)
      ::SQLite::Database.encode(org)
    end

    def decode(org)
      ::SQLite::Database.decode(org)
    end

    def check_table(table)
      raise unless /\A[a-z]+\z/ =~ table
      quote(table) # make sure
    end

    def table_create(table)
      t = check_table(table)
      sql = <<'EOT'
create table #{t}
(
  id INTEGER PRIMARY KEY,
  key TEXT,
  value VARCHAR
);
create index idx_#{t}_key on #{t} ( key );
EOT
      @db.execute(sql)
    end

    def delete(t, k)
      t = check_table(t)
      k = quote(k)
      @db.execute("delete from #{t} where key='#{k}';")
    end

    def set(t, k, v)
      t = check_table(t)
      k = quote(k)
      delete(t, k) if get(t, k)
      v = encode(v)
      @db.execute("insert into #{t} values (NULL, '#{k}', '#{v}');")
    end

    def get(t, k)
      t = check_table(t)
      k = quote(k)
      v = @db.get_first_value("select value from #{t} where key='#{k}'" )
      return nil if v.nil?
      decode(v)
    end
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  require 'qwik/test-common'
  require 'qwik/config'
  require 'qwik/server-memory'
  $test = true
end

if defined?($test) && $test
  module Qwik
    class SiteDB
      attr_reader :db
      def test(t)
      end
    end
  end

  class TestSiteDB < Test::Unit::TestCase
    def test_all
      # not yet.
    end
  end

  class CheckSiteDB < Test::Unit::TestCase
    include TestSession

    def test_all
      db = @site.sitedb

      # test_quote
      eq "''", db.quote("'")		# only this...
      eq 'BAhpAA==', db.encode(0)	# marshal and base64
      eq 0, db.decode('BAhpAA==')

      # test_sitedb
      assert_instance_of(SQLite::Database, db.db)
     #assert_instance_of(SQLite3::Database, db.db)
      db.db.database_list {|row|
	assert_instance_of(Array, row)
      }

      #eq '2.8.15', SQLite::Database::VERSION
      #eq 'iso8859', SQLite::Database::ENCODING
      db.table_create('test') unless db.table_exist?('test')
      db.set('test', 'k', 'v')
      eq 'v', db.get('test', 'k')
      db.delete('test', 'k')
      eq nil, db.get('test', 'k')
    end
  end
end
