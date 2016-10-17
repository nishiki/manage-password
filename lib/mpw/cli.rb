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
require 'locale'
require 'i18n'
require 'colorize'
require 'highline/import'
require 'clipboard'
require 'tmpdir'
require 'mpw/item'
require 'mpw/mpw'

module MPW
class Cli

	# Constructor
	# @args: config -> the config
	#        sync -> boolean for sync or not
	#        clipboard -> enable clopboard
	#        otp -> enable otp
	def initialize(config, clipboard=true, sync=true, otp=false)
		@config    = config
		@clipboard = clipboard
		@sync      = sync
		@otp       = otp
	end

	# Change a parameter int the config after init
	# @args: options -> param to change
	def set_config(options)
		raise I18n.t('error.config.check') if not @config.is_valid?
		
		gpg_key    = options[:gpg_key]    || @config.key
		lang       = options[:lang]       || @config.lang
		wallet_dir = options[:wallet_dir] || @config.wallet_dir
		gpg_exe    = options[:gpg_exe]    || @config.gpg_exe

		@config.setup(gpg_key, lang, wallet_dir, gpg_exe)
	rescue Exception => e
		puts "#{I18n.t('display.error')} #15: #{e}".red
		exit 2
	end

	# Create a new config file
	# @args: language -> the software language
	def setup(options)
		@config.is_valid?

		lang = options[:lang] || Locale::Tag.parse(ENV['LANG']).to_simple.to_s[0..1]

		I18n.locale = lang.to_sym

		@config.setup(options[:gpg_key], lang, options[:wallet_dir], options[:gpg_exe])

		raise I18n.t('error.config.check') if not @config.is_valid?

		puts "#{I18n.t('form.setup_config.valid')}".green
	rescue Exception => e
		puts "#{I18n.t('display.error')} #8: #{e}".red
		exit 2
	end
	
	# Setup a new GPG key
	# @args: gpg_key -> the key name
	def setup_gpg_key(gpg_key)
		password = ask(I18n.t('form.setup_gpg_key.password')) {|q| q.echo = false}
		confirm  = ask(I18n.t('form.setup_gpg_key.confirm_password')) {|q| q.echo = false}

		if password != confirm 
			raise I18n.t('form.setup_gpg_key.error_password')
		end

		@password = password.to_s 

		puts I18n.t('form.setup_gpg_key.wait')
		
		@config.setup_gpg_key(@password, gpg_key)

		puts "#{I18n.t('form.setup_gpg_key.valid')}".green
	rescue Exception => e
		puts "#{I18n.t('display.error')} #8: #{e}".red
		exit 2
	end

	# Setup wallet config for sync
	# @args: wallet -> the wallet name
	def setup_wallet_config(wallet = nil)
		#config         = {}
		#config['sync'] = {}

		#puts '--------------------'
		#config['sync']['type']     = ask(I18n.t('form.setup_wallet.sync_type')).to_s

		#if ['ftp', 'ssh'].include?(config['sync']['type'].downcase)
		#	config['sync']['host']     = ask(I18n.t('form.setup_wallet.sync_host')).to_s
		#	config['sync']['port']     = ask(I18n.t('form.setup_wallet.sync_port')).to_s
		#	config['sync']['user']     = ask(I18n.t('form.setup_wallet.sync_user')).to_s
		#	config['sync']['password'] = ask(I18n.t('form.setup_wallet.sync_pwd')).to_s
		#	config['sync']['path']     = ask(I18n.t('form.setup_wallet.sync_path')).to_s
		#end

		wallet_file = wallet.nil? ? "#{@config.wallet_dir}/default.mpw" : "#{@config.wallet_dir}/#{wallet}.mpw"

		@mpw = MPW.new(@config.key, wallet_file, @password, @config.gpg_exe)
		@mpw.read_data
		@mpw.set_config
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
			@mpw      = MPW.new(@config.key, @wallet_file, @password, @config.gpg_exe)
		end

		@mpw.read_data
		@mpw.sync if @sync
	rescue Exception => e
		puts "#{I18n.t('display.error')} #11: #{e}".red
		exit 2
	end

	# Format items on a table
	def table(items=[])
		group        = '.'
		i            = 1
		length_total = 10
		length       = { id: 3,
		                 host: 10,
		                 user: 8,
		                 comment: 15,
		                 otp: 5,
		               }

		items.each do |item|
			length[:host]    = item.host.length + 3    if item.host.to_s.length > length[:host]
			length[:user]    = item.user.length + 3    if item.user.to_s.length > length[:user]
			length[:comment] = item.comment.length + 3 if item.comment.to_s.length > length[:comment]
		end
		length[:id]  = items.length.to_s.length + 2 if items.length.to_s.length > length[:id]
		
		length.each_value { |v| length_total += v }
		items.sort!       { |a,b| a.group.to_s.downcase <=> b.group.to_s.downcase }

		items.each do |item|
			if group != item.group
				group = item.group

				if group.to_s.empty?
					puts "\n#{I18n.t('display.no_group')}".red
				else
					puts "\n#{group}".red
				end

				print ' '
				length_total.times { print '=' }
				print "\n "
				print ' ID '
				print '| Host'
				(length[:host] - 'Host'.length).times { print ' ' }
				print '| User'
				(length[:user] - 'User'.length).times { print ' ' }
				print '| OTP '
				print '| Comment'
				(length[:comment] - 'Comment'.length).times { print ' ' }
				print "\n "
				length_total.times { print '=' }
				print "\n"
			end

			print "  #{i}".cyan
			(length[:id] - i.to_s.length).times { print ' ' }
			print '| '
			print "#{item.host}".yellow
			(length[:host] - item.host.to_s.length).times { print ' ' }
			print '| '
			print "#{item.user}".green
			(length[:user] - item.user.to_s.length).times { print ' ' }
			print '| '
			if item.otp
				print ' X  '
			else
				4.times { print ' ' }
			end
			print '| '
			print "#{item.comment}".magenta
			(length[:comment] - item.comment.to_s.length).times { print ' ' }
			print "\n"

			i += 1
		end

		print "\n"
	end

	# Display the query's result
	# @args: options -> the option to search
	def list(options={})
		result = @mpw.list(options)

		if result.length == 0
			puts I18n.t('display.nothing')

		else
			table(result)
		end
	end

	# Get an item when multiple choice
	# @args: items -> array of items
	# @rtrn: item
	def get_item(items)
		return items[0] if items.length == 1

		items.sort! { |a,b| a.group.to_s.downcase <=> b.group.to_s.downcase }
		choice = ask(I18n.t('form.select')).to_i

		if choice >= 1 and choice <= items.length
			return items[choice-1]
		else
			return nil
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

		if @clipboard
			print "#{I18n.t('display.password')}: ".cyan
			puts '***********'
		else
			print "#{I18n.t('display.password')}: ".cyan
			puts  @mpw.get_password(item.id)

			if @mpw.get_otp_code(item.id) > 0
				print "#{I18n.t('display.otp_code')}: ".cyan
				puts "#{@mpw.get_otp_code(item.id)} (#{@mpw.get_otp_remaining_time}s)"
			end
		end

		print "#{I18n.t('display.port')}: ".cyan
		puts  item.port
		print "#{I18n.t('display.comment')}: ".cyan
		puts  item.comment

		clipboard(item) if @clipboard
	end

	# Copy in clipboard the login and password
	# @args: item -> the item
	def clipboard(item)
		pid = nil

		# Security: force quit after 90s
		Thread.new do
			sleep 90
			exit
		end
		
		while true
			choice = ask(I18n.t('form.clipboard.choice')).to_s
			
			case choice
			when 'q', 'quit'
				break

			when 'l', 'login'
				Clipboard.copy(item.user)
				puts I18n.t('form.clipboard.login').green

			when 'p', 'password'
				Clipboard.copy(@mpw.get_password(item.id))
				puts I18n.t('form.clipboard.password').yellow

				Thread.new do
					sleep 30

					Clipboard.clear
				end

			when 'o', 'otp'
				Clipboard.copy(@mpw.get_otp_code(item.id))
				puts I18n.t('form.clipboard.otp', time: @mpw.get_otp_remaining_time).yellow

			when 'd', 'delete'
				break if delete(item)

			when 'u', 'update', 'e', 'edit'
				update(item)

			else
				puts "----- #{I18n.t('form.clipboard.help.name')} -----".cyan
				puts I18n.t('form.clipboard.help.login')
				puts I18n.t('form.clipboard.help.password')
				puts I18n.t('form.clipboard.help.otp_code')
				puts I18n.t('form.clipboard.help.update')
				puts I18n.t('form.clipboard.help.delete')
				next
			end
		end

		Clipboard.clear
	rescue SystemExit, Interrupt
		Clipboard.clear
	end

	# Display the wallet
	# @args: wallet -> the wallet name
	def get_wallet(wallet=nil)
		@config.is_valid?

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
					exit 2
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
		@mpw.sync(true) if @sync

		puts "#{I18n.t('form.add_key.valid')}".green
	rescue Exception => e
		puts "#{I18n.t('display.error')} #13: #{e}".red
	end

	# Add new public key
	# args: key -> the key name to delete
	def delete_key(key)
		@mpw.delete_key(key)
		@mpw.write_data
		@mpw.sync(true) if @sync

		puts "#{I18n.t('form.delete_key.valid')}".green
	rescue Exception => e
		puts "#{I18n.t('display.error')} #15: #{e}".red
	end

	def text_editor(template_name, item=nil)
		editor        = ENV['EDITOR'] || 'nano'
		options       = {}
		opts          = {}
		template_file = "#{File.expand_path('../../../templates', __FILE__)}/#{template_name}.erb"
		template      = ERB.new(IO.read(template_file))

		Dir.mktmpdir do |dir|
			tmp_file = "#{dir}/#{template_name}.yml"

			File.open(tmp_file, 'w') do |f|
				f << template.result(binding)
			end

			system("#{editor} #{tmp_file}")

			opts = YAML::load_file(tmp_file)
		end

		opts.delete_if { |k,v| v.to_s.empty? }

		opts.each do |k,v|
			options[k.to_sym] = v
		end

		return options
	end

	# Form to add a new item
	def add
		options = text_editor('add_form')	
		item    = Item.new(options)

		@mpw.add(item)
		@mpw.set_password(item.id, options[:password]) if options.has_key?(:password)
		@mpw.set_otp_key(item.id, options[:otp_key])   if options.has_key?(:otp_key)
		@mpw.write_data
		@mpw.sync(true) if @sync

		puts "#{I18n.t('form.add_item.valid')}".green
	rescue Exception => e
		puts "#{I18n.t('display.error')} #13: #{e}".red
	end

	# Update an item
	# @args: options -> the option to search
	def update(options={})
		items = @mpw.list(options)
		
		if items.length == 0
			puts "#{I18n.t('display.warning')}: #{I18n.t('warning.select')}".yellow
		else
			table(items) if items.length > 1

			item    = get_item(items)
			options = text_editor('update_form', item)

			item.update(options)
			@mpw.set_password(item.id, options[:password]) if options.has_key?(:password)
			@mpw.set_otp_key(item.id, options[:otp_key])   if options.has_key?(:otp_key)
			@mpw.write_data
			@mpw.sync(true) if @sync

			puts "#{I18n.t('form.update_item.valid')}".green
		end
	rescue Exception => e
		puts "#{I18n.t('display.error')} #14: #{e}".red
	end

	# Remove an item
	# @args: options -> the option to search
	def delete(options={})
		items = @mpw.list(options)
		
		if items.length == 0
			puts "#{I18n.t('display.warning')}: #{I18n.t('warning.select')}".yellow
		else
			table(items)

			item    = get_item(items)
			confirm = ask("#{I18n.t('form.delete_item.ask')} (y/N) ").to_s
	
			if not confirm =~ /^(y|yes|YES|Yes|Y)$/
				return false
			end
	
			item.delete
			@mpw.write_data
			@mpw.sync(true) if @sync
	
			puts "#{I18n.t('form.delete_item.valid')}".green
		end
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
