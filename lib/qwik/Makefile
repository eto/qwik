# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

RUBY=ruby

default:	test-suite-all

# shorcut for test suites.
a:		test-suite-all
b:		test-suite-basic
m:		test-suite-ml

# test suites.
test-suite-all:
	$(RUBY) -I.. test-suite-all.rb
test-suite-basic:
	$(RUBY) -I.. test-suite-basic.rb
test-suite-ml:
	$(RUBY) -I.. test-suite-ml.rb

# For production test.
checkmail:
	$(RUBY) dev-sendmail.rb

# profiles
profile:
	$(RUBY) -rprofile -Icompat test-suite-basic.rb 2> profile.txt
rbprof:
	$(RUBY) -rrbprof -Icompat test-suite-basic.rb 2>rbprof.txt

# benchmarks
bench:
	$(RUBY) -runprof bench-s-md5.rb 2> rubyprof-bench.txt
bench-page:
	$(RUBY) -rrbprof -Icompat bench-page.rb 2> rbprof-page.txt
bench-textformat:
	$(RUBY) -rrbprof -Icompat bench-textformat.rb 2> rbprof-textformat.txt

x:
	-chmod 644 *.rb .cvsignore Makefile dev-*

# clean
clean:
	-rm -rf .test
	-rm -rf test
	-rm quickml.log

oldclean:
	-rm -rf site_test
	-rm -rf compat/.cache
	-rm -rf compat/compat
	-rm -rf www sid
	-rm testtemp.zip
	-rm access.log qwik-access.log qwik-error.log
	-rm generation.txt testlog.txt
	-rm t .#* *~ *.stackdump
	-rm ../../cache/sid/????????????????????????????????

realclean:	clean
	-rm *.profile profile.txt rbprof.txt rbprof-bench.txt rbprof-table.txt
	-rm rubyprof-bench.txt log
	-rm *.bak
