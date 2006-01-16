RUBY=ruby

debug:
	$(RUBY) bin/qwikweb-server -d -c etc/config.txt

mldebug:
	$(RUBY) bin/quickml-server -d -c etc/config.txt

run:
	$(RUBY) bin/qwikweb-server -c etc/config.txt

mlrun:
	$(RUBY) bin/qwikweb-server -c etc/config.txt

watch:
	$(RUBY) bin/qwikweb-watchlog -c etc/config.txt

test:
	cd lib/qwik; make; cd ../..

version:
	$(RUBY) -Ilib lib/qwik/dev-release.rb -v

manifest:	version
	$(RUBY) -Ilib lib/qwik/dev-release.rb -m

dist:	manifest
	$(RUBY) -Ilib lib/qwik/dev-release.rb -d

upload:	dist
	$(RUBY) -Ilib lib/qwik/dev-release.rb -u

clean:
	-rm *~

realclean:	clean
	-rm MANIFEST
	cd ext; make clean; cd ..
