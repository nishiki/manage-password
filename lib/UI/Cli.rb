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

require "#{APP_ROOT}/lib/MPW"

class Cli

	# Constructor
	# @args: lang -> the operating system language
	#        config_file -> a specify config file
	def initialize(config)
		@config = config
	end

	# Sync the data with the server
	# @rtnr: true if the synchro is finish
	def sync
		if not defined?(@sync)
			case @config.sync_type
			when 'mpw'
				require "#{APP_ROOT}/lib/Sync/MPWSync"
				@sync = MPW::Sync::MPWSync.new
			when 'sftp', 'scp', 'ssh'
				require "#{APP_ROOT}/lib/Sync/SSH"
				@sync = MPW::Sync::SSH.new
			when 'ftp'
				require "#{APP_ROOT}/lib/Sync/FTP"
				@sync = MPW::Sync::FTP.new
			else
				return false
			end
		end
		
		if  not @config.sync_host.nil? and not @config.sync_port.nil?
			if not @sync.connect(@config.sync_host, @config.sync_user, @config.sync_pwd, @config.sync_path, @config.sync_port)
				puts "#{I18n.t('display.error')} #1: #{@sync.error_msg}"
			end
		end

		if @sync.enable
			if not @mpw.sync(@sync.get(@passwd), @config.last_update)
				puts "#{I18n.t('display.error')} #2: #{@mpw.error_msg}"  if !@mpw.error_msg.nil?
				puts "#{I18n.t('display.error')} #3: #{@sync.error_msg}" if !@sync.error_msg.nil?
			elsif not @sync.update(File.open(@config.file_gpg).read)
				puts "#{I18n.t('display.error')} #4: #{@sync.error_msg}"
			elsif not @config.set_last_update
				puts "#{I18n.t('display.error')} #5: #{@config.error_msg}"
			elsif not @mpw.encrypt
				puts "#{I18n.t('display.error')} #6: #{@mpw.error_msg}"
			else
				return true
			end
		end
	rescue Exception => e
		puts "#{I18n.t('display.error')} #7: #{e}"
		puts @sync.error_msg   if @sync.error_msg.nil?
		puts @config.error_msg if @config.error_msg.nil?
		puts @mpw.error_msg    if @mpw.error_msg.nil?
	else
		return false
	end

	# Create a new config file
	# @args: lang -> the software language
	def setup(lang)
		puts I18n.t('form.setup.title')
		puts '--------------------'
		language    = ask(I18n.t('form.setup.lang', lang: lang)).to_s
		key         = ask(I18n.t('form.setup.gpg_key')).to_s
		share_keys  = ask(I18n.t('form.setup.share_gpg_keys')).to_s
		file_gpg    = ask(I18n.t('form.setup.gpg_file', home: @conf.dir_home)).to_s
		timeout_pwd = ask(I18n.t('form.setup.timeout')).to_s
		sync_type   = ask(I18n.t('form.setup.sync_type')).to_s

		if ['ssh', 'ftp', 'mpw'].include?(sync_type)
			sync_host   = ask(I18n.t('form.setup.sync_host')).to_s
			sync_port   = ask(I18n.t('form.setup.sync_port')).to_s
			sync_user   = ask(I18n.t('form.setup.sync_user')).to_s
			sync_pwd    = ask(I18n.t('form.setup.sync_pwd')).to_s
			sync_path   = ask(I18n.t('form.setup.sync_path')).to_s
		end
		
		if language.nil? or language.empty?
			language = lang
		end
		I18n.locale = language.to_sym

		sync_type = sync_type.nil? or sync_type.empty? ? nil : sync_type
		sync_host = sync_host.nil? or sync_host.empty? ? nil : sync_host
		sync_port = sync_port.nil? or sync_port.empty? ? nil : sync_port.to_i
		sync_user = sync_user.nil? or sync_user.empty? ? nil : sync_user
		sync_pwd  = sync_pwd.nil?  or sync_pwd.empty?  ? nil : sync_pwd
		sync_path = sync_path.nil? or sync_path.empty? ? nil : sync_path

		if @config.setup(key, share_keys, language, file_gpg, timeout_pwd, sync_type, sync_host, sync_port, sync_user, sync_pwd, sync_path)
			puts I18n.t('form.setup.valid')
		else
			puts "#{I18n.t('display.error')} #8: #{@config.error_msg}"
			exit 2
		end

		if not @config.checkconfig
			puts "#{I18n.t('display.error')} #9: #{@config.error_msg}"
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
			puts I18n.t('form.setup_gpg_key.valid')
		else
			puts "#{I18n.t('display.error')} #10: #{@config.error_msg}"
			exit 2
		end
	end

	# Request the GPG password and decrypt the file
	def decrypt
		if not defined?(@mpw)
			@mpw = MPW::MPW.new(@config.file_gpg, @config.key, @config.share_keys)
		end

		@passwd = ask(I18n.t('display.gpg_password')) {|q| q.echo = false}
		if not @mpw.decrypt(@passwd)
			puts "#{I18n.t('display.error')} #11: #{@mpw.error_msg}"
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
		puts "Id: #{item[:id]}"
		puts "#{I18n.t('display.name')}: #{item[:name]}"
		puts "#{I18n.t('display.group')}: #{item[:group]}"
		puts "#{I18n.t('display.server')}: #{item[:host]}"
		puts "#{I18n.t('display.protocol')}: #{item[:protocol]}"
		puts "#{I18n.t('display.login')}: #{item[:login]}"
		puts "#{I18n.t('display.password')}: #{item[:password]}"
		puts "#{I18n.t('display.port')}: #{item[:port]}"
		puts "#{I18n.t('display.comment')}: #{item[:comment]}"
	end

	# Display an item in the alternative format
	# @args: item -> an array with the item information
	def displayFormatAlt(item)
		port = item[:port].nil? ? '' : ":#{item[:port]}"

		if item[:password].nil? or item[:password].empty?
			if item[:login].include('@')
				puts "# #{item[:id]} #{item[:protocol]}://#{item[:login]}@#{item[:host]}#{port}"
			else
				puts "# #{item[:id]} #{item[:protocol]}://{#{item[:login]}}@#{item[:host]}#{port}"
			end
		else
			puts "# #{item[:id]} #{item[:protocol]}://{#{item[:login]}:#{item[:password]}}@#{item[:host]}#{port}"
		end
	end

	# Form to add a new item
	def add
		row = []
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
			if @mpw.encrypt
				sync
				puts I18n.t('form.add.valid')
			else
				puts "#{I18n.t('display.error')} #12: #{@mpw.error_msg}"
			end
		else
			puts "#{I18n.t('display.error')} #13: #{@mpw.error_msg}"
		end
	end

	# Update an item
	# @args: id -> the item's id
	def update(id)
		row = @mpw.search_by_id(id)

		if not row.empty?
			puts I18n.t('form.update.title')
			puts '--------------------'
			name     = ask(I18n.t('form.update.name'    , name:     row[:name])).to_s
			group    = ask(I18n.t('form.update.group'   , group:    row[:group])).to_s
			server   = ask(I18n.t('form.update.server'  , server:   row[:host])).to_s
			protocol = ask(I18n.t('form.update.protocol', protocol: row[:protocol])).to_s
			login    = ask(I18n.t('form.update.login'   , login:    row[:login])).to_s
			passwd   = ask(I18n.t('form.update.password')).to_s
			port     = ask(I18n.t('form.update.port'    , port:     row[:port])).to_s
			comment  = ask(I18n.t('form.update.comment' , comment:  row[:comment])).to_s
				
			if @mpw.update(name, group, server, protocol, login, passwd, port, comment, id)
				if @mpw.encrypt
					sync
					puts I18n.t('form.update.valid')
				else
					puts "#{I18n.t('display.error')} #14: #{@mpw.error_msg}"
				end
			else
				puts "#{I18n.t('display.error')} #15: #{@mpw.error_msg}"
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

				confirm = ask("#{I18n.t('form.delete.ask', id: id)} (y/N) ").to_s
				if confirm =~ /^(y|yes|YES|Yes|Y)$/
					force = true
				end
			else
				puts I18n.t('display.nothing')
			end
		end

		if force
			if @mpw.remove(id)
				if @mpw.encrypt
					sync
					puts I18n.t('form.delete.valid', id: id)
				else
					puts "#{I18n.t('display.error')} #16: #{@mpw.error_msg}"
				end
			else
				puts I18n.t('form.delete.not_valid')
			end
		end
	end

	# Export the items in a CSV file
	# @args: file -> the destination file
	def export(file, type)
		if @mpw.export(file, type)
			puts "The export in #{file} is succesfull!"
		else
			puts "#{I18n.t('display.error')} #17: #{@mpw.error_msg}"
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

				confirm = ask("#{I18n.t('form.import.ask', file: file)} (y/N) ").to_s
				if confirm =~ /^(y|yes|YES|Yes|Y)$/
					force = true
				end
			else
				puts I18n.t('form.import.not_valid')
			end
		end

		if force
			if @mpw.import(file) and @mpw.encrypt
				sync
				puts I18n.t('form.import.valid')
			else
				puts "#{I18n.t('display.error')} #18: #{@mpw.error_msg}"
			end
		end
	end

	# Interactive mode
	def interactive
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
				if not command[1].nil? and not command[1].empty?
					display(command[1], group, command[2])
				end
			when 'add', 'a'
				add
			when 'update', 'u'
				if not command[1].nil? and not command[1].empty?
					update(command[1])
				end
			when 'remove', 'delete', 'r', 'd'
				if not command[1].nil? and not command[1].empty?
					remove(command[1])
				end
			when 'group', 'g'
				if not command[1].nil? and not command[1].empty?
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
				if not command[0].nil? and not command[0].empty?
					puts I18n.t('interactive.unknown_command')
				end
			end

		end

	end
end
