#!/usr/bin/ruby
# author: nishiki
# mail: nishiki@yaegashi.fr
# info: a simple script who manage your passwords

require 'rubygems'
require 'gpgme'
require 'csv'
require 'i18n'
require 'fileutils'
require 'yaml'
require "#{APP_ROOT}/lib/Item"
	
module MPW
	class MPW
	
		attr_accessor :error_msg
		
		# Constructor
		def initialize(file_gpg, key, share_keys='')
			@error_msg  = nil
			@file_gpg   = file_gpg
			@key        = key
			@share_keys = share_keys
			@data       = []
		end
	
		# Decrypt a gpg file
		# @args: password -> the GPG key password
		# @rtrn: true if data has been decrypted
		def decrypt(password=nil)
			if File.exist?(@file_gpg)
				crypto       = GPGME::Crypto.new(armor: true)
				data_decrypt = crypto.decrypt(IO.read(@file_gpg), password: password).read.force_encoding('utf-8')
				if not data_decrypt.to_s.empty?
					YAML.load(data_decrypt).each do |d|
						@data.push(MPW::Item.new(id:        d['id'],
						                         name:      d['name'],
						                         group:     d['group'],
						                         host:      d['host'],
						                         protocol:  d['protocol'],
						                         user:      d['login'],
						                         password:  d['password'],
						                         port:      d['port'],
						                         comment:   d['comment'],
						                         last_edit: d['last_edit'],
						                         created:   d['created'],
						                        )
					end
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
		def list(options={})
			result = []
	
			search = defined?(options[:search]) ? options[:search].downcase : ''
	
			@data.each do |item|
				name    = item.name.nil?    ? nil : item.name.downcase
				host    = item.host.nil?    ? nil : item.host.downcase
				comment = item.comment.nil? ? nil : item.comment.downcase
	
				if name =~ /^.*#{search}.*$/ or host =~ /^.*#{search}.*$/ or comment =~ /^.*#{search}.*$/ 
					if (not defined?(options[:protocol] or options[:protocol].eql?(item.protocol)) and 
					   (group.nil? or options[:group].eql?(item.group))
						result.push(item)
					end
				end
			end
	
			return result
		end
	
		# Search in some csv data
		# @args: id -> the id item
		# @rtrn: a row with the resultat of the search
		def search_by_id(id)
			@data.each do |item|
				return item if item.id == id
			end
	
			return nil
		end
		
		# Remove an item 
		# @args: id -> the item's identifiant
		# @rtrn: true if the item has been deleted
		def remove(id)
			@data.each_value do |row|
				if row['id'] == id
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
		def export(file, type=:yaml)
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
		def import(file, type=:yaml)
			case type
			when :csv
				CSV.foreach(file, {headers: true}) do |row|
					if not update(row['name'], row['group'], row['host'], row['protocol'], row['login'], row['password'], row['port'], row['comment'])
						return false
					end
				end

			when :yaml
				YAML::load_file(file).each_value do |row| 
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
		# @rtrn: a hash with the items to import, if there is an error return false
		def import_preview(file, type=:yaml)
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
			if not data_remote.instance_of?(Array)
				@error_msg = I18n.t('error.sync.array')
				return false
			else not data_remote.to_s.empty?
				@data.each_value do |l|
					j = 0
					update = false
		
					# Update item
					data_remote.each do |r|
						if l['id'] == r['id']
							if l['date'].to_i < r['date'].to_i
								update(r['name'], r['group'], r['host'], r['protocol'], r['login'], r['password'], r['port'], r['comment'], l['id'])
							end
							update = true
							data_remote.delete(r['id'])
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
			data_remote.each do |r|
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
