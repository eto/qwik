# Copyright (C) 2003-2006 Kouichirou Eto, All rights reserved.
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute it and/or modify it under the terms of the GNU GPL 2.

RUBY=ruby

all:
	$(RUBY) -I../../../lib ../../../lib/qwik/dev-js-compressor.rb

clean:
	rm ../all.js

x:
	chmod -x *.js *.html .cvsignore Makefile

dist:	debugwindow.tar.bz2

debugwindow.tar.bz2:	debugwindow.js debugwindow.html debugwindow-test.html
	mkdir debugwindow
	mv debugwindow.js debugwindow.html debugwindow-test.html debugwindow
	tar cvfj debugwindow.tar.bz2 debugwindow
	mv debugwindow/* .
	rmdir debugwindow
