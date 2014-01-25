#!/usr/bin/ruby

require 'socket'
require 'json'
require 'highline/import'
require 'digest'
require 'logger'

require "#{APP_ROOT}/lib/MPW.rb"

class Server
	
	INFO    = 0
	WARNING = 1
	ERROR   = 2
	DEBUG   = 3

	attr_accessor :error_msg

	# Constructor
	def initialize()
		YAML::ENGINE.yamler='syck'
	end

	# Start the server
	def start()
		begin
			server = TCPServer.open(@host, @port)
			@log.info("The server is started on #{@host}:#{@port}")
		rescue Exception => e
			@log.error("Impossible to start the server: #{e}")
			exit 2
		end

		loop do
			Thread.start(server.accept) do |client|
				@log.info("#{client.peeraddr[3]} is connected")

				while true do
					msg = getClientMessage(client)

					if !msg
						next
					end
					
					if msg['gpg_key'].nil? || msg['gpg_key'].empty? || msg['password'].nil? || msg['password'].empty?
						closeConnection(client)
						next
					end

					case msg['action']
					when 'get'
						@log.debug("#{client.peeraddr[3]} GET gpg_key=#{msg['gpg_key']} suffix=#{msg['suffix']}")
						client.puts getFile(msg)
					when 'update'
						@log.debug("#{client.peeraddr[3]} UPDATE gpg_key=#{msg['gpg_key']} suffix=#{msg['suffix']}")
						client.puts updateFile(msg)
					when 'delete'
						@log.debug("#{client.peeraddr[3]} DELETE gpg_key=#{msg['gpg_key']} suffix=#{msg['suffix']}")
						client.puts deleteFile(msg)
					when 'close'
						@log.info("#{client.peeraddr[3]} is disconnected")
						closeConnection(client)
					else
						@log.warning("#{client.peeraddr[3]} is disconnected for unkwnow command")
						send_msg = {:action      => 'unknown',
						            :gpg_key     => msg['gpg_key'],
						            :error       => 'server.error.client.unknown'}
						client.puts send_msg 
						closeConnection(client)
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

			if isAuthorized?(msg['password'], salt, hash)
				send_msg = {:action      => 'get',
				            :gpg_key     => msg['gpg_key'],
				            :data        => data,
				            :error       => nil}
			else
				send_msg = {:action  => 'get',
				            :gpg_key => msg['gpg_key'],
				            :error   => 'server.error.client.no_authorized'}
			end
		else
			send_msg = {:action  => 'get',
			            :gpg_key => msg['gpg_key'],
			            :data    => '',
			            :error   => nil}
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
			            :error   => 'server.error.client.no_data'}
			
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

		if isAuthorized?(msg['password'], salt, hash)
			begin
				config = {'gpg' => {'salt'        => salt,
				                    'hash'        => hash,
				                    'data'        => data}}

				File.open(file_gpg, 'w+') do |file|
					file << config.to_yaml
				end

				send_msg = {:action  => 'update',
				            :gpg_key => msg['gpg_key'],
				            :error   => nil}
			rescue Exception => e
				send_msg = {:action  => 'update',
				            :gpg_key => msg['gpg_key'],
				            :error   => 'server.error.client.unknown'}
			end
		else
			send_msg = {:action  => 'update',
			            :gpg_key => msg['gpg_key'],
			            :error   => 'server.error.client.no_authorized'}
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
			            :error   => nil}

			return send_msg.to_json
		end

		gpg_data  = YAML::load_file(file_gpg)
		salt      = gpg_data['gpg']['salt']
		hash      = gpg_data['gpg']['hash']

		if isAuthorized?(msg['password'], salt, hash)
			begin
				File.unlink(file_gpg)

				send_msg = {:action  => 'delete',
				            :gpg_key => msg['gpg_key'],
				            :error   => nil}
			rescue Exception => e
				send_msg = {:action  => 'delete',
				            :gpg_key => msg['gpg_key'],
				            :error   => 'server.error.client.unknown'}
			end
		else
			send_msg = {:action  => 'delete',
			            :gpg_key => msg['gpg_key'],
			            :error   => 'server.error.client.no_authorized'}
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
			closeConnection(client)
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
			@log_file = config['config']['log_file']
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

			if @log_file.nil? || @log_file.empty?
				puts I18n.t('server.checkconfig.fail')
				puts I18n.t('server.checkconfig.log_file_empty')
				return false
			#elsif !File.writable?(@log_file)
			#	puts I18n.t('server.checkconfig.fail')
			#	puts I18n.t('server.checkconfig.log_file_ro')
			#	return false
			else
				begin
					@log = Logger.new(@log_file)
				rescue
					puts I18n.t('server.checkconfig.fail')
					puts I18n.t('server.checkconfig.log_file_create')
					return false
				end
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
		log_file = ask(I18n.t('server.form.setup.log_file')).to_s
		timeout  = ask(I18n.t('server.form.setup.timeout')).to_s

		config = {'config' => {'host'     => host,
		                       'port'     => port,
		                       'data_dir' => data_dir,
		                       'log_file' => log_file,
		                       'timeout'  => timeout}}

		begin
			File.open(file_config, 'w') do |file|
				file << config.to_yaml
			end
		rescue Exception => e 
			puts "#{I18n.t('server.form.setup.not_valid')}\n#{e}"
			return false
		end

		return true
	end
end
