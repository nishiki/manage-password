#!/usr/bin/ruby
# author: nishiki
# mail: nishiki@yaegashi.fr
# info: a simple script who manage your passwords

require 'rubygems'
require 'gpgme'
require 'csv'
require 'net/ssh'
require 'highline/import'

FILE_GPG    = './pass.gpg'
KEY         = 'a.waksberg@yaegashi.fr'
FILE_PWD    = '/tmp/.password-manager.pwd'
TIMEOUT_PWD = 300

class ManagePasswd
	
	ID       = 0
	TYPE     = 1
	SERVER   = 2
	LOGIN    = 3
	PASSWORD = 4
	PORT     = 5
	COMMENT  = 6

	# Constructor
	# @args: key -> the gpg key to encrypt
	#        file_gpg -> the file who is encrypted
	#        file_pwd -> the file who stock the password
	#        timeout_pwd -> time to save the password 
	def initialize(key, file_gpg, file_pwd, timeout_pwd=300)
		@key = key
		@file_gpg = file_gpg
		@file_pwd = file_pwd
		@timeout_pwd = timeout_pwd

		if File.exist?(@file_gpg)
			if not self.decrypt()
				exit 2
			end
		else
			@data = ""
		end
	end

	# Decrypt a gpg file
	# @rtrn: true if data is decrypted
	def decrypt()
		if File.exist?(@file_pwd) && File.stat(@file_pwd).mtime.to_i + @timeout_pwd < Time.now.to_i
			File.delete(@file_pwd)
		end

		begin
			passwd = IO.read(@file_pwd)
		rescue
			passwd = ask("Password GPG: ") {|q| q.echo = false}
			file_pwd = File.new(@file_pwd, 'w+')
			File.chmod(0600, @file_pwd)
			file_pwd << passwd
			file_pwd.close
		end
		
		begin
			crypto = GPGME::Crypto.new(:armor => true)
			@data = crypto.decrypt(IO.read(@file_gpg), :password => passwd).read

			return true
		rescue
			puts "Your passphrase is probably wrong!"
			File.delete(@file_pwd)

			return false
		end
	end

	# Encrypt a file
	def encrypt()
		begin
			crypto = GPGME::Crypto.new(:armor => true)
			file_gpg = File.open(@file_gpg, 'w+')
			crypto.encrypt(@data, :recipients => @key, :output => file_gpg)
			file_gpg.close

			return true
		rescue
			puts "Error during the encrypting file"
			return false
		end
	end
	
	# Search in some csv data
	# @args: search -> the string to search
	#        type -> the connection type (ssh, web, other)
	# @rtrn: a list with the resultat of the search
	def search(search, type=nil)
		result = Array.new()
		@data.lines do |line|
			row = line.parse_csv
			if line =~ /^.*#{search}.*$/ || type.eql?('all')
				if type.nil? || type.eql?(row[TYPE]) || type.eql?('all')
					result.push(row)
				end
			end
		end

		return result
	end

	# Display the connections informations for a server
	# @args: search -> a string to match
	#        type -> search for a type item
	def display(search, type=nil)
		result = self.search(search, type)

		if result.length > 0 
			result.each do |r|
				puts "# --------------------"
				puts "# Id: #{r[ID]}"
				puts "# Server: #{r[SERVER]}"
				puts "# Type: #{r[TYPE]}"
				puts "# Login: #{r[LOGIN]}"
				puts "# Password: #{r[PASSWORD]}"
				puts "# Port: #{r[PORT]}"
				puts "# Comment: #{r[COMMENT]}"
			end

			return true
		else
			puts "Nothing result!"
			return false
		end
	end

	# Add a new item
	def add()
		row = Array.new()
		puts "# Add a new password"
		puts "# --------------------"
		row[ID] = Time.now.to_i.to_s(16)
		row[SERVER]   = ask("Enter the server name or ip: ")
		row[TYPE]     = ask("Enter the type of connection (ssh, web, other): ")
		row[LOGIN]    = ask("Enter the login connection: ")
		row[PASSWORD] = ask("Enter the the password: ")
		row[PORT]     = ask("Enter the connection port (optinal): ")
		row[COMMENT]  = ask("Enter a comment (optinal): ")
		
		@data << "#{row.join(',')}\n"
		puts 'Item has been added!'
	end
	
	# Update an item
	# @args: id -> the item's identifiant
	def update(id)
		data_tmp = ''
		@data.lines do |line|
			row = line.parse_csv
			if id.eql?(row[ID])
				row_update = Array.new()
				
				puts "# Add a new password"
				puts "# --------------------"
				server  = ask("Enter the server name or ip [#{row[SERVER]}]: ")
				type    = ask("Enter the type of connection [#{row[TYPE]}]: ")
				login   = ask("Enter the login connection [#{row[LOGIN]}]: ")
				passwd  = ask("Enter the the password: ")
				port    = ask("Enter the connection port [#{row[PORT]}]: ")
				comment = ask("Enter a comment [#{row[COMMENT]}]: ")
				
				row_update[ID] = row[ID]
				server.empty?  ? (row_update[SERVER]   = row[SERVER])   : (row_update[SERVER]   = server)
				type.empty?    ? (row_update[TYPE]     = row[TYPE])     : (row_update[TYPE]     = type)
				login.empty?   ? (row_update[LOGIN]    = row[LOGIN])    : (row_update[LOGIN]    = login)
				passwd.empty?  ? (row_update[PASSWORD] = row[PASSWORD]) : (row_update[PASSWORD] = passwd)
				port.empty?    ? (row_update[PORT]     = row[PORT])     : (row_update[PORT]     = port)
				comment.empty? ? (row_update[COMMENT]  = row[COMMENT])  : (row_update[COMMENT]  = comment)
				
				data_tmp << "#{row_update.join(',')}\n"
			else
				data_tmp << line
			end
		end
		@data = data_tmp
		puts 'Item has been updated!'
	end
	
	# Remove an item 
	# @args: id -> the item's identifiant
	def remove(id)
		data_tmp = ''
		@data.lines do |line|
			row = line.parse_csv
			if id.eql?(row[ID])
				puts "The item #{row[ID]} has been removed!"
			else
				data_tmp << line
			end
		end
		@data = data_tmp
	end
	
	# Connect to ssh && display the password
	# @args: search -> a string to match
	def ssh(search)
		result = self.search(search, 'ssh')

		if result.length > 0
			result.each do |r|
				server = r[SERVER]
				login  = r[LOGIN]
				port   = r[PORT]
				passwd = r[PASSWORD]

				if port.empty?
					port = 22
				end

				if passwd.empty?
					system("#{passwd} ssh #{login}@#{server} -p #{port}")
				else
					system("sshpass -p #{passwd} ssh #{login}@#{server} -p #{port}")
				end
				#Net::SSH.start(server, login, :port => port, :password => passwd) do |ssh|
				#	channel = ssh.open_channel do |ch|
				#		puts ch.exec 'ls'
				#		ch.on_data do |data|
				#			$stdout.print data
				#		end
				#	end
				#end
			end

			return true
		else
			puts "Nothing result!"
			return false
		end
	end
		
end
