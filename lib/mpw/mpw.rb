#!/usr/bin/ruby
# author: nishiki
# mail: nishiki@yaegashi.fr

require 'rubygems/package'
require 'gpgme'
require 'i18n'
require 'yaml'

#TODO
require "#{APP_ROOT}/../lib/mpw/item.rb"
	
module MPW
class MPW

	# Constructor
	def initialize(key, wallet_file, gpg_pass=nil)
		@key         = key
		@gpg_pass    = gpg_pass
		@wallet_file = wallet_file
	end

	# Read mpw file
	def read_data
		@config    = nil
		@data      = []
		@keys      = {}
		@passwords = {}

		data       = nil

		return if not File.exists?(@wallet_file)

		Gem::Package::TarReader.new(File.open(@wallet_file)) do |tar|
			tar.each do |f| 
				case f.full_name
					when 'wallet/config.gpg'
						@config = YAML.load(decrypt(f.read))
						check_config

					when 'wallet/meta.gpg'
						data = decrypt(f.read)

					when /^wallet\/keys\/(?<key>.+)\.pub$/
						key = Regexp.last_match('key')

						if GPGME::Key.find(:public, key).length == 0
							GPGME::Key.import(f.read, armor: true)
						end

						@keys[key] = f.read

					when /^wallet\/passwords\/(?<id>[a-zA-Z0-9]+)\.gpg$/
						@passwords[Regexp.last_match('id')] = f.read
					else
						next
				end
			end
		end

		if not data.nil? and not data.empty?
			YAML.load(data).each_value do |d|
				@data.push(Item.new(id:        d['id'],
				                    name:      d['name'],
				                    group:     d['group'],
				                    host:      d['host'],
				                    protocol:  d['protocol'],
				                    user:      d['user'],
				                    port:      d['port'],
				                    comment:   d['comment'],
				                    last_edit: d['last_edit'],
				                    created:   d['created'],
				                   )
				          )
			end
		end
	rescue Exception => e
		raise "#{I18n.t('error.mpw_file.read_data')}\n#{e}"
	end

	# Encrypt a file
	def write_data
		data     = {}
		tmp_file = "#{@wallet_file}.tmp"

		@data.each do |item|
			next if item.empty?

			data.merge!(item.id => {'id'        => item.id,
			                        'name'      => item.name,
		                            'group'     => item.group,
			                        'host'      => item.host,
			                        'protocol'  => item.protocol,
			                        'user'      => item.user,
			                        'port'      => item.port,
			                        'comment'   => item.comment,
			                        'last_edit' => item.last_edit,
			                        'created'   => item.created,
			                       }
			           )
		end

		Gem::Package::TarWriter.new(File.open(tmp_file, 'w+')) do |tar|
			data_encrypt = encrypt(YAML::dump(data))
			tar.add_file_simple('wallet/meta.gpg', 0400, data_encrypt.length) do |io|
				io.write(data_encrypt)
			end

			config = @config.to_yaml
			tar.add_file_simple('wallet/config.gpg', 0400, config.length) do |io|
				io.write(config)
			end

			@passwords.each do |id, password|
				tar.add_file_simple("wallet/passwords/#{id}.gpg", 0400, password.length) do |io|
					io.write(password)
				end
			end

			@keys.each do |id, key|
				tar.add_file_simple("wallet/keys/#{id}.pub", 0400, key.length) do |io|
					io.write(key)
				end
			end
		end

		File.rename(tmp_file, @wallet_file)
	rescue Exception => e
		File.unlink(tmp_file)

		raise "#{I18n.t('error.mpw_file.write_data')}\n#{e}"
	end

	# Get a password
	# args: id -> the item id
	def get_password(id)
		password = decrypt(@passwords[id])
		
		if /^\$[a-zA-Z0-9]{4,9}::(?<password>.+)$/ =~ password
			return Regexp.last_match('password')
		else
			return password
		end
	end

	# Set a password
	# args: id -> the item id
	#       password -> the new password
	def set_password(id, password)
		salt     = MPW::password(Random.rand(4..9))
		password = "$#{salt}::#{password}"

		@passwords[id] = encrypt(password)
	end

	# Add a public key
	# args: key ->  new public key
	#       file -> public gpg file to import
	def add_key(key, file=nil)
		if not file.nil? and File.exists?(file)
			data = File.open(file).read
			GPGME::Key.import(data, armor: true)
		else
			data = GPGME::Key.export(key, armor: true).read
		end

		if data.to_s.empty?
			raise I18n.t('error.export_key')
		end

		@keys[key] = data
	end

	# Delete a public key
	# args: key ->  public key to delete
	def delete_key(key)
		@keys.delete(key)
	end

	# TODO
	def check_config
		if false
			raise 'ERROR'
		end
	end

	# Add a new item
	# @args: item -> Object MPW::Item
	def add(item)
		if not item.instance_of?(Item)
			raise I18n.t('error.bad_class')
		elsif item.empty?
			raise I18n.t('error.add.empty')
		else
			@data.push(item)
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

	# Export to yaml
	# @args: file -> file where you export the data
	def export(file)
		data = {}
		@data.each do |item|
			data.merge!(item.id => {'id'        => item.id,
			                        'name'      => item.name,
			                        'group'     => item.group,
			                        'host'      => item.host,
			                        'protocol'  => item.protocol,
			                        'user'      => item.user,
			                        'password'  => get_password(item.id),
			                        'port'      => item.port,
			                        'comment'   => item.comment,
			                        'last_edit' => item.last_edit,
			                        'created'   => item.created,
			                       }
			            )
		end

		File.open(file, 'w') {|f| f << data.to_yaml}
	rescue Exception => e 
		raise "#{I18n.t('error.export.write', file: file)}\n#{e}"
	end

	# Import to yaml
	# @args: file -> path to file import
	# TODO raise
	def import(file)
		YAML::load_file(file).each_value do |row| 
			item = Item.new(name:     row['name'], 
			                group:    row['group'],
			                host:     row['host'],
			                protocol: row['protocol'],
			                user:     row['user'],
			                port:     row['port'],
			                comment:  row['comment'],
			               )

			raise 'Item is empty' if item.empty?

			@data.push(item)
			set_password(item.id, row['password'])
		end
	rescue Exception => e 
		raise "#{I18n.t('error.import.read', file: file)}\n#{e}"
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

	# Decrypt a gpg file
	# @args: data -> string to decrypt
	private
	def decrypt(data)
		crypto = GPGME::Crypto.new(armor: true)
		
		return crypto.decrypt(data, password: @gpg_pass).read.force_encoding('utf-8')
	rescue Exception => e 
		raise "#{I18n.t('error.gpg_file.decrypt')}\n#{e}"
	end

	# Encrypt a file
	# args: data -> string to encrypt
	private
	def encrypt(data)
		recipients = []
		crypto     = GPGME::Crypto.new(armor: true, always_trust: true)

		@keys.each_key do |key|
			recipients.push(key)
		end

		recipients.push(@key) if not recipients.index(@key).nil?

		return crypto.encrypt(data, recipients: recipients).read
	rescue Exception => e 
		raise "#{I18n.t('error.gpg_file.encrypt')}\n#{e}"
	end

end
end
