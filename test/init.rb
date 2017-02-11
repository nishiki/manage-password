#!/usr/bin/ruby

require 'gpgme'

param = ''
param << '<GnupgKeyParms format="internal">' + "\n"
param << "Key-Type: RSA\n"
param << "Key-Length: 2048\n"
param << "Subkey-Type: ELG-E\n"
param << "Subkey-Length: 2048\n"
param << "Name-Real: test\n"
param << "Name-Comment: test\n"
param << "Name-Email: test2@example.com\n"
param << "Expire-Date: 0\n"
param << "Passphrase: password\n"
param << "</GnupgKeyParms>\n"

ctx = GPGME::Ctx.new
ctx.genkey(param, nil, nil)
