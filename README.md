# Manage your passwords!

MPW is a little software, who stock your passwords in an encrypt file (with GPG).

# Usage

## Interactive mode

Add a new item:
* add

Search and show item:
* show SEARCH
* show SEARCH PROTOCOL

Update an item:
* update ID

Remove an item:
* remove ID

Change group:
* group GROUP

## Cli mode

Add a new item:
* mpw -a

Search and show item:
* mpw -d SEARCH
* mpw -d SEARCH -t PROTOCOL
* mpw -A  # show all

Update an item:
* mpw -u ID

Remove an item:
* mpw -r ID

Connect to ssh:
* mpw-ssh SEARCH
* mpw-ssh SEARCH -l LOGIN -s SERVER -p PORT

Import a csv:
* mpw -i FILE

Export in a csv!
* mpw -e FILE

# Installation

You must generate a GPG Key with GPG or with Seahorse (GUI on linux).
This program work with ruby >= 1.9

## On Debian/Ubuntu:

* apt-get install ruby ruby-gpgme ruby-highline
