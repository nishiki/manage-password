#!/usr/bin/ruby
# author: nishiki
# mail: nishiki@yaegashi.fr
# info: a simple script who manage your passwords

require 'rubygems'
require 'gpgme'
require 'csv'

FILE_GPG    = '/home/nishiki/.password-manager.gpg'
KEY         = 'nishiki@yaegashi.fr'
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
	# @args: key ->
	#        file_gpg ->
	#        file_pwd ->
	#        timeout_pwd ->
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
			print "Password GPG: "
			passwd = $stdin.gets
			file_pwd = File.new(@file_pwd, 'w+')
			file_pwd << passwd
			file_pwd.close
			File.chmod(0600, @file_pwd)
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
			if line =~ /^.*#{search}.*$/
				if type.nil? || type.eql?(row[TYPE])
					puts "test"
					result.push(row)
				end
			end
		end

		return result
	end

	# Display the connections informations for a server
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
		print "Enter the server name or ip: "
		row[SERVER] = $stdin.gets
		print "Enter the type of connection (ssh, web, other): "
		row[TYPE] = $stdin.gets
		print "Enter the login connection: "
		row[LOGIN] = $stdin.gets
		print "Enter the the password: "
		row[PASSWORD] = $stdin.gets
		print "Enter the connection port (optinal): "
		row[PORT] = $stdin.gets
		print "Enter a comment (optinal): "
		row[COMMENT] = $stdin.gets
		
		@data << "#{row.join(',')}\n"
	end
	
	# Update an item
	# @args: id -> the item's identifiant
	def update(id)
		data_tmp = ''
		@data.lines do |line|
			row = line.parse_csv
			if id.eql?(row[ID])
				update_row = Array.new()
				
				puts "# Add a new password"
				puts "# --------------------"
				puts "Enter the server name or ip [#{row[SERVER]}]: "
				server = $stdin.gets
				puts = "Enter the type of connection [#{row[TYPE]}]: "
				type = $stdin.gets
				puts "Enter the login connection [#{row[LOGIN]}]: "
				login = $stdin.gets
				puts "Enter the the password: "
				passwd = $stdin.gets
				puts "Enter the connection port [#{row[PORT]}]: "
				port = $stdin.gets
				puts "Enter a comment [#{row[COMMENT]}]: "
				comment = $stdin.gets
				
				# TODO

			else
				data_tmp << line
			end
		end
		@data = data_tmp
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
	# @args: search -> 
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
			end

			return true
		else
			puts "Nothing result!"
			return false
		end
	end

	# Display help
	def help()
		puts "# HELP"
		puts "# --------------------"
		puts "Add a new item: -a"
		puts "Update an item: -u ID"
		puts "Remove an item: -r ID"
		puts "Show a item: -d search [type]"
		puts "Connect ssh: -s search"
	end
		
end

manage = ManagePasswd.new(KEY, FILE_GPG, FILE_PWD)
num_argv = ARGV.length

# Display the item's informations
if num_argv >= 2 && ARGV[0] == '-d'
	if num_argv == 3
		manage.display(ARGV[1], ARGV[2])
	else
		manage.display(ARGV[3])
	end

# Remove an item
elsif num_argv == 2 && ARGV[0] == '-r'
	manage.remove(ARGV[1]) 
	manage.encrypt()

# Update an item
elsif num_argv == 2 && ARGV[0] == '-u'
	manage.update(ARGV[1]) 
	manage.encrypt()

# Connect to ssh
elsif num_argv == 2 && ARGV[0] == '-s'
	manage.ssh(ARGV[1])

# Add a new item
elsif num_argv == 1 && ARGV[0] == '-a'
	manage.add()
	manage.encrypt()

# Display help
else
	manage.help()
end
