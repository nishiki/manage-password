#!/usr/bin/ruby
# author: nishiki
# mail: nishiki@yaegashi.fr
# info: a simple script who manage your passwords

require 'rubygems'
require 'gpgme'
require 'csv'
require 'i18n'

class MPW
	
	ID       = 0
	NAME     = 1
	GROUP    = 2
	PROTOCOL = 3
	SERVER   = 4
	LOGIN    = 5
	PASSWORD = 6
	PORT     = 7
	COMMENT  = 8
	DATE     = 9

	attr_accessor :error_msg
	
	# Constructor
	def initialize(file_gpg, key=nil)
		@error_msg = nil
		@file_gpg  = file_gpg
		@key       = key
	end

	# Decrypt a gpg file
	# @args: password -> the GPG key password
	# @rtrn: true if data has been decrypted
	def decrypt(passwd=nil)
		@data = Array.new

		begin
			if File.exist?(@file_gpg)
				crypto = GPGME::Crypto.new(:armor => true)
				data_decrypt = crypto.decrypt(IO.read(@file_gpg), :password => passwd).read

				data_decrypt.lines do |line|
					@data.push(line.parse_csv)
				end
			end

			return true
		rescue Exception => e 
			@error_msg = "#{I18n.t('error.gpg_file.decrypt')}\n#{e}"
			return false
		end
	end

	# Encrypt a file
	# @rtrn: true if the file has been encrypted
	def encrypt()
		begin
			crypto = GPGME::Crypto.new(:armor => true)
			file_gpg = File.open(@file_gpg, 'w+')

			data_to_encrypt = ''
			@data.each do |row|
				data_to_encrypt << row.to_csv
			end

			crypto.encrypt(data_to_encrypt, :recipients => @key, :output => file_gpg)
			file_gpg.close

			return true
		rescue Exception => e 
			@error_msg = "#{I18n.t('error.gpg_file.encrypt')}\n#{e}"
			return false
		end
	end
	
	# Search in some csv data
	# @args: search -> the string to search
	#        protocol -> the connection protocol (ssh, web, other)
	# @rtrn: a list with the resultat of the search
	def search(search='', group=nil, protocol=nil)
		result = Array.new()

		if !search.nil?
			search = search.downcase
		end
		search = search.force_encoding('ASCII-8BIT')

		@data.each do |row|
			row[NAME].nil?    ? (name    = nil) : (name    = row[NAME].downcase)
			row[SERVER].nil?  ? (server  = nil) : (server  = row[SERVER].downcase)
			row[COMMENT].nil? ? (comment = nil) : (comment = row[COMMENT].downcase)

			if name =~ /^.*#{search}.*$/  || server =~ /^.*#{search}.*$/ || comment =~ /^.*#{search}.*$/ 
				if (protocol.nil? || protocol.eql?(row[PROTOCOL])) && (group.nil? || group.eql?(row[GROUP]))
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
		@data.each do |row|
			if row[ID] == id
				return row
			end
		end

		return Array.new()
	end

	# Update an item
	# @args: id -> the item's identifiant
	#        name -> the item name
	#        group ->  the item group
	#        server -> the ip or hostname
	#        protocol -> the protocol
	#        login -> the login
	#        passwd -> the password
	#        port -> the port
	#        comment -> a comment
	# @rtrn: true if the item has been updated
	def update(name, group, server, protocol, login, passwd, port, comment, id=nil)
		row    = Array.new()
		update = false

		i  = 0
		@data.each do |r|
			if r[ID] == id
				row    = r
				update = true
				break
			end
			i += 1
		end

		if port.to_i <= 0
			port = nil
		end

		row_update       = Array.new()
		row_update[DATE] = Time.now.to_i

		id.nil?	      || id.empty?       ? (row_update[ID]       = MPW.generatePassword(16)) : (row_update[ID]       = row[ID])
		name.nil?     || name.empty?     ? (row_update[NAME]     = row[NAME])                : (row_update[NAME]     = name)
		group.nil?    || group.empty?    ? (row_update[GROUP]    = row[GROUP])               : (row_update[GROUP]    = group)
		server.nil?   || server.empty?   ? (row_update[SERVER]   = row[SERVER])              : (row_update[SERVER]   = server)
		protocol.nil? || protocol.empty? ? (row_update[PROTOCOL] = row[PROTOCOL])            : (row_update[PROTOCOL] = protocol)
		login.nil?    || login.empty?    ? (row_update[LOGIN]    = row[LOGIN])               : (row_update[LOGIN]    = login)
		passwd.nil?   || passwd.empty?   ? (row_update[PASSWORD] = row[PASSWORD])            : (row_update[PASSWORD] = passwd)
		port.nil?     || port.empty?     ? (row_update[PORT]     = row[PORT])                : (row_update[PORT]     = port)
		comment.nil?  || comment.empty?  ? (row_update[COMMENT]  = row[COMMENT])             : (row_update[COMMENT]  = comment)
		
		if row_update[NAME].nil? || row_update[NAME].empty?
			@error_msg = I18n.t('error.update.name_empty')
			return false
		end

		if update
			@data[i] = row_update
		else
			@data.push(row_update)
		end

		return true
	end
	
	# Remove an item 
	# @args: id -> the item's identifiant
	# @rtrn: true if the item has been deleted
	def remove(id)
		i = 0
		@data.each do |row|
			if row[ID] == id
				@data.delete_at(i)
				return true
			end
			i += 1
		end

		@error_msg = I18n.t('error.delete.id_no_exist', :id => id)
		return false
	end

	# Export to csv
	# @args: file -> a string to match
	# @rtrn: true if export work
	def export(file)
		begin
			File.open(file, 'w+') do |file|
				@data.each do |row|
					row.delete_at(ID).delete_at(DATE)
					file << row.to_csv
				end
			end

			return true
		rescue Exception => e 
			@error_msg = "#{I18n.t('error.export.write', :file => file)}\n#{e}"
			return false
		end
	end

	# Import to csv
	# @args: file -> path to file import
	# @rtrn: true if the import work
	def import(file)
		begin
			data_new = IO.read(file)
			data_new.lines do |line|
				if not line =~ /(.*,){6}/
					@error_msg = I18n.t('error.import.bad_format')
					return false
				else
					row = line.parse_csv.unshift(0)
					if not update(row[NAME], row[GROUP], row[SERVER], row[PROTOCOL], row[LOGIN], row[PASSWORD], row[PORT], row[COMMENT])
						return false
					end
				end
			end

			return true
		rescue Exception => e 
			@error_msg = "#{I18n.t('error.import.read', :file => file)}\n#{e}"
			return false
		end
	end

	# Return a preview import 
	# @args: file -> path to file import
	# @rtrn: an array with the items to import, if there is an error return false
	def importPreview(file)
		begin
			result = Array.new()
			id = 0

			data = IO.read(file)
			data.lines do |line|
				if not line =~ /(.*,){6}/
					@error_msg = I18n.t('error.import.bad_format')
					return false
				else
					result.push(line.parse_csv.unshift(id))
				end

				id += 1
			end

			return result
		rescue Exception => e 
			@error_msg = "#{I18n.t('error.import.read', :file => file)}\n#{e}"
			return false
		end
	end

	# Sync remote data and local data
	# @args: data_remote -> array with the data remote
	#        last_update -> last update
	# @rtrn: false if data_remote is nil
	def sync(data_remote, last_update)
		if !data_remote.instance_of?(Array)
			return false
		end

		@data.each do |l|
			j = 0
			update = false

			# Update item
			data_remote.each do |r|
				if l[ID] == r[ID]
					if l[DATE].to_i < r[DATE].to_i
						update(r[NAME], r[GROUP], r[SERVER], r[PROTOCOL], r[LOGIN], r[PASSWORD], r[PORT], r[COMMENT], l[ID])
					end
					update = true
					data_remote.delete_at(j)
					break
				end
				j += 1
			end

			# Delete an old item
			if !update && l[DATE].to_i < last_update
				remove(l[ID])
			end
		end

		# Add item
		data_remote.each do |r|
			if r[DATE].to_i > last_update
				update(r[NAME], r[GROUP], r[SERVER], r[PROTOCOL], r[LOGIN], r[PASSWORD], r[PORT], r[COMMENT], r[ID])
			end
		end

		encrypt()

		return true
	end

	# Generate a random password
	# @args: length -> the length password
	# @rtrn: a random string
	def self.generatePassword(length=8)
		if length.to_i <= 0
			length = 8
		else
			length = length.to_i
		end

		result = ''
		while length > 62 do
			result << ([*('A'..'Z'),*('a'..'z'),*('0'..'9')]).sample(62).join
			length -= 62
		end
		result << ([*('A'..'Z'),*('a'..'z'),*('0'..'9')]).sample(length).join

		return result
	end
	
end
