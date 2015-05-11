#!/usr/bin/ruby
# author: nishiki
# mail: nishiki@yaegashi.fr

require 'rubygems'
require 'gpgme'
require 'yaml'
require 'i18n'
	
module MPW
	class Config
		
		attr_accessor :error_msg
	
		attr_accessor :key
		attr_accessor :share_keys
		attr_accessor :lang
		attr_accessor :file_gpg
		attr_accessor :last_update
		attr_accessor :sync_type
		attr_accessor :sync_host
		attr_accessor :sync_port
		attr_accessor :sync_user
		attr_accessor :sync_pwd
		attr_accessor :sync_path
		attr_accessor :last_sync
		attr_accessor :dir_config
	
		# Constructor
		# @args: file_config -> the specify config file
		def initialize(file_config=nil)
			@error_msg  = nil

			if /darwin/ =~ RUBY_PLATFORM
				@dir_config = "#{Dir.home}/Library/Preferences/mpw"
			elsif /cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM
				@dir_config = "#{Dir.home}/AppData/Local/mpw"
			else 
				@dir_config = "#{Dir.home}/.config/mpw"
			end
			
			@file_config = "#{@dir_config}/conf/default.cfg"
			if not file_config.nil? and not file_config.empty?
				@file_config = file_config
			end
		end
	
		# Create a new config file
		# @args: key -> the gpg key to encrypt
		#        share_keys -> multiple keys to share the password with other people
		#        lang -> the software language
		#        file_gpg -> the file who is encrypted
		#        sync_type -> the type to synchronization
		#        sync_host -> the server host for synchronization
		#        sync_port -> the server port for synchronization
		#        sync_user -> the user for synchronization
		#        sync_pwd -> the password for synchronization
		#        sync_suffix -> the suffix file (optionnal) 
		# @rtrn: true if le config file is create
		def setup(key, share_keys, lang, file_gpg, sync_type, sync_host, sync_port, sync_user, sync_pwd, sync_path)
	
			if not key =~ /[a-zA-Z0-9.-_]+\@[a-zA-Z0-9]+\.[a-zA-Z]+/
				@error_msg = I18n.t('error.config.key_bad_format')
				return false
			end

			if not check_public_gpg_key(share_keys)
				return false
			end
			
			if file_gpg.empty?
				file_gpg = "#{@dir_config}/db/default.gpg"
			end
	
			config = {'config' => {'key'         => key,
			                       'share_keys'  => share_keys,
			                       'lang'        => lang,
			                       'file_gpg'    => file_gpg,
			                       'sync_type'   => sync_type,
			                       'sync_host'   => sync_host,
			                       'sync_port'   => sync_port,
			                       'sync_user'   => sync_user,
			                       'sync_pwd'    => sync_pwd,
			                       'sync_path'   => sync_path,
			                       'last_sync' => 0 
			                      }
			         }
	
			Dir.mkdir("#{@config_dir}/conf", 700)
			Dir.mkdir("#{@config_dir}/db", 700)
			File.open(@file_config, 'w') do |file|
				file << config.to_yaml
			end
			
			return true
		rescue Exception => e 
			@error_msg = "#{I18n.t('error.config.write')}\n#{e}"
			return false
		end

		# Setup a new gpg key
		# @args: password -> the GPG key password
		#        name -> the name of user
		#        length -> length of the GPG key
		#        expire -> the time of expire to GPG key
		# @rtrn: true if the GPG key is create, else false
		def setup_gpg_key(password, name, length = 2048, expire = 0)
			if name.nil? or name.empty?
				@error_msg = "#{I18n.t('error.config.genkey_gpg.name')}"
				return false
			elsif password.nil? or password.empty?
				@error_msg = "#{I18n.t('error.config.genkey_gpg.password')}"
				return false
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

			return true
		rescue Exception => e
			@error_msg = "#{I18n.t('error.config.genkey_gpg.exception')}\n#{e}"
			return false
		end
	
		# Check the config file
		# @rtrn: true if the config file is correct
		def checkconfig
			config = YAML::load_file(@file_config)
			@key        = config['config']['key']
			@share_keys = config['config']['share_keys']
			@lang       = config['config']['lang']
			@file_gpg   = config['config']['file_gpg']
			@sync_type  = config['config']['sync_type']
			@sync_host  = config['config']['sync_host']
			@sync_port  = config['config']['sync_port']
			@sync_user  = config['config']['sync_user']
			@sync_pwd   = config['config']['sync_pwd']
			@sync_path  = config['config']['sync_path']
			@last_sync  = config['config']['last_sync'].to_i

			if @key.empty? or @file_gpg.empty? 
				@error_msg = I18n.t('error.config.check')
				return false
			end
			I18n.locale = @lang.to_sym

			return true
		rescue Exception => e 
			puts e
			@error_msg = "#{I18n.t('error.config.check')}\n#{e}"
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

		# Check if private key exist
		# @args: share_keys -> string with all public keys
		# @rtrn: true if the key exist, else false
		def check_public_gpg_key(share_keys = @share_keys)
			ctx = GPGME::Ctx.new

			share_keys = share_keys.nil? ? '' : share_keys
			if not share_keys.empty?
				share_keys.split.each do |k|
					if not k =~ /[a-zA-Z0-9.-_]+\@[a-zA-Z0-9]+\.[a-zA-Z]+/
						@error_msg = I18n.t('error.config.key_bad_format')
						return false
					end
					
					ctx.each_key(key, false) do
						next
					end

					@error_msg = I18n.t('error.config.no_key_public', key: k)
					return false
				end
			end

			return true
		end
	
		# Set the last update when there is a sync
		# @rtrn: true is the file has been updated
		def set_last_sync
			config = {'config' => {'key'         => @key,
			                       'share_keys'  => @share_keys,
			                       'lang'        => @lang,
			                       'file_gpg'    => @file_gpg,
			                       'sync_type'   => @sync_type,
			                       'sync_host'   => @sync_host,
			                       'sync_port'   => @sync_port,
			                       'sync_user'   => @sync_user,
			                       'sync_pwd'    => @sync_pwd,
			                       'sync_path'   => @sync_path,
			                       'last_sync' => Time.now.to_i
			                      }
		           }
	
			File.open(@file_config, 'w') do |file|
				file << config.to_yaml
			end

			return true
		rescue Exception => e 
			@error_msg = "#{I18n.t('error.config.write')}\n#{e}"
			return false
		end
		
	end
end
