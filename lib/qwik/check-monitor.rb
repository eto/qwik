def check_monitor_main
  require 'monitor.rb'

  buf = []
  buf.extend(MonitorMixin)
  empty_cond = buf.new_cond

  # consumer
  Thread.start {
    loop {
      buf.synchronize {
	empty_cond.wait_while { buf.empty? }
	print buf.shift
      }
    }
  }

  # producer
  while line = ARGF.gets
    buf.synchronize {
      buf.push(line)
      empty_cond.signal
    }
  end
end

if $0 == __FILE__
  check_monitor_main
end
