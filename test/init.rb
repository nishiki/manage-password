#!/usr/bin/ruby

require 'fileutils'
require 'gpgme'

FileUtils.rm_rf("#{Dir.home}/.config/mpw")
FileUtils.rm_rf("#{Dir.home}/.gnupg")

param = ''
param << '<GnupgKeyParms format="internal">' + "\n"
param << "Key-Type: RSA\n"
param << "Key-Length: 512\n"
param << "Subkey-Type: ELG-E\n"
param << "Subkey-Length: 512\n"
param << "Name-Real: test\n"
param << "Name-Comment: test\n"
param << "Name-Email: test2@example.com\n"
param << "Expire-Date: 0\n"
param << "Passphrase: password\n"
param << "</GnupgKeyParms>\n"

ctx = GPGME::Ctx.new
ctx.genkey(param, nil, nil)
