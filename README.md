# MPW: Manage your passwords!
[![Version](https://img.shields.io/badge/latest_version-4.2.2-green.svg)](https://github.com/nishiki/manage-password/releases)
[![Build Status](https://travis-ci.org/nishiki/manage-password.svg?branch=master)](https://travis-ci.org/nishiki/manage-password)
[![License](https://img.shields.io/badge/license-GPL--2.0-blue.svg)](https://github.com/nishiki/manage-password/blob/master/LICENSE)

mpw is a little software which stores your passwords in [GnuPG](http://www.gnupg.org/) encrypted files.

## Features

 * generate random password
 * generate OTP code
 * copy your login, password or otp in clipboard
 * manage many wallets
 * share a wallet with others GPG keys

## Install

On debian or ubuntu:
```
apt install ruby ruby-dev xclip
gem install mpw
```

## How to use
### First steps

Initialize your first wallet:
```
mpw config --init user@host.com
```

Add your first item:
```
mpw add --host assurance.com --port 443 --user user_2132 --protocol https --random
mpw add --host fric.com --user 230403 --otp-code 23434113 --protocol https --comment 'I love my bank' --random

```

And list your items:
```
mpw list
```
or search an item with
```
mpw list --pattern love
mpw list --group bank
```

Output:
```
Assurance
 ==========================================================================
  ID | Host                        | User        | OTP | Comment          
 ==========================================================================
  1  | https://assurance.com:443   | user_2132   |     |                  

Bank
 ==========================================================================
  ID | Host                        | User        | OTP | Comment          
 ==========================================================================
  3  | https://fric.com            | 230403      |  X  | I love my bank   
```

Copy a password, login or OTP code:
```
mpw copy -p assurance.com
```

Update an item:
```
mpw update -p assurance.com
```

Delete an item:
```
mpw delete -p assurance.com
```

### Manage wallets

List all available wallets:
```
mpw wallet
```

List all GPG keys in wallet:
```
mpw wallet --list-keys [--wallet NAME]
```

Share with an other GPG key:
```
mpw wallet --add-gpg-key test42@localhost.com
 or
mpw wallet --add-gpg-key /path/to/file
```

Remove a GPG key:
```
mpw wallet --delete-gpg-key test42@localhost.com
```

### Export and import data

You can export your data in yaml file with your passwords in clear text:
```
mpw export --file export.yml
```

Import data from an yaml file:
```
mpw import --file import.yml
```

Example yaml file for mpw:

```
---
1:
  host: fric.com
  user: 230403
  group: Bank
  password: 5XdiTQOubRDw9B0aJoMlcEyL
  protocol: https
  port:
  otp_key: 330223432
  comment: I love my bank
2:
  host: assurance.com
  user: user_2132
  group: Assurance
  password: DMyK6B3v4bWO52VzU7aTHIem
  protocol: https
  port: 443
  otp_key:
  comment:
```

### Config

Print the current config
```
mpw config
```

Output:

```
Configuration
 ==============================================
  lang             | fr
  gpg_key          | mpw@yae.im
  default_wallet   |
  config_dir       | /home/mpw/.config/mpw
  pinmode          | true
  gpg_exe          |
  path_wallet_test | /tmp/test.mpw
  password_numeric | true
  password_alpha   | true
  password_special | false
  password_length  | 16

```
