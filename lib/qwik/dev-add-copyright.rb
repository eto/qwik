# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

$LOAD_PATH.unshift '..' unless $LOAD_PATH.include? '..'
require 'qwik/util-pathname'

COPYRIGHT_BANNER = <<END
# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

END

ARGV.each {|fname|
  #s = File.read(fname)
  s = fname.path.read
  unless /\A#/ =~ s
    s = COPYRIGHT_BANNER + s
    fname.path.write(s)
    #File.open(fname, "w"){|f| f.write(s) }
  end
}
