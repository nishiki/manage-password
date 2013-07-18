#!/usr/bin/ruby
# author: nishiki
# mail: nishiki@yaegashi.fr
# info: a simple script who m your passwords

require 'rubygems'
require 'highline/import'
require 'pathname'

require "#{APP_ROOT}/MPW.rb"

class Cli

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

	def decrypt()
		if not @m.checkFilePassword()
			passwd = ask("Password GPG: ") {|q| q.echo = false}
			return @m.decrypt(passwd)
		else
			return @m.decrypt()
		end
	end

	def display(search, protocol=nil)
		result = @m.search(search, protocol)

		if not result.empty?
			result.each do |r|
				puts "# --------------------"
				puts "# Id: #{r[MPW::ID]}"
				puts "# Server: #{r[MPW::SERVER]}"
				puts "# Type: #{r[MPW::PROTOCOL]}"
				puts "# Login: #{r[MPW::LOGIN]}"
				puts "# Password: #{r[MPW::PASSWORD]}"
				puts "# Port: #{r[MPW::PORT]}"
				puts "# Comment: #{r[MPW::COMMENT]}"
			end
		else
			puts "Nothing result!"	
		end
	end

	def add()
		row = Array.new()
		puts "# Add a new item"
		puts "# --------------------"
		server   = ask("Enter the server name or ip: ")
		protocol = ask("Enter the type of connection (ssh, web, other): ")
		login    = ask("Enter the login connection: ")
		passwd   = ask("Enter the the password: ")
		port     = ask("Enter the connection port (optinal): ")
		comment  = ask("Enter a comment (optinal): ")

		@m.add(server, protocol, login, passwd, port, comment)

		if @m.encrypt()
			puts "Item has been added!"
		else
			puts "ERROR: #{@m.error_msg}"
		end
	end

	def update(id)
		row = @m.searchById(id)

		if not row.empty?
			puts "# Add a new password"
			puts "# --------------------"
			server   = ask("Enter the server name or ip [#{row[MPW::SERVER]}]: ")
			protocol = ask("Enter the type of connection [#{row[MPW::PROTOCOL]}]: ")
			login    = ask("Enter the login connection [#{row[MPW::LOGIN]}]: ")
			passwd   = ask("Enter the the password: ")
			port     = ask("Enter the connection port [#{row[MPW::PORT]}]: ")
			comment  = ask("Enter a comment [#{row[MPW::COMMENT]}]: ")
				
			if @m.update(id, server, protocol, login, passwd, port, comment)
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

	def ssh(search)
		@m.ssh(search)
	end
end
