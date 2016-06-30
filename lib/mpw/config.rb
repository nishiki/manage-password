#!/usr/bin/ruby
# MPW is a software to crypt and manage your passwords
# Copyright (C) 2016  Adrien Waksberg <mpw@yae.im>
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require 'gpgme'
require 'yaml'
require 'i18n'
require 'fileutils'
	
module MPW
class Config
	
	attr_accessor :error_msg

	attr_accessor :key
	attr_accessor :lang
	attr_accessor :config_dir
	attr_accessor :wallet_dir

	# Constructor
	# @args: config_file -> the specify config file
	def initialize(config_file=nil)
		@config_file = config_file

		if /darwin/ =~ RUBY_PLATFORM
			@config_dir = "#{Dir.home}/Library/Preferences/mpw"
		elsif /cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM
			@config_dir = "#{Dir.home}/AppData/Local/mpw"
		else 
			@config_dir = "#{Dir.home}/.config/mpw"
		end
		
		if @config_file.nil? or @config_file.empty?
			@config_file = "#{@config_dir}/mpw.cfg"
		end
	end

	# Create a new config file
	# @args: key -> the gpg key to encrypt
	#        lang -> the software language
	#        wallet_dir -> the  directory where are the wallets password
	# @rtrn: true if le config file is create
	def setup(key, lang, wallet_dir)

		if not key =~ /[a-zA-Z0-9.-_]+\@[a-zA-Z0-9]+\.[a-zA-Z]+/
			raise I18n.t('error.config.key_bad_format')
		end

		if wallet_dir.empty?
			wallet_dir = "#{@config_dir}/wallets"
		end

		config = {'config' => {'key'        => key,
		                       'lang'       => lang,
		                       'wallet_dir' => wallet_dir,
		                      }
		         }

		FileUtils.mkdir_p(wallet_dir, mode: 0700)
		File.open(@config_file, 'w') do |file|
			file << config.to_yaml
		end
		
	rescue Exception => e 
		raise "#{I18n.t('error.config.write')}\n#{e}"
	end

	# Setup a new gpg key
	# @args: password -> the GPG key password
	#        name -> the name of user
	#        length -> length of the GPG key
	#        expire -> the time of expire to GPG key
	# @rtrn: true if the GPG key is create, else false
	def setup_gpg_key(password, name, length = 4096, expire = 0)
		if name.nil? or name.empty?
			raise "#{I18n.t('error.config.genkey_gpg.name')}"
		elsif password.nil? or password.empty?
			raise "#{I18n.t('error.config.genkey_gpg.password')}"
		end

		param = ''
		param << '<GnupgKeyParms format="internal">' + "\n"
		param << "Key-Type: DSA\n"  
		param << "Key-Length: #{length}\n"
		param << "Subkey-Type: ELG-E\n"
		param << "Subkey-Length: #{length}\n"
		param << "Name-Real: #{name}\n"
		param << "Name-Comment: #{name}\n"
		param << "Name-Email: #{@key}\n"
		param << "Expire-Date: #{expire}\n"
		param << "Passphrase: #{password}\n"
		param << "</GnupgKeyParms>\n"

		ctx = GPGME::Ctx.new
		ctx.genkey(param, nil, nil)
	rescue Exception => e
		raise "#{I18n.t('error.config.genkey_gpg.exception')}\n#{e}"
	end

	# Check the config file
	# @rtrn: true if the config file is correct
	def is_valid?
		config      = YAML::load_file(@config_file)
		@key        = config['config']['key']
		@lang       = config['config']['lang']
		@wallet_dir = config['config']['wallet_dir']

		raise if @key.empty? or @wallet_dir.empty?
			
		I18n.locale = @lang.to_sym

		return true
	rescue
		return false
	end

	# Check if private key exist
	# @rtrn: true if the key exist, else false
	def check_gpg_key?
		ctx = GPGME::Ctx.new
		ctx.each_key(@key, true) do
			return true
		end

		return false
	end
end
end
