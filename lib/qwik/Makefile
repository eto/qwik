RUBY=ruby

all:	m

# test suites.
a:		test-suite-all
b:		test-suite-basic
m:		test-suite-ml
test-suite-all:
	$(RUBY) test-suite-all.rb
test-suite-basic:
	$(RUBY) test-suite-basic.rb
test-suite-ml:
	$(RUBY) test-suite-ml.rb

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
	-rm -rf test www
	-rm t qwik-error.log .#* *~ *.stackdump
	-rm ../../cache/sid/????????????????????????????????

realclean:	clean
	-rm *.profile profile.txt rbprof.txt rbprof-bench.txt rbprof-table.txt
	-rm rubyprof-bench.txt log
