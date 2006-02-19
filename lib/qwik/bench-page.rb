$LOAD_PATH << '..' unless $LOAD_PATH.include? '..'
require 'qwik/bench-module-session'
require 'qwik/test-module-session'
require 'qwik/pages'

class BenchPages
  include TestSession
  include BenchmarkModule

  def self.main
    b = self.new
    b.setup
    b.bench_all
    b.teardown
  end

  def setup
    @config = Qwik::Config.new
    @dir = 'test/'.path
    @wwwdir = @dir

    # setup dir
    @wwwdir = 'www/'.path
    @wwwdir.setup
    @dir = 'test/'.path
    @dir.setup

    @pages = Qwik::Pages.new(@config, @dir)
  end

  def bench_all
    n = 10000
    page = @pages['TextFormat']
    benchmark {
      n.times {
	title = page.get_title
	#title = page.key
      }
    }
    @pages.erase_all if @pages
  end
end

if $0 == __FILE__
  BenchPages.main
end
