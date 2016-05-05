#!/usr/bin/ruby
# author: nishiki
# mail: nishiki@yaegashi.fr

require 'readline'
require 'i18n'
require 'colorize'
require 'highline/import'

#TODO
require "#{APP_ROOT}/../lib/mpw/item.rb"
require "#{APP_ROOT}/../lib/mpw/mpw.rb"

class Cli

	# Constructor
	# @args: lang -> the operating system language
	#        config_file -> a specify config file
	# TODO
	def initialize(config)
		@config = config
		@wallet_file = "#{@config.wallet_dir}/test.mpw"
	end

	# Create a new config file
	# @args: lang -> the software language
	def setup(lang)
		puts I18n.t('form.setup.title')
		puts '--------------------'
		language   = ask(I18n.t('form.setup.lang', lang: lang)).to_s
		key        = ask(I18n.t('form.setup.gpg_key')).to_s
		wallet_dir = ask(I18n.t('form.setup.wallet_dir')).to_s

		if language.nil? or language.empty?
			language = lang
		end
		I18n.locale = language.to_sym

		if @config.setup(key, lang, wallet_dir)
			puts "#{I18n.t('form.setup.valid')}".green
		else
			puts "#{I18n.t('display.error')} #8: #{@config.error_msg}".red
			exit 2
		end

		if not @config.checkconfig
			puts "#{I18n.t('display.error')} #9: #{@config.error_msg}".red
			exit 2
		end
	end
	
	# Setup a new GPG key
	def setup_gpg_key
		puts I18n.t('form.setup_gpg_key.title')
		puts '--------------------'
		ask      = ask(I18n.t('form.setup_gpg_key.ask')).to_s
		
		if not ['Y', 'y', 'O', 'o'].include?(ask)
			puts I18n.t('form.setup_gpg_key.no_create')
			exit 2
		end

		name     = ask(I18n.t('form.setup_gpg_key.name')).to_s
		password = ask(I18n.t('form.setup_gpg_key.password')) {|q| q.echo = false}
		confirm  = ask(I18n.t('form.setup_gpg_key.confirm_password')) {|q| q.echo = false}

		if password != confirm 
			puts I18n.t('form.setup_gpg_key.error_password')
			exit 2
		end

		length   = ask(I18n.t('form.setup_gpg_key.length')).to_s
		expire   = ask(I18n.t('form.setup_gpg_key.expire')).to_s
		password = password.to_s

		length = length.nil? or length.empty? ? 2048 : length.to_i
		expire = expire.nil? or expire.empty? ? 0    : expire.to_i

		puts I18n.t('form.setup_gpg_key.wait')
		
		if @config.setup_gpg_key(password, name, length, expire)
			puts "#{I18n.t('form.setup_gpg_key.valid')}".green
		else
			puts "#{I18n.t('display.error')} #10: #{@config.error_msg}".red
			exit 2
		end
	end

	
	# Request the GPG password and decrypt the file
	def decrypt
		if not defined?(@mpw)
			@password = ask(I18n.t('display.gpg_password')) {|q| q.echo = false}
			@mpw = MPW::MPW.new(@config.key, @wallet_file, @password)
		end

		@mpw.read_data
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

	# Form to add a new item
	def add
		options = {}

		puts I18n.t('form.add.title')
		puts '--------------------'
		options[:name]     = ask(I18n.t('form.add.name')).to_s
		options[:group]    = ask(I18n.t('form.add.group')).to_s
		options[:host]     = ask(I18n.t('form.add.server')).to_s
		options[:protocol] = ask(I18n.t('form.add.protocol')).to_s
		options[:user]     = ask(I18n.t('form.add.login')).to_s
		password           = ask(I18n.t('form.add.password')).to_s
		options[:port]     = ask(I18n.t('form.add.port')).to_s
		options[:comment]  = ask(I18n.t('form.add.comment')).to_s

		item = MPW::Item.new(options)

		@mpw.add(item)
		@mpw.set_password(item.id, password)
		@mpw.write_data

		puts "#{I18n.t('form.add.valid')}".green
	end

	# Update an item
	# @args: id -> the item's id
	def update(id)
		item = @mpw.search_by_id(id)

		if not item.nil?
			options = {}

			puts I18n.t('form.update.title')
			puts '--------------------'
			options[:name]     = ask(I18n.t('form.update.name'    , name:     item.name)).to_s
			options[:group]    = ask(I18n.t('form.update.group'   , group:    item.group)).to_s
			options[:host]     = ask(I18n.t('form.update.server'  , server:   item.host)).to_s
			options[:protocol] = ask(I18n.t('form.update.protocol', protocol: item.protocol)).to_s
			options[:user]     = ask(I18n.t('form.update.login'   , login:    item.user)).to_s
			password           = ask(I18n.t('form.update.password')).to_s
			options[:port]     = ask(I18n.t('form.update.port'    , port:     item.port)).to_s
			options[:comment]  = ask(I18n.t('form.update.comment' , comment:  item.comment)).to_s

			options.delete_if { |k,v| v.empty? }
				
			item.update(options)
			@mpw.encrypt
			@mpw.write_data

			puts "#{I18n.t('form.update.valid')}".green
		else
			puts I18n.t('display.nothing')
		end
	end

	# Remove an item
	# @args: id -> the item's id
	#        force -> no resquest a validation
	def delete(id, force=false)
		if not force
			item = @mpw.search_by_id(id)

			if not item.nil?
				display_item(item)

				confirm = ask("#{I18n.t('form.delete.ask', id: id)} (y/N) ").to_s
				if confirm =~ /^(y|yes|YES|Yes|Y)$/
					force = true
				end
			else
				puts I18n.t('display.nothing')
			end
		end

		if force
			item.delete

			if @mpw.encrypt
				sync
				puts "#{I18n.t('form.delete.valid', id: id)}".green
			else
				puts "#{I18n.t('display.error')} #16: #{@mpw.error_msg}".red
			end
		end
	end

	# Export the items in a CSV file
	# @args: file -> the destination file
	def export(file)
		@mpw.export(file)

		puts "#{I18n.t('export.valid', file)}".green
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
