# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

RUBY=ruby

default:	test

debug:
	$(RUBY) -Ilib bin/qwikweb-server -d -c etc/config-debug.txt

mldebug:
	$(RUBY) -Ilib bin/quickml-server -d -c etc/config-debug.txt

run:
	$(RUBY) -Ilib bin/qwikweb-server -c etc/config.txt

mlrun:
	$(RUBY) -Ilib bin/qwikweb-server -c etc/config.txt

watch:
	$(RUBY) -Ilib bin/qwik-service --watchlog -c etc/config-debug.txt

test:
	cd lib/qwik; make; cd ../..

version:
	$(RUBY) -Ilib lib/qwik/dev-release.rb --generate-vesrion

manifest:	version
	$(RUBY) -Ilib lib/qwik/dev-release.rb --generate-manifest

dist:	manifest
	$(RUBY) -Ilib lib/qwik/dev-release.rb --generate-dist

upload:	dist
	$(RUBY) -Ilib lib/qwik/dev-release.rb --upload

clean:
	-rm *~ .config InstalledFiles
	cd lib/qwik; make clean; cd ../..

realclean:	clean
	-rm MANIFEST
	cd ext; make clean; cd ..

.PHONY: debug mldebug run mlrun watch test version manifest dist upload clean realclean
