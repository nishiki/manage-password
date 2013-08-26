#!/usr/bin/ruby
# author: nishiki
# mail: nishiki@yaegashi.fr
# info: a simple script who m your passwords

require 'rubygems'
require 'highline/import'
require 'pathname'

require "#{APP_ROOT}/MPW.rb"

class Cli

	# Constructor
	def initialize()
		@m = MPW.new()
		
		if not @m.checkconfig()
			self.setup()
		end

		if not self.decrypt()
			puts "ERROR: #{@m.error_msg}"
			exit 2
		end
	end

	# Create a new config file
	def setup()
		puts "# Setup a new config file"
		puts "# --------------------"
		key         = ask("Enter the GPG key: ")
		file_gpg    = ask("Enter the path to encrypt file [default=#{Dir.home()}/.mpw.gpg]: ")
		file_pwd    = ask("Enter te path to password file [default=#{Dir.home()}/.mpw.pwd]: ")
		timeout_pwd = ask("Enter the timeout (in seconde) to GPG password [default=300]: ")
		
		if @m.setup(key, file_gpg, file_pwd, timeout_pwd)
			puts "The config file has been created!"
		else
			puts "ERROR: #{@m.error_msg}"
		end
	end

	# Request the GPG password and decrypt the file
	def decrypt()
		if not @m.checkFilePassword()
			passwd = ask("Password GPG: ") {|q| q.echo = false}
			return @m.decrypt(passwd)
		else
			return @m.decrypt()
		end
	end

	# Display the query's result
	# @args: search -> the string to search
	#        protocol -> search from a particular protocol
	def display(search, protocol=nil)
		result = @m.search(search, protocol)

		if not result.empty?
			i = 0
			result.each do |r|
				puts "# --------------------"
				puts "# Id: #{i}"
				puts "# Name: #{r[MPW::NAME]}"
				puts "# Group: #{r[MPW::GROUP]}"
				puts "# Server: #{r[MPW::SERVER]}"
				puts "# Type: #{r[MPW::PROTOCOL]}"
				puts "# Login: #{r[MPW::LOGIN]}"
				puts "# Password: #{r[MPW::PASSWORD]}"
				puts "# Port: #{r[MPW::PORT]}"
				puts "# Comment: #{r[MPW::COMMENT]}"

				i += 1
			end
		else
			puts "Nothing result!"	
		end
	end

	# Form to add a new item
	def add()
		row = Array.new()
		puts "# Add a new item"
		puts "# --------------------"
		name     = ask("Enter the name: ")
		group    = ask("Enter the group [default=No Group]: ")
		server   = ask("Enter the hostname or ip: ")
		protocol = ask("Enter the type of connection (ssh, web, other): ")
		login    = ask("Enter the login connection: ")
		passwd   = ask("Enter the the password: ")
		port     = ask("Enter the connection port (optinal): ")
		comment  = ask("Enter a comment (optinal): ")

		if @m.add(name, group, server, protocol, login, passwd, port, comment)
			if @m.encrypt()
				puts "Item has been added!"
			else
				puts "ERROR: #{@m.error_msg}"
			end
		else
			puts "ERROR: #{@m.error_msg}"
		end
	end

	# Update an item
	# @args: id -> the item's id
	def update(id)
		row = @m.searchById(id)

		if not row.empty?
			puts "# Update an item"
			puts "# --------------------"
			name     = ask("Enter the name [#{row[MPW::NAME]}]: ")
			group    = ask("Enter the group [#{row[MPW::GROUP]}]: ")
			server   = ask("Enter the hostname or ip [#{row[MPW::SERVER]}]: ")
			protocol = ask("Enter the type of connection [#{row[MPW::PROTOCOL]}]: ")
			login    = ask("Enter the login connection [#{row[MPW::LOGIN]}]: ")
			passwd   = ask("Enter the the password: ")
			port     = ask("Enter the connection port [#{row[MPW::PORT]}]: ")
			comment  = ask("Enter a comment [#{row[MPW::COMMENT]}]: ")
				
			if @m.update(id, name, group, server, protocol, login, passwd, port, comment)
				if @m.encrypt()
					puts "Item has been updated!"
				else
					puts "ERROR: #{@m.error_msg}"
				end
			else
				puts "Nothing item has been updated!"
			end
		else
			puts "Nothing result!"
		end
	end

	# Remove an item
	# @args: id -> the item's id
	#        force -> no resquest a validation
	def remove(id, force=false)
		if not force
			confirm = ask("Are you sur to remove the item: #{id} ? (y/N) ")
			if confirm =~ /^(y|yes|YES|Yes|Y)$/
				force = true
			end
		end

		if force
			if @m.remove(id)
				if @m.encrypt()
					puts "The item #{id} has been removed!"
				else
					puts "ERROR: #{@m.error_msg}"
				end
			else
				puts "Nothing item has been removed!"
			end
		end
	end

	# Export the items in a CSV file
	# @args: file -> the destination file
	def export(file)
		if @m.export(file)
			puts "The export in #{file} is succesfull!"
		else
			puts "ERROR: #{@m.error_msg}"
		end

	end

	# Import items from a CSV file
	# @args: file -> the import file
	def import(file)
		if @m.import(file)
			if @m.encrypt()
				puts "The import is succesfull!"
			else
				puts "ERROR: #{@m.error_msg}"
			end
		else
			puts "ERROR: #{@m.error_msg}"
		end
			
	end

end
