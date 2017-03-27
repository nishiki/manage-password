# MPW: Manage your passwords!
[![Version](https://img.shields.io/badge/latest_version-4.0.0-green.svg)](https://github.com/nishiki/manage-password/releases)
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
mpw add
```

And list your items:
```
mpw list
```
or search an item with
```
mpw list --pattern Da
mpw list --group bank
```

Output:
```
Bank
 ==============================================================================
  ID | Host          | User      | Protocol | Port | OTP | Comment                
 ==============================================================================
  1  | bank.com      | 1234456   | https    |      |  X  |                        

Linux
 ==============================================================================
  ID | Host          | User      | Protocol | Port | OTP | Comment                
 ==============================================================================
  2  | linuxfr.org   | example   | https    |      |     | Da Linux French Site

```

Copy a password, login or OTP code:
```
mpw copy -p linuxfr
```

Update an item:
```
mpw update -p linuxfr
```

Delete an item:
```
mpw delete -p linuxfr
```

### Manage wallets

List all available wallets:
```
mpw wallet --list
```

Create an other wallet:
```
mpw config --wallet work --init user@host.com
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
  host: bank.com
  user: 123456
  group: Bank
  password: secret
  protocol: https
  port: 
  otp_key: 1afg34
  comment: 
2:
  host: linuxfr.org
  user: example
  group: 
  password: 'complex %- password'
  protocol: https
  port: 
  otp_key: 
  comment: Da Linux French Site
```
