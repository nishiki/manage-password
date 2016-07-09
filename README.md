# Manage your passwords!

MPW is a little software which stores your passwords in an GPG encrypted file.
MPW can synchronize your password with SSH or FTP.

# Installation

This program work with ruby >= 2.0

* install ruby and rubygems on your computer
* install xclip
* gem install mpw

# How to use

* Show help
```
mpw --help
```

* Setup a new config file
```
mpw --setup
mpw --setup --config /path/conf/file.cfg
```

* Create and setup a new wallet
```
mpw --setup-wallet --wallet new_wallet_name
mpw --setup-wallet --wallet new_wallet_name --config /path/conf/file.cfg 
```

* Add a GPG key in wallet
```
mpw --add --key root@localhost.local
mpw --add --key root@localhost.local --config /path/conf/file.cfg 
mpw --add --key root@localhost.local --wallet wallet_name
mpw --add --key root@localhost.local --config /path/conf/file.cfg --wallet wallet_name
```

* Add a new  GPG key in wallet
```
mpw --add --key root@localhost.local --file /path/gpg/file.pub
mpw --add --key root@localhost.local --file /path/gpg/file.pub --config /path/conf/file.cfg 
mpw --add --key root@localhost.local --file /path/gpg/file.pub --wallet wallet_name
mpw --add --key root@localhost.local --file /path/gpg/file.pub --config /path/conf/file.cfg --wallet wallet_name
```

* Delete a GPG key in wallet
```
mpw --delete --key root@localhost.local
mpw --delete --key root@localhost.local --wallet wallet_name
mpw --delete --key root@localhost.local --wallet wallet_name --config /path/conf/file.cfg 
```

* Add a new item in wallet
```
mpw --add 
mpw --add --config /path/conf/file.cfg
mpw --add --wallet wallet_name
mpw --add --config /path/conf/file.cfg --wallet wallet_name
```

* Update an item
```
mpw --update --id uniq_id
mpw --update --id uniq_id --config /path/conf/file.cfg
mpw --update --id uniq_id --wallet wallet_name
mpw --update --id uniq_id --config /path/conf/file.cfg --wallet wallet_name
```

* Delete an item
```
mpw --delete --id uniq_id
mpw --delete --id uniq_id --config /path/conf/file.cfg
mpw --delete --id uniq_id --wallet wallet_name
mpw --delete --id uniq_id --config /path/conf/file.cfg --wallet wallet_name
```

* Show an item
```
mpw --show 'string to search'
mpw --show 'string to search' --config /path/conf/file.cfg
mpw --show 'string to search' --wallet wallet_name
mpw --show 'string to search' --config /path/conf/file.cfg --wallet wallet_name
mpw --show 'string to search' --group group_name
mpw --show 'string to search' --group group_name --config /path/conf/file.cfg
mpw --show 'string to search' --group group_name --wallet wallet_name
mpw --show 'string to search' --group group_name --config /path/conf/file.cfg --wallet wallet_name
```

* Export data in YAML file
```
mpw --export --file /path/file/to/export.yml
mpw --export --file /path/file/to/export.yml --config /path/conf/file.cfg
mpw --export --file /path/file/to/export.yml --wallet wallet_name
mpw --export --file /path/file/to/export.yml --config /path/conf/file.cfg --wallet wallet_name
```

* Import data from YAML file
```
mpw --import --file /path/file/to/export.yml
mpw --import --file /path/file/to/export.yml --config /path/conf/file.cfg
mpw --import --file /path/file/to/export.yml --wallet wallet_name
mpw --import --file /path/file/to/export.yml --config /path/conf/file.cfg --wallet wallet_name
```

Format file to import:
```
1:
  name: Website perso
  group: Perso
  host: localhost.local
  protocol: ftp
  user: test
  password: letoortue
  port: 21
  comment: Mysuper website
2:
  name: Linuxfr
  group: Pro
  host: Linuxfr.org
  protocol: https
  user: test
  password: coucou 
  port: 
  comment: 
```
