#!/usr/bin/ruby
# author: nishiki
# mail: nishiki@yaegashi.fr

require 'rubygems'
require 'gpgme'
require 'csv'
require 'i18n'
require 'fileutils'
require 'yaml'
require 'mpw/item'
	
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
			@data = []

			if File.exist?(@file_gpg) and not File.zero?(@file_gpg)
				crypto       = GPGME::Crypto.new(armor: true)
				data_decrypt = crypto.decrypt(IO.read(@file_gpg), password: password).read.force_encoding('utf-8')

				if not data_decrypt.to_s.empty?
					YAML.load(data_decrypt).each_value do |d|
						@data.push(Item.new(id:        d['id'],
						                    name:      d['name'],
						                    group:     d['group'],
						                    host:      d['host'],
						                    protocol:  d['protocol'],
						                    user:      d['user'],
						                    password:  d['password'],
						                    port:      d['port'],
						                    comment:   d['comment'],
						                    last_edit: d['last_edit'],
						                    created:   d['created'],
						                   )
						          )
					end
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

			data_to_encrypt = {}
	
			@data.each do |item|
				next if item.empty?

				data_to_encrypt.merge!(item.id => {'id'        => item.id,
				                                   'name'      => item.name,
				                                   'group'     => item.group,
				                                   'host'      => item.host,
				                                   'protocol'  => item.protocol,
				                                   'user'      => item.user,
				                                   'password'  => item.password,
				                                   'port'      => item.port,
				                                   'comment'   => item.comment,
				                                   'last_edit' => item.last_edit,
				                                   'created'   => item.created,
				                                  }
				                      )
			end
	
			recipients = []
			recipients.push(@key)
			if not @share_keys.nil?
				@share_keys.split.each { |k| recipients.push(k) }
			end

			crypto = GPGME::Crypto.new(armor: true)
			file_gpg = File.open(@file_gpg, 'w+')
			crypto.encrypt(data_to_encrypt.to_yaml, recipients: recipients, output: file_gpg)
			file_gpg.close
	
			FileUtils.rm("#{@file_gpg}.bk") if File.exist?("#{@file_gpg}.bk")
			return true
		rescue Exception => e 
			@error_msg = "#{I18n.t('error.gpg_file.encrypt')}\n#{e}"
			FileUtils.mv("#{@file_gpg}.bk", @file_gpg) if File.exist?("#{@file_gpg}.bk")
			return false
		end
		
		# Add a new item
		# @args: item -> Object MPW::Item
		# @rtrn: true if add item
		def add(item)
			if not item.instance_of?(Item)
				@error_msg = I18n.t('error.bad_class')
				return false
			elsif item.empty?
				@error_msg = I18n.t('error.add.empty')
				return false
			else
				@data.push(item)
				return true
			end
		end

		# Search in some csv data
		# @args: options -> a hash with paramaters
		# @rtrn: a list with the resultat of the search
		def list(options={})
			result = []
	
			search   = options[:search].to_s.downcase
			group    = options[:group].to_s.downcase
			protocol = options[:protocol].to_s.downcase

			@data.each do |item|
				next if item.empty?

				next if not group.empty?    and not group.eql?(item.group.downcase)
				next if not protocol.empty? and not protocol.eql?(item.protocol.downcase)
				
				name    = item.name.to_s.downcase
				host    = item.host.to_s.downcase
				comment = item.comment.to_s.downcase

				if not name =~ /^.*#{search}.*$/ and not host =~ /^.*#{search}.*$/ and not comment =~ /^.*#{search}.*$/ 
					next
				end

				result.push(item)
			end
	
			return result
		end
	
		# Search in some csv data
		# @args: id -> the id item
		# @rtrn: a row with the result of the search
		def search_by_id(id)
			@data.each do |item|
				return item if item.id == id
			end
	
			return nil
		end
		
		# Export to csv
		# @args: file -> file where you export the data
		#        type -> udata type
		# @rtrn: true if export work
		def export(file, type=:yaml)
			case type
			when :csv
				CSV.open(file, 'w', write_headers: true,
									headers: ['name', 'group', 'protocol', 'host', 'user', 'password', 'port', 'comment']) do |csv|
					@data.each do |item|
						csv << [item.name, item.group, item.protocol, item.host, item.user, item.password, item.port, item.comment]
					end
				end

			when :yaml
				data = {}
				@data.each do |item|
					data.merge!(item.id => {'id'        => item.id,
					                        'name'      => item.name,
					                        'group'     => item.group,
					                        'host'      => item.host,
					                        'protocol'  => item.protocol,
					                        'user'      => item.user,
					                        'password'  => item.password,
					                        'port'      => item.port,
					                        'comment'   => item.comment,
					                        'last_edit' => item.last_edit,
					                        'created'   => item.created,
					                       }
					            )
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
		#        type -> udata type
		# @rtrn: true if the import work
		def import(file, type=:yaml)
			case type
			when :csv
				CSV.foreach(file, {headers: true}) do |row|
					item = Item.new(name:     row['name'], 
					                group:    row['group'],
					                host:     row['host'],
					                protocol: row['protocol'],
					                user:     row['user'],
					                password: row['password'],
					                port:     row['port'],
					                comment:  row['comment'],
					               )

					return false if item.empty?

					@data.push(item)
				end

			when :yaml
				YAML::load_file(file).each_value do |row| 
					item = Item.new(name:     row['name'], 
					                group:    row['group'],
					                host:     row['host'],
					                protocol: row['protocol'],
					                user:     row['user'],
					                password: row['password'],
					                port:     row['port'],
					                comment:  row['comment'],
					               )

					return false if item.empty?

					@data.push(item)
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
			data = []

			case type
			when :csv
				CSV.foreach(file, {headers: true}) do |row|
					item = Item.new(name:     row['name'], 
					                group:    row['group'],
					                host:     row['host'],
					                protocol: row['protocol'],
					                user:     row['user'],
					                password: row['password'],
					                port:     row['port'],
					                comment:  row['comment'],
					               )

					return false if item.empty?

					data.push(item)
				end

			when :yaml
				YAML::load_file(file).each_value do |row| 
					item = Item.new(name:     row['name'], 
					                group:    row['group'],
					                host:     row['host'],
					                protocol: row['protocol'],
					                user:     row['user'],
					                password: row['password'],
					                port:     row['port'],
					                comment:  row['comment'],
					               )

					return false if item.empty?

					data.push(item)
				end

			else
				@error_msg = "#{I18n.t('error.export.unknown_type', type: type)}"
				return false
			end
	
			return data
		rescue Exception => e 
			@error_msg = "#{I18n.t('error.import.read', file: file)}\n#{e}"
			return false
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
