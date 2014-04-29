all:
	$(info 'Nothing todo!')
	$(info 'Use make install or make uninstall')


install:
	mkdir -p /usr/local/mpw
	cp -rv ./MPW /usr/local/mpw/
	cp -rv ./i18n /usr/local/mpw/
	cp -v ./mpw /usr/local/mpw/
	ln -snvf /usr/local/mpw/mpw /usr/local/bin/
	cp -v ./mpw-server /usr/local/mpw/
	ln -snvf /usr/local/mpw/mpw-server /usr/local/bin/mpw-server
	cp -v ./mpw-ssh /usr/local/mpw/
	ln -snvf /usr/local/mpw/mpw-ssh /usr/local/bin/mpw-ssh

uninstall:
	rm -v /usr/local/bin/mpw-server
	rm -v /usr/local/bin/mpw
	rm -v /usr/local/bin/mpw-ssh
	rm -rf /usr/local/mpw
