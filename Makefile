all:
	$(info 'Nothing todo!')
	$(info 'Use make install or make uninstall')

dep-ubuntu:
	apt-get install ruby ruby-gpgme ruby-highline ruby-i18n ruby-locale

install:
	mkdir -p /usr/local/mpw
	cp -r ./MPW /usr/local/mpw/
	cp -r ./i18n /usr/local/mpw/
	cp ./mpw /usr/local/mpw/
	ln -snf /usr/local/mpw/mpw /usr/local/bin/
	cp ./mpw-server /usr/local/mpw/
	ln -snf /usr/local/mpw/mpw-server /usr/local/bin/mpw-server
	cp ./mpw-ssh /usr/local/mpw/
	ln -snf /usr/local/mpw/mpw-ssh /usr/local/bin/mpw-ssh

uninstall:
	rm /usr/local/bin/mpw-server
	rm /usr/local/bin/mpw
	rm /usr/local/bin/mpw-ssh
	rm -rf /usr/local/mpw
