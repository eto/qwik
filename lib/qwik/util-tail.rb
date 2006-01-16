#
# copied from ruby-list
# http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/45971
#

class Tail
  TAIL_TOP = 1
  TAIL_END = 2
  TAIL_SEEK = 3

  def initialize(filename, seek, whence)
    @filename = filename

    begin
      @fileh = File.open(filename)
    rescue Errno::ENOENT
      retry
    end

    @ino = @fileh.stat.ino
    @ino_changed = false

    case whence
    when TAIL_TOP
      raise 'Must specify non-negative number for TAIL_TOP' unless seek >= 0
      wind(seek)
    when TAIL_END
      raise 'Must specify non-positive number for TAIL_END' unless seek <= 0
      rewind(seek)
    when TAIL_SEEK
      raise "Invalid file position #{seek} for file #{@filename}" unless
	seek >= 0 && seek <= @fileh.stat.size
      @fileh.seek(seek, IO::SEEK_SET)
    else
      raise "Invalid value for whence #{whence}"
    end
  end

  def wind(lines)
    @fileh.seek(0, IO::SEEK_SET)

    numlines = 0
    0.upto(@fileh.stat.size) { |filepos|
      @fileh.seek(filepos, IO::SEEK_SET)
      return if (numlines == lines)
      i = @fileh.getc
      c = sprintf('%c', i)
      numlines += 1 if (c == "\n")
    }
  end

  def rewind(lines)
    @fileh.seek(0, IO::SEEK_END)

    lines = lines.abs
    numlines = 0
    size = @fileh.stat.size - 1

    size.downto(0) { |filepos|
      next if (size == filepos)
      @fileh.seek(filepos, IO::SEEK_SET)
      i = @fileh.getc
      c = sprintf('%c', i)
      numlines += 1 if (c == "\n")
      return if (numlines == lines)
    }
  end

  def gets
    loop {
      while (@fileh.eof?)
	begin
	  if ((ino = File.stat(@filename).ino) != @ino)
	    @ino_changed = true
	  end
	rescue Errno::ENOENT
	  retry
	end

	if (@ino_changed)
	  @fileh.close
	  initialize(@filename, 0, TAIL_TOP)
	  @ino_changed = false
	  next
	end

	sleep 0.5
	@fileh.seek(0, IO::SEEK_CUR)
      end

      line = @fileh.gets
      if block_given?
	yield line
      else
	return line
      end
    }
  end
end

if $0 == __FILE__
  filename = ARGV.shift

  if filename.nil?
    puts 'Usage: util-tail.rb filename'
    exit
  end

  tail = Tail.new(filename, -10, Tail::TAIL_END)
  tail.gets { |line|
    print line
  }
  #while (line = tail.gets) 
  #  print line
  #end
end
