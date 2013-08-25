#!/usr/bin/ruby
# author: nishiki
# mail: nishiki@yaegashi.fr
# info: a simple script who manage your passwords

require 'rubygems'
require 'gpgme'
require 'csv'
require 'yaml'

class MPW
	
	ID       = 0
	PROTOCOL = 1
	SERVER   = 2
	LOGIN    = 3
	PASSWORD = 4
	PORT     = 5
	COMMENT  = 6

	attr_accessor :error
	attr_accessor :error_msg

	# Constructor
	def initialize()
		@file_config = "#{Dir.home()}/.mpw.cfg"
		@error_mgs   = nil
		@error       = 0
	end

	# Create a new config file
	# @args: key -> the gpg key to encrypt
	#        file_gpg -> the file who is encrypted
	#        file_pwd -> the file who stock the password
	#        timeout_pwd -> time to save the password 
	# @rtrn: true if le config file is create
	def setup(key, file_gpg, file_pwd, timeout_pwd)

		if not key =~ /[a-zA-Z0-9.-_]+\@[a-zA-Z0-9]+\.[a-zA-Z]+/
			@error_msg = "The key string isn't in good format!"
			@error     = 1
			return false
		end
		
		if file_gpg.empty?
			file_gpg = "#{Dir.home()}/.mpw.gpg"
		end

		if file_pwd.empty?
			file_pwd = "#{Dir.home()}/.mpw.pwd"
		end

		timeout_pwd.empty? ? (timeout_pwd = 300) : (timeout_pwd = timeout_pwd.to_i)

		config = {'config' => {'key'         => key,
		                       'file_gpg'    => file_gpg,
		                       'timeout_pwd' => timeout_pwd,
		                       'file_pwd'    => file_pwd}}

		begin
			File.open(@file_config, 'w') do |file|
				file << config.to_yaml
			end
		rescue
			@error_msg = "Can't write the config file!"
			@error     = 2
			return false
		end

		return true
	end

	# Check the config file
	# @rtrn: true if the config file is correct
	def checkconfig()
		begin
			config = YAML::load_file(@file_config)
			@key         = config['config']['key']
			@file_gpg    = config['config']['file_gpg']
			@file_pwd    = config['config']['file_pwd']
			@timeout_pwd = config['config']['timeout_pwd'].to_i

			if @key.empty? || @file_gpg.empty? || @file_pwd.empty? 
				return false
			end

		rescue
			@error_msg = "Checkconfig failed!"
			@error     = 3
			return false
		end

		return true
	end

	# Decrypt a gpg file
	# @args: password -> the GPG key password
	# @rtrn: true if data has been decrypted
	def decrypt(passwd=nil)
		@data = ""

		begin
			if passwd.nil? || passwd.empty?
				passwd = IO.read(@file_pwd)

			elsif !passwd.nil? && !passwd.empty?
				file_pwd = File.new(@file_pwd, 'w')
				File.chmod(0600, @file_pwd)
				file_pwd << passwd
				file_pwd.close
			end
		rescue
			return false
		end

		begin
			if File.exist?(@file_gpg)
				crypto = GPGME::Crypto.new(:armor => true)
				@data = crypto.decrypt(IO.read(@file_gpg), :password => passwd).read
			end
			return true
		rescue
			if !@file_pwd.nil? && File.exist?(@file_pwd)
				File.delete(@file_pwd)
			end
			
			@error_msg = "Can't decrypt file!"
			@error     = 4
			return false
		end
	end

	# Check if a password it saved
	# @rtrn: true if a password exist in the password file
	def checkFilePassword()
		if !@file_pwd.nil? && File.exist?(@file_pwd) && File.stat(@file_pwd).mtime.to_i + @timeout_pwd < Time.now.to_i
			File.delete(@file_pwd)
			return false
		elsif !@file_pwd.nil? && File.exist?(@file_pwd) 
			return true
		else
			return false
		end
	end

	# Encrypt a file
	# @rtrn: true if the file has been encrypted
	def encrypt()
		begin
			crypto = GPGME::Crypto.new(:armor => true)
			file_gpg = File.open(@file_gpg, 'w+')
			crypto.encrypt(@data, :recipients => @key, :output => file_gpg)
			file_gpg.close

			return true
		rescue
			@error_msg = "Can't encrypt the GPG file!"
			@error     = 5
			return false
		end
	end
	
	# Search in some csv data
	# @args: search -> the string to search
	#        type -> the connection type (ssh, web, other)
	# @rtrn: a list with the resultat of the search
	def search(search, protocol=nil)
		result = Array.new()
		@data.lines do |line|
			row = line.parse_csv
			if line =~ /^.*#{search}.*$/ || protocol.eql?('all')
				if protocol.nil? || protocol.eql?(row[PROTOCOL]) || protocol.eql?('all')
					result.push(row)
				end
			end
		end

		return result
	end

	# Search in some csv data
	# @args: id -> the id item
	# @rtrn: a row with the resultat of the search
	def searchById(id)
		@data.lines do |line|
			row = line.parse_csv
			if !id.nil? && id.eql?(row[ID])
				return row
			end
		end

		return Array.new()
	end

	# Add a new item
	# @args: server -> the ip or server
	#        protocol -> the protocol
	#        login -> the login
	#        passwd -> the password
	#        port -> the port
	#        comment -> a comment
	def add(server, protocol=nil, login=nil, passwd=nil, port=nil, comment=nil)
		row = Array.new()

		row[ID]       = Time.now.to_i.to_s(16)
		row[SERVER]   = server
		row[PROTOCOL] = protocol
		row[LOGIN]    = login
		row[PASSWORD] = passwd
		row[PORT]     = port
		row[COMMENT]  = comment

		@data << "#{row.join(',')}\n"
	end
	
	# Update an item
	# @args: id -> the item's identifiant
	#        server -> the ip or server
	#        protocol -> the protocol
	#        login -> the login
	#        passwd -> the password
	#        port -> the port
	#        comment -> a comment
	# @rtrn: true if the item has been updated
	def update(id, server=nil, protocol=nil, login=nil, passwd=nil, port=nil, comment=nil)
		updated  = false
		data_tmp = ''

		@data.lines do |line|
			row = line.parse_csv
			if id.eql?(row[ID])
				row_update = Array.new()

				row_update[ID] = row[ID]
				server.empty?   ? (row_update[SERVER]   = row[SERVER])   : (row_update[SERVER]   = server)
				protocol.empty? ? (row_update[PROTOCOL] = row[PROTOCOL]) : (row_update[PROTOCOL] = protocol)
				login.empty?    ? (row_update[LOGIN]    = row[LOGIN])    : (row_update[LOGIN]    = login)
				passwd.empty?   ? (row_update[PASSWORD] = row[PASSWORD]) : (row_update[PASSWORD] = passwd)
				port.empty?     ? (row_update[PORT]     = row[PORT])     : (row_update[PORT]     = port)
				comment.empty?  ? (row_update[COMMENT]  = row[COMMENT])  : (row_update[COMMENT]  = comment)
				
				data_tmp << "#{row_update.join(',')}\n"
				updated = true
			else
				data_tmp << line
			end
		end
		@data = data_tmp

		if not updated
			@error_msg = "Can't update the item: #{id}!"
			@error     = 6
		end

		return updated
	end
	
	# Remove an item 
	# @args: id -> the item's identifiant
	# @rtrn: true if the item has been deleted
	def remove(id)
		removed  = false
		data_tmp = ""

		@data.lines do |line|
			row = line.parse_csv
			if id.eql?(row[ID])
				removed = true
			else
				data_tmp << line
			end
		end
		@data = data_tmp

		if not removed
			@error_msg = "Can't remove the item: #{id}!"
			@error     = 7
		end

		return removed
	end

	
	# Export to csv
	# @args: file -> a string to match
	# @rtrn: true if export work
	def export(file)
		begin
			File.open(file, 'w+') do |f|
				f << @data
			end
			return true
		rescue
			@error_msg = "Can't export, impossible to write in #{file}!"
			@error     = 8
			return false
		end
	end

	# Import to csv
	# @args: search -> a string to match
	# @rtrn: true if the import work
	def import(file)
		begin
			data_new = IO.read(file)
			data_new.lines do |line|
				if not line =~ /(.*,){6}/
					@error_msg = "Can't import, the file is bad format!"
					@error     = 9
					return false
				end
			end
			@data << data_new

			return true
		rescue
			@error_msg = "Can't import, impossible to read  #{file}!"
			@error     = 10
			return false
		end
	end
		
end
