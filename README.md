# Manage your passwords!

MPW is a little software which stores your passwords in an GPG encrypted file.
MPW can synchronize your password with a MPW Server or via SSH or via FTP.

# Installation

You must generate a GPG Key with GPG or with Seahorse (GUI on linux).
This program work with ruby >= 1.9

* install ruby on your computer
* gem install bundler
* bundle install 
or
* bundle install --without ssh # if you don't want synchronize your password via SSH

## On Debian/Ubuntu:

* apt-get install ruby ruby-gpgme ruby-highline ruby-i18n ruby-locale

If you want to synchronize your passwords via SSH/SCP:
* apt-get install ruby-net-ssh ruby-net-scp

For mpw-ssh:
* apt-get install sshpass


