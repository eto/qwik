%w(/var/cache/qwik /var/lib/qwik /var/log/qwik /var/run/qwik).each {|dir|
  if ! File.exist?(dir)
    system "mkdir #{dir}"
  end
  system "chmod 777 #{dir}"
}
system 'mkdir -p /var/lib/qwik/data/www'
open('/var/lib/qwik/data/www/_SiteConfig.txt', 'wb') {|f|
  f.puts ':open:true'
}
