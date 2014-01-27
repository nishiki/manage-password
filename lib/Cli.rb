#!/usr/bin/ruby
# author: nishiki
# mail: nishiki@yaegashi.fr
# info: a simple script who m your passwords

require 'rubygems'
require 'highline/import'
require 'pathname'
require 'readline'
require 'i18n'
require 'yaml'

require "#{APP_ROOT}/lib/MPW.rb"
require "#{APP_ROOT}/lib/MPWConfig.rb"
require "#{APP_ROOT}/lib/Sync.rb"

class Cli

	# Constructor
	# @args: lang -> the operating system language
	#        config_file -> a specify config file
	def initialize(lang, config)
		@config = config
	end

	# Close sync
	def sync_close()
		@sync.close()
	end

	# Sync the data with the server
	# @rtnr: true if the synchro is finish
	def sync()
		if !defined?(@sync)
			@sync = Sync.new()

			if !@config.sync_host.nil? && !@config.sync_port.nil?
				if !@sync.connect(@config.sync_host, @config.sync_port, @config.key, @config.sync_pwd, @config.sync_suffix)
					puts "#{I18n.t('display.error')}: #{@sync.error_msg}"
				end
			end
		end
		
		begin
			if @sync.enable
				if !@mpw.sync(@sync.get(@passwd), @config.last_update)
					puts "#{I18n.t('display.error')}: #{@mpw.error_msg}"
				elsif !@sync.update(File.open(@config.file_gpg).read)
					puts "#{I18n.t('display.error')}: #{@sync.error_msg}"
				elsif !@config.set_last_update()
					puts "#{I18n.t('display.error')}: #{@config.error_msg}"
				else
					return true
				end
			end
		rescue Exception => e
			puts "#{I18n.t('display.error')}: #{e}"
		end

		return false
	end

	# Create a new config file
	# @args: lang -> the software language
	def setup(lang)
		puts I18n.t('form.setup.title')
		puts '--------------------'
		language    = ask(I18n.t('form.setup.lang', :lang => lang)).to_s
		key         = ask(I18n.t('form.setup.gpg_key')).to_s
		file_gpg    = ask(I18n.t('form.setup.gpg_file', :home => Dir.home())).to_s
		timeout_pwd = ask(I18n.t('form.setup.timeout')).to_s
		sync_host   = ask(I18n.t('form.setup.sync_host')).to_s
		sync_port   = ask(I18n.t('form.setup.sync_port')).to_s
		sync_pwd    = ask(I18n.t('form.setup.sync_pwd')).to_s
		sync_suffix = ask(I18n.t('form.setup.sync_suffix')).to_s
		
		if !File.exist?("#{APP_ROOT}/i18n/#{language}.yml")
			language= 'en'
		end
		I18n.locale = language.to_sym

		sync_host.empty?   ? (sync_host = nil)   : (sync_host   = sync_host)
		sync_port.empty?   ? (sync_port = nil)   : (sync_port   = sync_port.to_i)
		sync_pwd.empty?    ? (sync_pwd = nil)    : (sync_pwd    = sync_pwd)
		sync_suffix.empty? ? (sync_suffix = nil) : (sync_suffix = sync_suffix)

		if @config.setup(key, language, file_gpg, timeout_pwd, sync_host, sync_port, sync_pwd, sync_suffix)
			puts I18n.t('form.setup.valid')
		else
			puts "#{I18n.t('display.error')}: #{@config.error_msg}"
		end

		if not @config.checkconfig()
			puts "#{I18n.t('display.error')}: #{@config.error_msg}"
			exit 2
		end
	end

	# Request the GPG password and decrypt the file
	def decrypt()
		if !defined?(@mpw)
			@mpw = MPW.new(@config.file_gpg, @config.key)
		end

		@passwd = ask(I18n.t('display.gpg_password')) {|q| q.echo = false}
		if !@mpw.decrypt(@passwd)
			puts "#{I18n.t('display.error')}: #{@mpw.error_msg}"
			exit 2
		end
	end

	# Display the query's result
	# @args: search -> the string to search
	#        protocol -> search from a particular protocol
	def display(search, protocol=nil, group=nil, format=nil)
		result = @mpw.search(search, group, protocol)

		if not result.empty?
			result.each do |r|
				if format.nil? || !format
					displayFormat(r)
				else
					displayFormatAlt(r)
				end
			end
		else
			puts I18n.t('display.nothing')
		end
	end

	# Display an item in the default format
	# @args: item -> an array with the item information
	def displayFormat(item)
		puts '--------------------'
		puts "Id: #{item[MPW::ID]}"
		puts "#{I18n.t('display.name')}: #{item[MPW::NAME]}"
		puts "#{I18n.t('display.group')}: #{item[MPW::GROUP]}"
		puts "#{I18n.t('display.server')}: #{item[MPW::SERVER]}"
		puts "#{I18n.t('display.protocol')}: #{item[MPW::PROTOCOL]}"
		puts "#{I18n.t('display.login')}: #{item[MPW::LOGIN]}"
		puts "#{I18n.t('display.password')}: #{item[MPW::PASSWORD]}"
		puts "#{I18n.t('display.port')}: #{item[MPW::PORT]}"
		puts "#{I18n.t('display.comment')}: #{item[MPW::COMMENT]}"
	end

	# Display an item in the alternative format
	# @args: item -> an array with the item information
	def displayFormatAlt(item)
		item[MPW::PORT].nil? ? (port = '') : (port = ":#{item[MPW::PORT]}")

		if item[MPW::PASSWORD].nil? || item[MPW::PASSWORD].empty?
			if item[MPW::LOGIN].include('@')
				puts "# #{item[MPW::ID]} #{item[MPW::PROTOCOL]}://#{item[MPW::LOGIN]}@#{item[MPW::SERVER]}#{port}"
			else
				puts "# #{item[MPW::ID]} #{item[MPW::PROTOCOL]}://{#{item[MPW::LOGIN]}}@#{item[MPW::SERVER]}#{port}"
			end
		else
			puts "# #{item[MPW::ID]} #{item[MPW::PROTOCOL]}://{#{item[MPW::LOGIN]}:#{item[MPW::PASSWORD]}}@#{item[MPW::SERVER]}#{port}"
		end
	end

	# Form to add a new item
	def add()
		row = Array.new()
		puts I18n.t('form.add.title')
		puts '--------------------'
		name     = ask(I18n.t('form.add.name')).to_s
		group    = ask(I18n.t('form.add.group')).to_s
		server   = ask(I18n.t('form.add.server')).to_s
		protocol = ask(I18n.t('form.add.protocol')).to_s
		login    = ask(I18n.t('form.add.login')).to_s
		passwd   = ask(I18n.t('form.add.password')).to_s
		port     = ask(I18n.t('form.add.port')).to_s
		comment  = ask(I18n.t('form.add.comment')).to_s

		if @mpw.update(name, group, server, protocol, login, passwd, port, comment)
			if @mpw.encrypt()
				sync()
				puts I18n.t('form.add.valid')
			else
				puts "#{I18n.t('display.error')}: #{@mpw.error_msg}"
			end
		else
			puts "#{I18n.t('display.error')}: #{@mpw.error_msg}"
		end
	end

	# Update an item
	# @args: id -> the item's id
	def update(id)
		row = @mpw.search_by_id(id)

		if not row.empty?
			puts I18n.t('form.update.title')
			puts '--------------------'
			name     = ask(I18n.t('form.update.name'    , :name => row[MPW::NAME])).to_s
			group    = ask(I18n.t('form.update.group'   , :group => row[MPW::GROUP])).to_s
			server   = ask(I18n.t('form.update.server'  , :server => row[MPW::SERVER])).to_s
			protocol = ask(I18n.t('form.update.protocol', :protocol => row[MPW::PROTOCOL])).to_s
			login    = ask(I18n.t('form.update.login'   , :login => row[MPW::LOGIN])).to_s
			passwd   = ask(I18n.t('form.update.password')).to_s
			port     = ask(I18n.t('form.update.port'    , :port => row[MPW::PORT])).to_s
			comment  = ask(I18n.t('form.update.comment' , :comment => row[MPW::COMMENT])).to_s
				
			if @mpw.update(name, group, server, protocol, login, passwd, port, comment, id)
				if @mpw.encrypt()
					sync()
					puts I18n.t('form.update.valid')
				else
					puts "#{I18n.t('display.error')}: #{@mpw.error_msg}"
				end
			else
				puts "#{I18n.t('display.error')}: #{@mpw.error_msg}"
			end
		else
			puts I18n.t('display.nothing')
		end
	end

	# Remove an item
	# @args: id -> the item's id
	#        force -> no resquest a validation
	def remove(id, force=false)
		if not force
			result = @mpw.search_by_id(id)

			if result.length > 0
				displayFormat(result)

				confirm = ask("#{I18n.t('form.delete.ask', :id => id)} (y/N) ").to_s
				if confirm =~ /^(y|yes|YES|Yes|Y)$/
					force = true
				end
			else
				puts I18n.t('display.nothing')
			end
		end

		if force
			if @mpw.remove(id)
				if @mpw.encrypt()
					sync()
					puts I18n.t('form.delete.valid', :id => id)
				else
					puts "#{I18n.t('display.error')}: #{@mpw.error_msg}"
				end
			else
				puts I18n.t('form.delete.not_valid')
			end
		end
	end

	# Export the items in a CSV file
	# @args: file -> the destination file
	def export(file)
		if @mpw.export(file)
			puts "The export in #{file} is succesfull!"
		else
			puts "#{I18n.t('display.error')}: #{@mpw.error_msg}"
		end

	end

	# Import items from a CSV file
	# @args: file -> the import file
	#        force -> no resquest a validation
	def import(file, force=false)
		result = @mpw.import_preview(file)

		if not force
			if result.is_a?(Array) && !result.empty?
				result.each do |r|
					displayFormat(r)
				end

				confirm = ask("#{I18n.t('form.import.ask', :file => file)} (y/N) ").to_s
				if confirm =~ /^(y|yes|YES|Yes|Y)$/
					force = true
				end
			else
				puts I18n.t('form.import.not_valid')
			end
		end

		if force
			if @mpw.import(file) && @mpw.encrypt()
				sync()
				puts I18n.t('form.import.valid')
			else
				puts "#{I18n.t('display.error')}: #{@mpw.error_msg}"
			end
		end
	end

	# Interactive mode
	def interactive()
		group       = nil
		last_access = Time.now.to_i

		while buf = Readline.readline('<mpw> ', true)

			if @config.timeout_pwd < Time.now.to_i - last_access
				passwd_confirm = ask(I18n.t('interactive.ask_password')) {|q| q.echo = false}

				if @passwd.eql?(passwd_confirm)
					last_access = Time.now.to_i
				else
					puts I18n.t('interactive.bad_password')
					next
				end
			else
				last_access = Time.now.to_i
			end

			command = buf.split(' ')

			case command[0]
			when 'display', 'show', 'd', 's'
				if !command[1].nil? && !command[1].empty?
					display(command[1], group, command[2])
				end
			when 'add', 'a'
				add()
			when 'update', 'u'
				if !command[1].nil? && !command[1].empty?
					update(command[1])
				end
			when 'remove', 'delete', 'r', 'd'
				if !command[1].nil? && !command[1].empty?
					remove(command[1])
				end
			when 'group', 'g'
				if !command[1].nil? && !command[1].empty?
					group = command[1]
				else
					group = nil
				end
			when 'help', 'h', '?'
				puts I18n.t('interactive.option.title')
				puts '--------------------'
				puts "display, show, d, s SEARCH    #{I18n.t('interactive.option.show')}"
				puts "group, g                      #{I18n.t('interactive.option.group')}"
				puts "add, a                        #{I18n.t('interactive.option.add')}"
				puts "update, u ID                  #{I18n.t('interactive.option.update')}"
				puts "remove, delete, r, d ID       #{I18n.t('interactive.option.remove')}"
				puts "help, h, ?                    #{I18n.t('interactive.option.help')}"
				puts "quit, exit, q                 #{I18n.t('interactive.option.quit')}"
			when 'quit', 'exit', 'q'
				puts I18n.t('interactive.goodbye')
				break
			else
				if !command[0].nil? && !command[0].empty?
					puts I18n.t('interactive.unknown_command')
				end
			end

		end

	end
end
