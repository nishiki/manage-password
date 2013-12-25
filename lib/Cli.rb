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
	def initialize(lang)
		@m = MPW.new()
		
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
		puts "# #{I18n.t('cli.form.setup.title')}"
		puts "# --------------------"
		language    = ask(I18n.t('cli.form.setup.lang', :lang => lang))
		key         = ask(I18n.t('cli.form.setup.gpg_key'))
		file_gpg    = ask(I18n.t('cli.form.setup.gpg_file', :home => Dir.home()))
		timeout_pwd = ask(I18n.t('cli.form.setup.timeout'))
		
		if !File.exist?("#{APP_ROOT}/i18n/#{language}.yml")
			language= 'en_US'
		end
		I18n.load_path = Dir["#{APP_ROOT}/i18n/#{language}.yml"]
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
		puts "# --------------------"
		puts "# Id: #{item[MPW::ID]}"
		puts "# #{I18n.t('cli.display.name')}: #{item[MPW::NAME]}"
		puts "# #{I18n.t('cli.display.group')}: #{item[MPW::GROUP]}"
		puts "# #{I18n.t('cli.display.server')}: #{item[MPW::SERVER]}"
		puts "# #{I18n.t('cli.display.protocol')}: #{item[MPW::PROTOCOL]}"
		puts "# #{I18n.t('cli.display.login')}: #{item[MPW::LOGIN]}"
		puts "# #{I18n.t('cli.display.password')}: #{item[MPW::PASSWORD]}"
		puts "# #{I18n.t('cli.display.port')}: #{item[MPW::PORT]}"
		puts "# #{I18n.t('cli.display.comment')}: #{item[MPW::COMMENT]}"
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
		puts "# #{I18n.t('cli.form.add.title')}"
		puts "# --------------------"
		name     = ask(I18n.t('cli.form.add.name'))
		group    = ask(I18n.t('cli.form.add.group'))
		server   = ask(I18n.t('cli.form.add.server'))
		protocol = ask(I18n.t('cli.form.add.protocol'))
		login    = ask(I18n.t('cli.form.add.login'))
		passwd   = ask(I18n.t('cli.form.add.password'))
		port     = ask(I18n.t('cli.form.add.port'))
		comment  = ask(I18n.t('cli.form.add.comment'))

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
			puts "# #{I18n.t('cli.form.update.title')}"
			puts "# --------------------"
			name     = ask(I18n.t('cli.form.update.name'    , :name => row[MPW::NAME]))
			group    = ask(I18n.t('cli.form.update.group'   , :group => row[MPW::GROUP]))
			server   = ask(I18n.t('cli.form.update.server'  , :server => row[MPW::SERVER]))
			protocol = ask(I18n.t('cli.form.update.protocol', :protocol => row[MPW::PROTOCOL]))
			login    = ask(I18n.t('cli.form.update.login'   , :login => row[MPW::LOGIN]))
			passwd   = ask(I18n.t('cli.form.update.password'))
			port     = ask(I18n.t('cli.form.update.port'    , :port => row[MPW::PORT]))
			comment  = ask(I18n.t('cli.form.update.comment' , :comment => row[MPW::COMMENT]))
				
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

				confirm = ask("#{I18n.t('cli.form.delete.ask', :id => id)} (y/N) ")
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

				confirm = ask("#{I18n.t('cli.form.import.ask', :file => file)} (y/N) ")
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
				puts '# Help'
				puts '# --------------------'
				puts '# Display an item:'
				puts '#	display SEARCH'
				puts '#	show SEARCH'
				puts '#	s SEARCH'
				puts '#	d SEARCH'
				puts '# Add an new item:'
				puts '#	add'
				puts '#	a'
				puts '# Update an item:'
				puts '#	update ID'
				puts '#	u ID'
				puts '# Remove an item:'
				puts '#	remove ID'
				puts '#	delete ID'
				puts '#	r ID'
				puts '#	d ID'
				puts '# Quit the program:'
				puts '#	quit'
				puts '#	exit'
				puts '#	q'
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
