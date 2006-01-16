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
