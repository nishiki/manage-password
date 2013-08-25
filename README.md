# Manage your passwords!

MPW is a little software, who stock your passwords in an encrypt file (with GPG).

# Usage

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


# Installation

You must generate a GPG Key with GPG or with Seahorse (GUI on linux).

## On Debian/Ubuntu:

* apt-get install ruby ruby-gpgme ruby-highline
