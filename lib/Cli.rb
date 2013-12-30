#!/usr/bin/ruby
# author: nishiki
# mail: nishiki@yaegashi.fr
# info: a simple script who m your passwords

require 'rubygems'
require 'highline/import'
require 'pathname'
require 'readline'
require 'i18n'

require "#{APP_ROOT}/lib/MPW.rb"

class Cli

	# Constructor
	def initialize(lang, config_file=nil)
		@m = MPW.new(config_file)
		
		if not @m.checkconfig()
			self.setup(lang)
		end

		if not self.decrypt()
			puts "#{I18n.t('cli.display.error')}: #{@m.error_msg}"
			exit 2
		end
	end

	# Create a new config file
	# @args: lang -> the software language
	def setup(lang)
		puts I18n.t('cli.form.setup.title')
		puts '--------------------'
		language    = ask(I18n.t('cli.form.setup.lang', :lang => lang)).to_s
		key         = ask(I18n.t('cli.form.setup.gpg_key')).to_s
		file_gpg    = ask(I18n.t('cli.form.setup.gpg_file', :home => Dir.home())).to_s
		timeout_pwd = ask(I18n.t('cli.form.setup.timeout')).to_s
		
		if !File.exist?("#{APP_ROOT}/i18n/#{language}.yml")
			language= 'en'
		end
		I18n.locale = language.to_sym

		if @m.setup(key, language, file_gpg, timeout_pwd)
			puts I18n.t('cli.form.setup.valid')
		else
			puts "#{I18n.t('cli.display.error')}: #{@m.error_msg}"
		end
	end

	# Request the GPG password and decrypt the file
	def decrypt()
		@passwd = ask(I18n.t('cli.display.gpg_password')) {|q| q.echo = false}
		return @m.decrypt(@passwd)
	end

	# Display the query's result
	# @args: search -> the string to search
	#        protocol -> search from a particular protocol
	def display(search, protocol=nil, group=nil, format=nil)
		result = @m.search(search, group, protocol)

		if not result.empty?
			result.each do |r|
				if format.nil? || !format
					self.displayFormat(r)
				else
					self.displayFormatAlt(r)
				end
			end
		else
			puts I18n.t('cli.display.nothing')
		end
	end

	# Display an item in the default format
	# @args: item -> an array with the item information
	def displayFormat(item)
		puts '--------------------'
		puts "Id: #{item[MPW::ID]}"
		puts "#{I18n.t('cli.display.name')}: #{item[MPW::NAME]}"
		puts "#{I18n.t('cli.display.group')}: #{item[MPW::GROUP]}"
		puts "#{I18n.t('cli.display.server')}: #{item[MPW::SERVER]}"
		puts "#{I18n.t('cli.display.protocol')}: #{item[MPW::PROTOCOL]}"
		puts "#{I18n.t('cli.display.login')}: #{item[MPW::LOGIN]}"
		puts "#{I18n.t('cli.display.password')}: #{item[MPW::PASSWORD]}"
		puts "#{I18n.t('cli.display.port')}: #{item[MPW::PORT]}"
		puts "#{I18n.t('cli.display.comment')}: #{item[MPW::COMMENT]}"
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
		puts I18n.t('cli.form.add.title')
		puts '--------------------'
		name     = ask(I18n.t('cli.form.add.name')).to_s
		group    = ask(I18n.t('cli.form.add.group')).to_s
		server   = ask(I18n.t('cli.form.add.server')).to_s
		protocol = ask(I18n.t('cli.form.add.protocol')).to_s
		login    = ask(I18n.t('cli.form.add.login')).to_s
		passwd   = ask(I18n.t('cli.form.add.password')).to_s
		port     = ask(I18n.t('cli.form.add.port')).to_s
		comment  = ask(I18n.t('cli.form.add.comment')).to_s

		if @m.add(name, group, server, protocol, login, passwd, port, comment)
			if @m.encrypt()
				puts I18n.t('cli.form.add.valid')
			else
				puts "#{I18n.t('cli.display.error')}: #{@m.error_msg}"
			end
		else
			puts "#{I18n.t('cli.display.error')}: #{@m.error_msg}"
		end
	end

	# Update an item
	# @args: id -> the item's id
	def update(id)
		row = @m.searchById(id)

		if not row.empty?
			puts I18n.t('cli.form.update.title')
			puts '--------------------'
			name     = ask(I18n.t('cli.form.update.name'    , :name => row[MPW::NAME])).to_s
			group    = ask(I18n.t('cli.form.update.group'   , :group => row[MPW::GROUP])).to_s
			server   = ask(I18n.t('cli.form.update.server'  , :server => row[MPW::SERVER])).to_s
			protocol = ask(I18n.t('cli.form.update.protocol', :protocol => row[MPW::PROTOCOL])).to_s
			login    = ask(I18n.t('cli.form.update.login'   , :login => row[MPW::LOGIN])).to_s
			passwd   = ask(I18n.t('cli.form.update.password')).to_s
			port     = ask(I18n.t('cli.form.update.port'    , :port => row[MPW::PORT])).to_s
			comment  = ask(I18n.t('cli.form.update.comment' , :comment => row[MPW::COMMENT])).to_s
				
			if @m.update(id, name, group, server, protocol, login, passwd, port, comment)
				if @m.encrypt()
					puts I18n.t('cli.form.update.valid')
				else
					puts "#{I18n.t('cli.display.error')}: #{@m.error_msg}"
				end
			else
				puts "#{I18n.t('cli.display.error')}: #{@m.error_msg}"
			end
		else
			puts I18n.t('cli.display.nothing')
		end
	end

	# Remove an item
	# @args: id -> the item's id
	#        force -> no resquest a validation
	def remove(id, force=false)
		if not force
			result = @m.searchById(id)		

			if result.length > 0
				self.displayFormat(result)

				confirm = ask("#{I18n.t('cli.form.delete.ask', :id => id)} (y/N) ").to_s
				if confirm =~ /^(y|yes|YES|Yes|Y)$/
					force = true
				end
			else
				puts I18n.t('cli.display.nothing')
			end
		end

		if force
			if @m.remove(id)
				if @m.encrypt()
					puts I18n.t('cli.form.delete.valid', :id => id)
				else
					puts "#{I18n.t('cli.display.error')}: #{@m.error_msg}"
				end
			else
				puts I18n.t('cli.form.delete.not_valid')
			end
		end
	end

	# Export the items in a CSV file
	# @args: file -> the destination file
	def export(file)
		if @m.export(file)
			puts "The export in #{file} is succesfull!"
		else
			puts "#{I18n.t('cli.display.error')}: #{@m.error_msg}"
		end

	end

	# Import items from a CSV file
	# @args: file -> the import file
	#        force -> no resquest a validation
	def import(file, force=false)
		result = @m.importPreview(file)

		if not force
			if result.is_a?(Array) && !result.empty?
				result.each do |r|
					self.displayFormat(r)
				end

				confirm = ask("#{I18n.t('cli.form.import.ask', :file => file)} (y/N) ").to_s
				if confirm =~ /^(y|yes|YES|Yes|Y)$/
					force = true
				end
			else
				puts I18n.t('cli.form.import.not_valid')
			end
		end

		if force
			if @m.import(file) && @m.encrypt()
				puts I18n.t('cli.form.import.valid')
			else
				puts "#{I18n.t('cli.display.error')}: #{@m.error_msg}"
			end
		end
	end

	# Interactive mode
	def interactive()
		group       = nil
		last_access = Time.now.to_i

		while buf = Readline.readline('<mpw> ', true)

			if @m.timeout_pwd < Time.now.to_i - last_access
				passwd_confirm = ask(I18n.t('cli.interactive.ask_password')) {|q| q.echo = false}

				if @passwd.eql?(passwd_confirm)
					last_access = Time.now.to_i
				else
					puts I18n.t('cli.interactive.bad_password')
					next
				end
			else
				last_access = Time.now.to_i
			end

			command = buf.split(' ')

			case command[0]
			when 'display', 'show', 'd', 's'
				if !command[1].nil? && !command[1].empty?
					self.display(command[1], group, command[2])
				end
			when 'add', 'a'
				add()
			when 'update', 'u'
				if !command[1].nil? && !command[1].empty?
					self.update(command[1])
				end
			when 'remove', 'delete', 'r', 'd'
				if !command[1].nil? && !command[1].empty?
					self.remove(command[1])
				end
			when 'group', 'g'
				if !command[1].nil? && !command[1].empty?
					group = command[1]
				else
					group = nil
				end
			when 'help', 'h', '?'
				puts I18n.t('cli.interactive.option.title')
				puts '--------------------'
				puts "display, show, d, s SEARCH    #{I18n.t('cli.interactive.option.show')}"
				puts "group, g                      #{I18n.t('cli.interactive.option.group')}"
				puts "add, a                        #{I18n.t('cli.interactive.option.add')}"
				puts "update, u ID                  #{I18n.t('cli.interactive.option.update')}"
				puts "remove, delete, r, d ID       #{I18n.t('cli.interactive.option.remove')}"
				puts "help, h, ?                    #{I18n.t('cli.interactive.option.help')}"
				puts "quit, exit, q                 #{I18n.t('cli.interactive.option.quit')}"
			when 'quit', 'exit', 'q'
				puts I18n.t('cli.interactive.goodbye')
				break
			else
				if !command[0].nil? && !command[0].empty?
					puts I18n.t('cli.interactive.unknown_command')
				end
			end

		end

	end
end
