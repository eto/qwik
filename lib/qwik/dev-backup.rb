# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

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
