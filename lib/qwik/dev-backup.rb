$LOAD_PATH << '../../lib' unless $LOAD_PATH.include?('../../lib')

module Qwik
  class Backup
    def self.main(argv)
      Dir.chdir($base)
      date = Time.now.strftime('%Y-%m-%dT%H')
      if ! FileTest.exist?('backup')
	Dir.mkdir('backup')
      end
      cmd = "tar cfj backup/data-#{date}.tar.bz2 data"
      puts cmd
      system cmd
    end
  end
end

if $0 == __FILE__
  Qwik::Backup.main(ARGV)
end
