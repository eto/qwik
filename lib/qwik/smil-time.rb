# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'

module Qwik
  class SmilTime < Time
    def to_smil
      str = self.strftime('%H:%M:%S')
      frame = SmilTime.usec_to_frame(self.usec)
      str += '.'+sprintf('%02d', frame) if 0 < frame
      return str
    end

    def self.at_smil(arg)
      raise 'arg must be String' unless arg.is_a?(String)
      hour, min, sec, frame = SmilTime.parse_smil(arg)
      return SmilTime.gm(1970, 1, 1, hour, min, sec, frame_to_usec(frame))
    end

    def self.frame_to_usec(frame)
      return (1000000.0 * frame.to_f / 30.0).to_i
    end

    def self.usec_to_frame(usec)
      return (30.0 * usec.to_f / 1000000.0 + 0.5).to_i	# half adjust
    end

    def self.parse_smil(str)
      hour = min = sec = frame = 0
      if str.include?('.')
	str, frame = str.split('.', 2)
	frame = with_range(frame.to_i, 0, 29)
      end
      ar = str.split(/:/)
      sec = with_range(ar.pop.to_i, 0, 59)
      min = with_range(ar.pop.to_i, 0, 59)
      hour = with_range(ar.pop.to_i, 0, 999999) # without max
      return [hour, min, sec, frame]
    end

    def self.with_range(n, min, max)
      n = min if n < min
      n = max if max < n
      return n
    end
  end
end

if $0 == __FILE__
  require 'qwik/testunit'
  $test = true
end

if defined?($test) && $test
  class TestSmilTime < Test::Unit::TestCase
    def test_all
      c = Qwik::SmilTime

      # test_to_smil
      ok_eq('12:34:56.15', c.at_smil('12:34:56.15').to_smil)
      ok_eq('12:34:56', c.at_smil('12:34:56').to_smil)
      ok_eq('00:12:34', c.at_smil('12:34').to_smil)
      ok_eq('00:00:12.15', c.at_smil('12.15').to_smil)
      ok_eq('00:00:12.05', c.at_smil('12.05').to_smil)

      # test_at_smil
      t = c.at_smil('12')
      ok_eq(12.0, t.to_f)
      ok_eq(c.at(12), t) # same

      t = c.at_smil('12.15')
      ok_eq(12.5, t.to_f)
      ok_eq(c.at(12.5), t) # same

      # should test with range...
      ok_eq(12.333333, c.at_smil('12.10').to_f)
      ok_eq(45296.5, c.at_smil('12:34:56.15').to_f)

      # test_frame_to_usec
      ok_eq(500000, c.frame_to_usec(15))

      # test_usec_to_frame
      ok_eq(15, c.usec_to_frame(500000))

      (0..30).each {|n|
	usec = c.frame_to_usec(n)
	frame = c.usec_to_frame(usec)
	ok_eq(n, frame)
      }

      # test_parse_smil
      ok_eq([ 0,  0, 12,  0], c.parse_smil('12'))
      ok_eq([ 0, 12, 34,  0], c.parse_smil('12:34'))
      ok_eq([12, 34, 56,  0], c.parse_smil('12:34:56'))
      ok_eq([12, 34, 56, 15], c.parse_smil('12:34:56.15'))
      ok_eq([ 0, 12, 34, 15], c.parse_smil('12:34.15'))

      # test_with_range
      ok_eq(0,  c.with_range(-1, 0, 29))
      ok_eq(29, c.with_range(30, 0, 29))
    end
  end
end
