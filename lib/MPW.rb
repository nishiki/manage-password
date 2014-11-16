#!/usr/bin/ruby
# author: nishiki
# mail: nishiki@yaegashi.fr
# info: a simple script who manage your passwords

module MPW

	require 'rubygems'
	require 'gpgme'
	require 'csv'
	require 'i18n'
	require 'fileutils'
	
	class MPW
	
		attr_accessor :error_msg
		
		# Constructor
		def initialize(file_gpg, key=nil, share_keys='')
			@error_msg  = nil
			@file_gpg   = file_gpg
			@key        = key
			@share_keys = share_keys
		end
	
		# Decrypt a gpg file
		# @args: password -> the GPG key password
		# @rtrn: true if data has been decrypted
		def decrypt(passwd=nil)
			@data = []
	
			if File.exist?(@file_gpg)
				crypto = GPGME::Crypto.new(armor: true)
				data_decrypt = crypto.decrypt(IO.read(@file_gpg), password: passwd).read
	
				@data = CSV.parse(data_decrypt, {headers: true, header_converters: :symbol})
			end
	
			return true
		rescue Exception => e 
			@error_msg = "#{I18n.t('error.gpg_file.decrypt')}\n#{e}"
			return false
		end
	
		# Encrypt a file
		# @rtrn: true if the file has been encrypted
		def encrypt
			FileUtils.cp(@file_gpg, "#{@file_gpg}.bk")

			crypto = GPGME::Crypto.new(armor: true)
			file_gpg = File.open(@file_gpg, 'w+')
	
			data_to_encrypt = CSV.generate(write_headers: true,
			                               headers: ['id', 'name', 'group', 'protocol', 'host', 'login', 'password', 'port', 'comment', 'date']) do |csv|
				@data.each do |r|
					csv << [r[:id], r[:name], r[:group], r[:protocol], r[:host], r[:login], r[:password], r[:port], r[:comment], r[:date]]
				end
			end
	
			recipients = []
			recipients.push(@key)
			if not @share_keys.nil?
				@share_keys.split.each { |k| recipients.push(k) }
			end

			crypto.encrypt(data_to_encrypt, recipients: recipients, output: file_gpg)
			file_gpg.close
	
			FileUtils.rm("#{@file_gpg}.bk")
			return true
		rescue Exception => e 
			@error_msg = "#{I18n.t('error.gpg_file.encrypt')}\n#{e}"
			FileUtils.mv("#{@file_gpg}.bk", @file_gpg)
			return false
		end
		
		# Search in some csv data
		# @args: search -> the string to search
		#        protocol -> the connection protocol (ssh, web, other)
		# @rtrn: a list with the resultat of the search
		def search(search='', group=nil, protocol=nil)
			result = []
	
			if not search.nil?
				search = search.downcase
			end
			search = search.force_encoding('ASCII-8BIT')
	
			@data.each do |row|
				name    = row[:name].nil?    ? nil : row[:name].downcase
				server  = row[:host].nil?  ? nil : row[:host].downcase
				comment = row[:comment].nil? ? nil : row[:comment].downcase
	
				if name =~ /^.*#{search}.*$/ or server =~ /^.*#{search}.*$/ or comment =~ /^.*#{search}.*$/ 
					if (protocol.nil? or protocol.eql?(row[:protocol])) and (group.nil? or group.eql?(row[:group]))
						result.push(row)
					end
				end
			end
	
			return result
		end
	
		# Search in some csv data
		# @args: id -> the id item
		# @rtrn: a row with the resultat of the search
		def search_by_id(id)
			@data.each do |row|
				if row[:id] == id
					return row
				end
			end
	
			return []
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
			row    = {}
			update = false
	
			i  = 0
			@data.each do |r|
				if r[:id] == id
					row    = r
					update = true
					break
				end
				i += 1
			end
	
			if port.to_i <= 0
				port = nil
			end
	
			row_update        = {}
			row_update[:date] = Time.now.to_i
	
			row_update[:id]       = id.nil?       or id.empty?       ? MPW.password(16)  : id
			row_update[:name]     = name.nil?     or name.empty?     ? row[:name]        : name
			row_update[:group]    = group.nil?    or group.empty?    ? row[:group]       : group
			row_update[:host]     = server.nil?   or server.empty?   ? row[:host]        : server
			row_update[:protocol] = protocol.nil? or protocol.empty? ? row[:protocol]    : protocol
			row_update[:login]    = login.nil?    or login.empty?    ? row[:login]       : login
			row_update[:password] = passwd.nil?   or passwd.empty?   ? row[:password]    : passwd
			row_update[:port]     = port.nil?     or port.empty?     ? row[:port]        : port
			row_update[:comment]  = comment.nil?  or comment.empty?  ? row[:comment]     : comment
			
			row_update[:name]     = row_update[:name].nil?     ? nil : row_update[:name].force_encoding('ASCII-8BIT')
			row_update[:group]    = row_update[:group].nil?    ? nil : row_update[:group].force_encoding('ASCII-8BIT')
			row_update[:host]     = row_update[:host].nil?     ? nil : row_update[:host].force_encoding('ASCII-8BIT')
			row_update[:protocol] = row_update[:protocol].nil? ? nil : row_update[:protocol].force_encoding('ASCII-8BIT')
			row_update[:login]    = row_update[:login].nil?    ? nil : row_update[:login].force_encoding('ASCII-8BIT')
			row_update[:password] = row_update[:password].nil? ? nil : row_update[:password].force_encoding('ASCII-8BIT')
			row_update[:comment]  = row_update[:comment].nil?  ? nil : row_update[:comment].force_encoding('ASCII-8BIT')
	
			if row_update[:name].nil? or row_update[:name].empty?
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
				if row[:id] == id
					@data.delete_at(i)
					return true
				end
				i += 1
			end
	
			@error_msg = I18n.t('error.delete.id_no_exist', id: id)
			return false
		end
	
		# Export to csv
		# @args: file -> file where you export the data
		#        type -> data type
		# @rtrn: true if export work
		def export(file, type=:csv)
			case type
			when :csv
					CSV.open(file, 'w', write_headers: true,
										headers: ['name', 'group', 'protocol', 'host', 'login', 'password', 'port', 'comment']) do |csv|
						@data.each do |r|
							csv << [r[:name], r[:group], r[:protocol], r[:host], r[:login], r[:password], r[:port], r[:comment]]
						end
					end
			when :yaml
				data = {}

				i = 0
				@data.each do |r|
					data.merge!({i => {'id'       => r[:id],
					                   'name'     => r[:name],
					                   'group'    => r[:group],
					                   'protocol' => r[:protocol],
					                   'host'     => r[:host],
					                   'login'    => r[:login],
					                   'password' => r[:password],
					                   'port'     => r[:port],
					                   'comment'  => r[:comment]
					                  }
					            }
					          )

					i += 1
				end

				File.open(file, 'w') {|f| f << data.to_yaml}
			else
				@error_msg = "#{I18n.t('error.export.unknown_type', type: type)}"
				return false
			end

			return true
		rescue Exception => e 
			@error_msg = "#{I18n.t('error.export.write', file: file)}\n#{e}"
			return false
		end
	
		# Import to csv
		# @args: file -> path to file import
		# @rtrn: true if the import work
		def import(file)
			CSV.foreach(file, {headers: true, header_converters: :symbol}) do |row|
				if not update(row[:name], row[:group], row[:host], row[:protocol], row[:login], row[:password], row[:port], row[:comment])
					return false
				end
			end
	
			return true
		rescue Exception => e 
			@error_msg = "#{I18n.t('error.import.read', file: file)}\n#{e}"
			return false
		end
	
		# Return a preview import 
		# @args: file -> path to file import
		# @rtrn: an array with the items to import, if there is an error return false
		def import_preview(file)
			result = []
			CSV.foreach(file, {headers: true, header_converters: :symbol}) do |row|
				result << row
			end

			return result
		rescue Exception => e 
			@error_msg = "#{I18n.t('error.import.read', file: file)}\n#{e}"
			return false
		end
	
		# Sync remote data and local data
		# @args: data_remote -> array with the data remote
		#        last_update -> last update
		# @rtrn: false if data_remote is nil
		def sync(data_remote, last_update)
			if not data_remote.instance_of?(Array)
				return false
			else not data_remote.nil? and not data_remote.empty?
				@data.each do |l|
					j = 0
					update = false
		
					# Update item
					data_remote.each do |r|
						if l[:id] == r[:id]
							if l[:date].to_i < r[:date].to_i
								update(r[:name], r[:group], r[:host], r[:protocol], r[:login], r[:password], r[:port], r[:comment], l[:id])
							end
							update = true
							data_remote.delete_at(j)
							break
						end
						j += 1
					end
		
					# Delete an old item
					if not update and l[:date].to_i < last_update
						remove(l[:id])
					end
				end
			end
	
			# Add item
			data_remote.each do |r|
				if r[:date].to_i > last_update
					update(r[:name], r[:group], r[:host], r[:protocol], r[:login], r[:password], r[:port], r[:comment], r[:id])
				end
			end
	
			return encrypt
		end
	
		# Generate a random password
		# @args: length -> the length password
		# @rtrn: a random string
		def self.password(length=8)
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

end
