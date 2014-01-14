#!/usr/bin/ruby

require 'socket'
require 'json'
require 'highline/import'
require 'digest'

require "#{APP_ROOT}/lib/MPW.rb"

class Server
	
	attr_accessor :error_msg

	# Constructor
	def initialize()
		YAML::ENGINE.yamler='syck'
	end

	# Start the server
	def start()
		server = TCPServer.open(@host, @port)
		loop do
			Thread.start(server.accept) do |client|
				while true do
					msg = self.getClientMessage(client)

					if !msg
						next
					end
					
					if msg['gpg_key'].nil? || msg['gpg_key'].empty? || msg['password'].nil? || msg['password'].empty?
						self.closeConnection(client)
						next
					end

					case msg['action']
					when 'get'
						client.puts self.getFile(msg)
					when 'update'
						client.puts self.updateFile(msg)
					when 'delete'
						client.puts self.deleteFile(msg)
					when 'close'
						self.closeConnection(client)
					else
						client.puts 'Unknown command'
						self.closeConnection(client)
					end
				end
			end
		end
	end

	# Get a gpg file
	# @args: msg -> message puts by the client
	# @rtrn: json message
	def getFile(msg)
		gpg_key = msg['gpg_key'].sub('@', '_')

		if msg['suffix'].nil? || msg['suffix'].empty?
			file_gpg = "#{@data_dir}/#{gpg_key}.yml"
		else
			file_gpg = "#{@data_dir}/#{gpg_key}-#{msg['suffix']}.yml"
		end

		if File.exist?(file_gpg)
			gpg_data    = YAML::load_file(file_gpg)
			salt        = gpg_data['gpg']['salt']
			hash        = gpg_data['gpg']['hash']
			data        = gpg_data['gpg']['data']
			last_update = gpg_data['gpg']['last_update']

			if self.isAuthorized?(msg['password'], salt, hash)
				send_msg = {:action      => 'get',
				            :gpg_key     => msg['gpg_key'],
				            :last_update => last_update,
				            :msg         => 'done',
				            :data        => data}
			else
				send_msg = {:action  => 'get',
				            :gpg_key => msg['gpg_key'],
				            :msg     => 'fail',
				            :error   => 'not_authorized'}
			end
		else
			send_msg = {:action      => 'get',
			            :gpg_key     => msg['gpg_key'],
			            :last_update => 0,
			            :data        => '',
			            :msg         => 'fail',
			            :error       => 'file_not_exist'}
		end

		return send_msg.to_json
	end

	# Update a file
	# @args: msg -> message puts by the client
	# @rtrn: json message
	def updateFile(msg)
		gpg_key = msg['gpg_key'].sub('@', '_')
		data    = msg['data']

		if data.nil? || data.empty?
			send_msg = {:action  => 'update',
			            :gpg_key => msg['gpg_key'],
			            :msg     => 'fail',
			            :error   => 'no_data'}
			
			return send_msg.to_json
		end

		if msg['suffix'].nil? || msg['suffix'].empty?
			file_gpg = "#{@data_dir}/#{gpg_key}.yml"
		else
			file_gpg = "#{@data_dir}/#{gpg_key}-#{msg['suffix']}.yml"
		end

		if File.exist?(file_gpg)
			gpg_data  = YAML::load_file(file_gpg)
			salt      = gpg_data['gpg']['salt']
			hash      = gpg_data['gpg']['hash']

		else
			salt = MPW.generatePassword(4)
			hash = Digest::SHA256.hexdigest(salt + msg['password'])
		end

		if self.isAuthorized?(msg['password'], salt, hash)
			begin
				last_update = Time.now.to_i
				config = {'gpg' => {'salt'        => salt,
				                    'hash'        => hash,
				                    'last_update' => last_update,
				                    'data'        => data}}

				File.open(file_gpg, 'w+') do |file|
					file << config.to_yaml
				end

				send_msg = {:action      => 'update',
				            :gpg_key     => msg['gpg_key'],
				            :last_update => last_update,
				            :msg         => 'done'}
			rescue Exception => e
				send_msg = {:action  => 'update',
				            :gpg_key => msg['gpg_key'],
				            :msg     => 'fail',
				            :error   => 'server_error'}
			end
		else
			send_msg = {:action  => 'update',
			            :gpg_key => msg['gpg_key'],
			            :msg     => 'fail',
			            :error   => 'not_autorized'}
		end
		
		return send_msg.to_json
	end

	# Remove a gpg file
	# @args: msg -> message puts by the client
	# @rtrn: json message
	def deleteFile(msg)
		gpg_key = msg['gpg_key'].sub('@', '_')

		if msg['suffix'].nil? || msg['suffix'].empty?
			file_gpg = "#{@data_dir}/#{gpg_key}.yml"
		else
			file_gpg = "#{@data_dir}/#{gpg_key}-#{msg['suffix']}.yml"
		end

		if !File.exist?(file_gpg)
			send_msg = {:action  => 'delete',
			            :gpg_key => msg['gpg_key'],
			            :msg     => 'delete_fail',
			            :error   => 'file_not_exist'}

			return send_msg.to_json
		end

		gpg_data  = YAML::load_file(file_gpg)
		salt      = gpg_data['gpg']['salt']
		hash      = gpg_data['gpg']['hash']

		if self.isAuthorized?(msg['password'], salt, hash)
			begin
				File.unlink(file_gpg)

				send_msg = {:action  => 'delete',
				            :gpg_key => msg['gpg_key'],
				            :msg    => 'delete_done'}
			rescue Exception => e
				send_msg = {:action  => 'delete',
				            :gpg_key => msg['gpg_key'],
				            :msg     => 'delete_fail',
				            :error   => e}
			end
		else
			send_msg = {:action  => 'delete',
			            :gpg_key => msg['gpg_key'],
			            :msg     => 'delete_fail',
			            :error   => 'not_autorized'}
		end
		
		return send_msg.to_json
	end

	# Check is the hash equal the password with the salt
	# @args: password -> the user password
	#        salt -> the salt
	#        hash -> the hash of the password with the salt
	# @rtrn: true is is good, else false
	def isAuthorized?(password, salt, hash)
		if hash == Digest::SHA256.hexdigest(salt + password)
			return true
		else
			return false
		end
	end

	# Get message to client
	# @args: client -> client connection
	# @rtrn: array of the json string, or false if isn't json message
	def getClientMessage(client)
		begin
			msg = client.gets
			return JSON.parse(msg)
		rescue
			client.puts "Communication it's bad"
			self.closeConnection(client)
			return false
		end
	end

	# Close the client connection
	# @args: client -> client connection
	def closeConnection(client)
			client.puts "Closing the connection. Bye!"
			client.close
	end

	# Check the config file
	# @args: file_config -> the configuration file
	# @rtrn: true if the config file is correct
	def checkconfig(file_config)
		begin
			config    = YAML::load_file(file_config)
			@host     = config['config']['host']
			@port     = config['config']['port'].to_i
			@data_dir = config['config']['data_dir']
			@timeout  = config['config']['timeout'].to_i

			if @host.empty? || @port <= 0 || @data_dir.empty? 
				puts I18n.t('server.checkconfig.fail')
				puts I18n.t('server.checkconfig.empty')
				return false
			end

			if !Dir.exist?(@data_dir)
				puts I18n.t('server.checkconfig.fail')
				puts I18n.t('server.checkconfig.datadir')
				return false
			end

		rescue Exception => e 
			puts "#{I18n.t('server.checkconfig.fail')}\n#{e}"
			return false
		end

		return true
	end

	# Create a new config file
	# @args: file_config -> the configuration file
	# @rtrn: true if le config file is create
	def setup(file_config)
		puts I18n.t('server.form.setup.title')
		puts '--------------------'
		host     = ask(I18n.t('server.form.setup.host')).to_s
		port     = ask(I18n.t('server.form.setup.port')).to_s
		data_dir = ask(I18n.t('server.form.setup.data_dir')).to_s
		timeout  = ask(I18n.t('server.form.setup.timeout')).to_s

		config = {'config' => {'host'     => host,
		                       'port'     => port,
		                       'data_dir' => data_dir,
		                       'timeout'  => timeout}}

		begin
			File.open(file_config, 'w') do |file|
				file << config.to_yaml
			end
		rescue Exception => e 
			puts "#{I18n.t('server.formsetup.not_valid')}\n#{e}"
			return false
		end

		return true
	end

end
