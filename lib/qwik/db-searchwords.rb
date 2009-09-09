# Copyright (C) 2009 AIST, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/util-pathname'

require 'thread'

module Qwik
  class SearchWordsDB
    Word = Struct.new("Word", :word, :count, :time)

    def initialize(path, config)
      @config = config
      @path = path
      @word_index = Hash.new
      @recent_list = Array.new
      @normalized_list = Array.new
      @lock = Mutex.new
      read
    end

    def delete(word)
      w = word.to_sym
      @lock.synchronize {
        em = @word_index[w]
        if em
  	  @word_index.delete(w)
	  @recent_list.delete(em)
	  save
        end
      }
    end

    def put(words)
      if words.class == String
        words = [words]
      end
      @lock.synchronize {
        words.each {|word|
	  w = word.to_sym
          em = @word_index[w]
	  if em
	    @recent_list.delete(em)
	    em.count +=1 
	  else
	    em = Word.new(w, 1, Time.new)
	    if @config[:search_word_max_num] < @recent_list.size
	      em = @recent_list.delete_at(-1)
	      @word_index.delete(em.word)
	    end
	    @word_index[em.word] = em
	  end
	  @recent_list.unshift(em)
	}
        save
      }
    end

    def get
      @recent_list[0...@config[:search_word_display_num]]
    end

    def get_normalized
      @normalized_list
    end

   private
    # should be called from synchronized block
    def save
      f = File.new(path,"w")
      @recent_list.each {|em|
        f.puts "#{em.time.to_i} #{em.count} #{em.word}" 
      }
      f.close
      normalize
    end

    def read
      begin
        cont = File.new(path).read
        @lock.synchronize {
          cont.each_line {|line|
            time, count, word = line.chomp.split(/ /)
	    em = Word.new(word.to_sym, count.to_i, Time.at(time.to_i))
	    @recent_list.push(em)
	    @word_index[em.word] = em
          }
	  normalize
        }
      rescue Errno::ENOENT
        # do nothing
      end
    end

    def path
      "#{@path}/_SearchWords.txt"
    end

    NUM_SIZE = 5
    def normalize
      min,max = min_max
      diff = max - min + 0.1
      @normalized_list =
        @recent_list[0...@config[:search_word_display_num]].map{|em|
        norm = (em.count - min) / diff * NUM_SIZE
        Word.new(em.word, norm.to_i, em.time)
      }
    end

    def min_max
      return [0, 0] if @recent_list[0].nil?
      min = max = @recent_list[0].count
      @recent_list[1...@config[:search_word_display_num]].each{|em|
        if max < em.count 
	  max = em.count
	elsif em.count < min
	  min = em.count
	end
      }
      return [min, max]
    end
  end
end

if $0 == __FILE__
  require 'test/unit'
  require 'qwik/config'
  require 'qwik/test-module-path'
  $test = true
end

if defined?($test) && $test
  class TestSearchWorddsDB < Test::Unit::TestCase
    def test_swdb
      # setup
      config = Qwik::Config.new
      config.update Qwik::Config::DebugConfig
      config.update Qwik::Config::TestConfig
      path = '.test/'.path
      path.setup
      db = Qwik::SearchWordsDB.new(path,config)

      # put a word
      db.put(["foo"])
      ems = db.get
      assert_equal 1, ems.size
      assert_equal :foo, ems[0].word
      assert_equal 1, ems[0].count

      # put the same word
      db.put("foo")
      ems = db.get
      assert_equal 1, ems.size
      assert_equal :foo, ems[0].word
      assert_equal 2, ems[0].count

      # check if correctly saved and read
      db2 = Qwik::SearchWordsDB.new(path,config)
      ems = db2.get
      assert_equal 1, ems.size
      assert_equal :foo, ems[0].word
      assert_equal 2, ems[0].count

      # put the different word
      db.put("bar")
      ems = db.get
      assert_equal 2, ems.size
      assert_equal :bar, ems[0].word
      assert_equal 1, ems[0].count
      assert_equal :foo, ems[1].word
      assert_equal 2, ems[1].count

      # check if correctly saved and read
      db2 = Qwik::SearchWordsDB.new(path,config)
      ems = db2.get
      assert_equal 2, ems.size
      assert_equal :bar, ems[0].word
      assert_equal 1, ems[0].count
      assert_equal :foo, ems[1].word
      assert_equal 2, ems[1].count

      # put Jpanaese name
      word = "‚Ù‚°"
      db.put(word)
      ems = db.get
      assert_equal 3, ems.size
      assert_equal word.to_sym, ems[0].word
      assert_equal 1, ems[0].count
      assert_equal :bar, ems[1].word
      assert_equal 1, ems[1].count
      assert_equal :foo, ems[2].word
      assert_equal 2, ems[2].count

      # check if correctly saved and read
      db2 = Qwik::SearchWordsDB.new(path,config)
      ems = db2.get
      assert_equal 3, ems.size
      assert_equal word.to_sym, ems[0].word
      assert_equal 1, ems[0].count
      assert_equal :bar, ems[1].word
      assert_equal 1, ems[1].count
      assert_equal :foo, ems[2].word
      assert_equal 2, ems[2].count

      db2.put("bar")
      ems = db2.get
      assert_equal 3, ems.size
      assert_equal :bar, ems[0].word
      assert_equal 2, ems[0].count
      assert_equal word.to_sym, ems[1].word
      assert_equal 1, ems[1].count
      assert_equal :foo, ems[2].word
      assert_equal 2, ems[2].count

      #test deleation
      db2.delete(word)
      ems = db2.get
      assert_equal 2, ems.size
      assert_equal :bar, ems[0].word
      assert_equal 2, ems[0].count
      assert_equal :foo, ems[1].word
      assert_equal 2, ems[1].count

      # check if correctly saved and read
      db3 = Qwik::SearchWordsDB.new(path,config)
      ems = db3.get
      assert_equal 2, ems.size
      assert_equal :bar, ems[0].word
      assert_equal 2, ems[0].count
      assert_equal :foo, ems[1].word
      assert_equal 2, ems[1].count

      path.teardown
    end
  end
end
