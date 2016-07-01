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

require 'readline'
require 'i18n'
require 'colorize'
require 'highline/import'

#TODO
require "#{APP_ROOT}/../lib/mpw/item.rb"
require "#{APP_ROOT}/../lib/mpw/mpw.rb"

module MPW
class Cli

	# Constructor
	# @args: config -> the config
	#        sync -> boolean for sync or not
	def initialize(config, sync=true)
		@config = config
		@sync   = sync
	end

	# Create a new config file
	# @args: lang -> the software language
	def setup(lang)
		puts I18n.t('form.setup_config.title')
		puts '--------------------'
		language   = ask(I18n.t('form.setup_config.lang', lang: lang)).to_s
		key        = ask(I18n.t('form.setup_config.gpg_key')).to_s
		wallet_dir = ask(I18n.t('form.setup_config.wallet_dir', home: "#{@config.config_dir}")).to_s

		if language.nil? or language.empty?
			language = lang
		end
		I18n.locale = language.to_sym

		@config.setup(key, lang, wallet_dir)

		raise I18n.t('error.config.check') if not @config.is_valid?

		puts "#{I18n.t('form.setup_config.valid')}".green
	rescue Exception => e
		puts "#{I18n.t('display.error')} #8: #{e}".red
		exit 2
	end
	
	# Setup a new GPG key
	def setup_gpg_key
		puts I18n.t('form.setup_gpg_key.title')
		puts '--------------------'
		ask      = ask(I18n.t('form.setup_gpg_key.ask')).to_s
		
		if not ['Y', 'y', 'O', 'o'].include?(ask)
			raise I18n.t('form.setup_gpg_key.no_create')
		end

		name     = ask(I18n.t('form.setup_gpg_key.name')).to_s
		password = ask(I18n.t('form.setup_gpg_key.password')) {|q| q.echo = false}
		confirm  = ask(I18n.t('form.setup_gpg_key.confirm_password')) {|q| q.echo = false}

		if password != confirm 
			raise I18n.t('form.setup_gpg_key.error_password')
		end

		length   = ask(I18n.t('form.setup_gpg_key.length')).to_s
		expire   = ask(I18n.t('form.setup_gpg_key.expire')).to_s
		password = password.to_s

		length = length.nil? or length.empty? ? 2048 : length.to_i
		expire = expire.nil? or expire.empty? ? 0    : expire.to_i

		puts I18n.t('form.setup_gpg_key.wait')
		
		@config.setup_gpg_key(password, name, length, expire)

		puts "#{I18n.t('form.setup_gpg_key.valid')}".green
	rescue Exception => e
		puts "#{I18n.t('display.error')} #8: #{e}".red
		exit 2
	end

	# Setup wallet config for sync
	def setup_wallet_config
		config         = {}
		config['sync'] = {}

		puts I18n.t('form.setup_wallet.title')
		puts '--------------------'
		config['sync']['type']     = ask(I18n.t('form.setup_wallet.sync_type')).to_s
		config['sync']['host']     = ask(I18n.t('form.setup_wallet.sync_host')).to_s
		config['sync']['port']     = ask(I18n.t('form.setup_wallet.sync_port')).to_s
		config['sync']['user']     = ask(I18n.t('form.setup_wallet.sync_user')).to_s
		config['sync']['password'] = ask(I18n.t('form.setup_wallet.sync_pwd')).to_s
		config['sync']['path']     = ask(I18n.t('form.setup_wallet.sync_path')).to_s

		@mpw.set_config(config)
		@mpw.write_data

		puts "#{I18n.t('form.setup_wallet.valid')}".green
	rescue Exception => e
		puts "#{I18n.t('display.error')} #10: #{e}".red
		exit 2
	end
	
	# Request the GPG password and decrypt the file
	def decrypt
		if not defined?(@mpw)
			@password = ask(I18n.t('display.gpg_password')) {|q| q.echo = false}
			@mpw = MPW.new(@config.key, @wallet_file, @password)
		end

		@mpw.read_data
		@mpw.sync if @sync
	rescue Exception => e
		puts "#{I18n.t('display.error')} #11: #{e}".red
		exit 2
	end

	# Display the query's result
	# @args: search -> the string to search
	#        protocol -> search from a particular protocol
	def display(options={})
		result = @mpw.list(options)

		case result.length
		when 0
			puts I18n.t('display.nothing')
		when 1
			display_item(result.first)
		else
			i = 1
			result.each do |item|
				print "#{i}: ".cyan
				print item.name
				print " -> #{item.comment}".magenta if not item.comment.to_s.empty?
				print "\n"

				i += 1
			end
			choice = ask(I18n.t('form.select')).to_i

			if choice >= 1 and choice < i 
				display_item(result[choice-1])
			else
				puts "#{I18n.t('display.warning')}: #{I18n.t('warning.select')}".yellow
			end
		end
	end

	# Display an item in the default format
	# @args: item -> an array with the item information
	def display_item(item)
		puts '--------------------'.cyan
		print 'Id: '.cyan
		puts  item.id
		print "#{I18n.t('display.name')}: ".cyan
		puts  item.name
		print "#{I18n.t('display.group')}: ".cyan
		puts  item.group
		print "#{I18n.t('display.server')}: ".cyan
		puts  item.host
		print "#{I18n.t('display.protocol')}: ".cyan
		puts  item.protocol
		print "#{I18n.t('display.login')}: ".cyan
		puts  item.user
		print "#{I18n.t('display.password')}: ".cyan
		puts  @mpw.get_password(item.id)
		print "#{I18n.t('display.port')}: ".cyan
		puts  item.port
		print "#{I18n.t('display.comment')}: ".cyan
		puts  item.comment
	end

	# Display the wallet
	# @args: wallet -> the wallet name
	def get_wallet(wallet=nil)
		if wallet.to_s.empty?
			wallets = Dir.glob("#{@config.wallet_dir}/*.mpw")

			case wallets.length
			when 0
				puts I18n.t('display.nothing')
			when 1
				@wallet_file = wallets[0]
			else
				i = 1
				wallets.each do |wallet|
						print "#{i}: ".cyan
						puts File.basename(wallet, '.mpw')

						i += 1
				end

				choice = ask(I18n.t('form.select')).to_i

				if choice >= 1 and choice < i
					@wallet_file = wallets[choice-1]
				else
					puts "#{I18n.t('display.warning')}: #{I18n.t('warning.select')}".yellow
				end
			end
		else
			@wallet_file = "#{@config.wallet_dir}/#{wallet}.mpw"
		end
	end

	# Add a new public key
	# args: key -> the key name to add
	#       file -> gpg public file to import
	def add_key(key, file=nil)
		@mpw.add_key(key, file)
		@mpw.write_data
		@mpw.sync if @sync

		puts "#{I18n.t('form.add_key.valid')}".green
	rescue Exception => e
		puts "#{I18n.t('display.error')} #13: #{e}".red
	end

	# Add new public key
	# args: key -> the key name to delete
	def delete_key(key)
		@mpw.delete_key(key)
		@mpw.write_data
		@mpw.sync if @sync

		puts "#{I18n.t('form.delete_key.valid')}".green
	rescue Exception => e
		puts "#{I18n.t('display.error')} #15: #{e}".red
	end

	# Form to add a new item
	def add
		options = {}

		puts I18n.t('form.add_item.title')
		puts '--------------------'
		options[:name]     = ask(I18n.t('form.add_item.name')).to_s
		options[:group]    = ask(I18n.t('form.add_item.group')).to_s
		options[:host]     = ask(I18n.t('form.add_item.server')).to_s
		options[:protocol] = ask(I18n.t('form.add_item.protocol')).to_s
		options[:user]     = ask(I18n.t('form.add_item.login')).to_s
		password           = ask(I18n.t('form.add_item.password')).to_s
		options[:port]     = ask(I18n.t('form.add_item.port')).to_s
		options[:comment]  = ask(I18n.t('form.add_item.comment')).to_s

		item = Item.new(options)

		@mpw.add(item)
		@mpw.set_password(item.id, password)
		@mpw.write_data
		@mpw.sync if @sync

		puts "#{I18n.t('form.add_item.valid')}".green
	end

	# Update an item
	# @args: id -> the item's id
	def update(id)
		item = @mpw.search_by_id(id)

		if not item.nil?
			options = {}

			puts I18n.t('form.update_item.title')
			puts '--------------------'
			options[:name]     = ask(I18n.t('form.update_item.name'    , name:     item.name)).to_s
			options[:group]    = ask(I18n.t('form.update_item.group'   , group:    item.group)).to_s
			options[:host]     = ask(I18n.t('form.update_item.server'  , server:   item.host)).to_s
			options[:protocol] = ask(I18n.t('form.update_item.protocol', protocol: item.protocol)).to_s
			options[:user]     = ask(I18n.t('form.update_item.login'   , login:    item.user)).to_s
			password           = ask(I18n.t('form.update_item.password')).to_s
			options[:port]     = ask(I18n.t('form.update_item.port'    , port:     item.port)).to_s
			options[:comment]  = ask(I18n.t('form.update_item.comment' , comment:  item.comment)).to_s

			options.delete_if { |k,v| v.empty? }
				
			item.update(options)
			@mpw.set_password(item.id, password) if not password.empty?
			@mpw.write_data
			@mpw.sync if @sync

			puts "#{I18n.t('form.update_item.valid')}".green
		else
			puts I18n.t('display.nothing')
		end
	rescue Exception => e
		puts "#{I18n.t('display.error')} #14: #{e}".red
	end

	# Remove an item
	# @args: id -> the item's id
	#        force -> no resquest a validation
	def delete(id, force=false)
		item = @mpw.search_by_id(id)

		if item.nil?
			puts I18n.t('form.delete_item.not_valid', id: id)
			return
		end

		if not force
			display_item(item)

			confirm = ask("#{I18n.t('form.delete_item.ask', id: id)} (y/N) ").to_s
			if not confirm =~ /^(y|yes|YES|Yes|Y)$/
				return
			end
		end

		item.delete
		@mpw.write_data
		@mpw.sync if @sync

		puts "#{I18n.t('form.delete_item.valid', id: id)}".green
	rescue Exception => e
		puts "#{I18n.t('display.error')} #16: #{e}".red
	end

	# Export the items in a CSV file
	# @args: file -> the destination file
	def export(file)
		@mpw.export(file)

		puts "#{I18n.t('export.export.valid', file)}".green
	rescue Exception => e
		puts "#{I18n.t('display.error')} #17: #{e}".red
	end

	# Import items from a YAML file
	# @args: file -> the import file
	def import(file)
		@mpw.import(file)
		@mpw.write_data

		puts "#{I18n.t('form.import.valid')}".green
	rescue Exception => e
		puts "#{I18n.t('display.error')} #18: #{e}".red
	end
end
end
