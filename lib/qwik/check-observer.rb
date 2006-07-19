# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

require 'observer'

class Ticker          ### Periodically fetch a stock price.
  include Observable

  def initialize(symbol)
    @symbol = symbol
  end

  def run
    lastPrice = nil
    loop {
      price = Price.fetch(@symbol)
      print "Current price: #{price}\n"
      if price != lastPrice
        changed                 # notify observers
        lastPrice = price
        notify_observers(Time.now, price)
      end
      sleep 1
    }
  end
end

class Price           ### A mock class to fetch a stock price (60 - 140).
  def Price.fetch(symbol)
    60 + rand(80)
  end
end

class Warner          ### An abstract observer of Ticker objects.
  def initialize(ticker, limit)
    @limit = limit
    ticker.add_observer(self)
  end
end

class WarnLow < Warner
  def update(time, price)       # callback for observer
    if price < @limit
      print "--- #{time.to_s}: Price below #@limit: #{price}\n"
    end
  end
end

class WarnHigh < Warner
  def update(time, price)       # callback for observer
    if price > @limit
      print "+++ #{time.to_s}: Price above #@limit: #{price}\n"
    end
  end
end

def check_observer_main
  ticker = Ticker.new('MSFT')
  WarnLow.new(ticker, 80)
  WarnHigh.new(ticker, 120)
  ticker.run
end

if $0 == __FILE__
  check_observer_main
end
