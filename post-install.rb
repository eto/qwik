# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

system 'mkdir -p /var/lib/qwik/data/www'
open('/var/lib/qwik/data/www/_SiteConfig.txt', 'wb') {|f|
  f.puts ':open:true'
}
open('/var/lib/qwik/data/www/_GroupMembers.txt', 'wb') {|f|
  f.puts 'guest@qwik'
}

%w(
/var/cache/qwik
/var/lib/qwik
/var/lib/qwik/data
/var/lib/qwik/data/www
/var/log/qwik
/var/run/qwik
).each {|dir|
  system "mkdir #{dir}" if ! File.exist?(dir)
  system "chown -R daemon.daemon #{dir}"
  system "chmod -R go+w #{dir}"
}

=begin
%w(
/var/lib/qwik/data/www/_SiteConfig.txt
/var/lib/qwik/data/www/_GroupMembers.txt
).each {|file|
  system "chmod -R go+w #{dir}"
}
=end
