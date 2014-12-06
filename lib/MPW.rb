#!/usr/bin/ruby
# author: nishiki
# mail: nishiki@yaegashi.fr
# info: a simple script who manage your passwords

require 'rubygems'
require 'gpgme'
require 'csv'
require 'i18n'
require 'fileutils'
	
module MPW
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
				data_decrypt = crypto.decrypt(IO.read(@file_gpg), password: passwd).read.force_encoding('utf-8')
				@data = YAML.load(data_decrypt)
			end
	
			return true
		rescue Exception => e 
			@error_msg = "#{I18n.t('error.gpg_file.decrypt')}\n#{e}"
			return false
		end
	
		# Encrypt a file
		# @rtrn: true if the file has been encrypted
		def encrypt
			FileUtils.cp(@file_gpg, "#{@file_gpg}.bk") if File.exist?(@file_gpg)
	
			data_to_encrypt = @data.to_yaml
	
			recipients = []
			recipients.push(@key)
			if not @share_keys.nil?
				@share_keys.split.each { |k| recipients.push(k) }
			end

			crypto = GPGME::Crypto.new(armor: true)
			file_gpg = File.open(@file_gpg, 'w+')
			crypto.encrypt(data_to_encrypt, recipients: recipients, output: file_gpg)
			file_gpg.close
	
			FileUtils.rm("#{@file_gpg}.bk") if File.exist?("#{@file_gpg}.bk")
			return true
		rescue Exception => e 
			@error_msg = "#{I18n.t('error.gpg_file.encrypt')}\n#{e}"
			FileUtils.mv("#{@file_gpg}.bk", @file_gpg) if File.exist?("#{@file_gpg}.bk")
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
	
			@data.each do |id, row|
				name    = row['name'].nil?    ? nil : row['name'].downcase
				server  = row['host'].nil?    ? nil : row['host'].downcase
				comment = row['comment'].nil? ? nil : row['comment'].downcase
	
				if name =~ /^.*#{search}.*$/ or server =~ /^.*#{search}.*$/ or comment =~ /^.*#{search}.*$/ 
					if (protocol.nil? or protocol.eql?(row[:protocol])) and (group.nil? or group.eql?(row[:group]))
						result.push(row)
					end
				end
			end
	
			return result
		end
	
		# Search in some csv data
		# @args: id_search -> the id item
		# @rtrn: a row with the resultat of the search
		def search_by_id(id_search)
			@data.each do |id, row|
				return row if id == id_search
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
			if @data.has_key?(id)
				row = @data[id]
			end
	
			if port.to_i <= 0
				port = nil
			end
	
			row_update             = {}
			row_update['id']       = id.to_s.empty?       ? MPW.password(16) : id
			row_update['name']     = name.to_s.empty?     ? row['name']      : name
			row_update['group']    = group.to_s.empty?    ? row['group']     : group
			row_update['host']     = server.to_s.empty?   ? row['host']      : server
			row_update['protocol'] = protocol.to_s.empty? ? row['protocol']  : protocol
			row_update['login']    = login.to_s.empty?    ? row['login']     : login
			row_update['password'] = passwd.to_s.empty?   ? row['password']  : passwd
			row_update['port']     = port.to_s.empty?     ? row['port']      : port
			row_update['comment']  = comment.to_s.empty?  ? row['comment']   : comment
			row_update['date']     = Time.now.to_i
	
			if row_update['name'].to_s.empty?
				@error_msg = I18n.t('error.update.name_empty')
				return false
			end
	
			if update
				@data[id] = row_update
			else
				@data[row_update['id']] = row_update
			end
	
			return true
		end
		
		# Remove an item 
		# @args: id -> the item's identifiant
		# @rtrn: true if the item has been deleted
		def remove(id)
			@data.each do |k, row|
				if k == id
					@data.delete(id)
					return true
				end
			end
	
			@error_msg = I18n.t('error.delete.id_no_exist', id: id)
			return false
		end
	
		# Export to csv
		# @args: file -> file where you export the data
		#        type -> udata type
		# @rtrn: true if export work
		def export(file, type=:csv)
			case type
			when :csv
					CSV.open(file, 'w', write_headers: true,
										headers: ['name', 'group', 'protocol', 'host', 'login', 'password', 'port', 'comment']) do |csv|
						@data.each do |id, r|
							csv << [r['name'], r['group'], r['protocol'], r['host'], r['login'], r['password'], r['port'], r['comment']]
						end
					end

			when :yaml
				File.open(file, 'w') {|f| f << @data.to_yaml}

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
		#        type -> udata type
		# @rtrn: true if the import work
		def import(file, type=:csv)
			case type
			when :csv
				CSV.foreach(file, {headers: true}) do |row|
					if not update(row['name'], row['group'], row['host'], row['protocol'], row['login'], row['password'], row['port'], row['comment'])
						return false
					end
				end

			when :yaml
				YAML::load_file(file).each do |k, row| 
					if not update(row['name'], row['group'], row['host'], row['protocol'], row['login'], row['password'], row['port'], row['comment'])
						return false
					end
				end

			else
				@error_msg = "#{I18n.t('error.export.unknown_type', type: type)}"
				return false
			end
	
			return true
		rescue Exception => e 
			@error_msg = "#{I18n.t('error.import.read', file: file)}\n#{e}"
			return false
		end
	
		# Return a preview import 
		# @args: file -> path to file import
		# @rtrn: an array with the items to import, if there is an error return false
		def import_preview(file, type=:csv)
			result = []
			case type
			when :csv
				CSV.foreach(file, {headers: true}) do |row|
					result << row
				end
			when :yaml
				YAML::load_file(file).each do |k, row| 
					result << row
				end
			else
				@error_msg = "#{I18n.t('error.export.unknown_type', type: type)}"
				return false
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
			if not data_remote.instance_of?(Hash)
				@error_msg = I18n.t('error.sync.hash')
				return false

			else not data_remote.to_s.empty?
				@data.each do |lk, l|
					j = 0
					update = false
		
					# Update item
					data_remote.each do |rk, r|
						if l['id'] == r['id']
							if l['date'].to_i < r['date'].to_i
								update(r['name'], r['group'], r['host'], r['protocol'], r['login'], r['password'], r['port'], r['comment'], l['id'])
							end
							update = true
							data_remote.delete(rk)
							break
						end
						j += 1
					end
		
					# Delete an old item
					if not update and l['date'].to_i < last_update
						remove(l['id'])
					end
				end
			end
	
			# Add item
			data_remote.each do |rk, r|
				if r['date'].to_i > last_update
					update(r['name'], r['group'], r['host'], r['protocol'], r['login'], r['password'], r['port'], r['comment'], r['id'])
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
