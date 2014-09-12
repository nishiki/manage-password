#!/usr/bin/ruby
# author: nishiki
# mail: nishiki@yaegashi.fr
# info: a simple script who manage your passwords

module MPW

	module Sync

		require 'rubygems'
		require 'i18n'
		require 'socket'
		require 'json'
		require 'timeout'
		
		class MPWSync
		
			attr_accessor :error_msg
			attr_accessor :enable
		
			# Constructor
			def initialize
				@error_msg = nil
				@enable    = false
			end
		
			# Connect to server
			# @args: host -> the server host
			#        port -> ther connection port
			#        gpg_key -> the gpg key
			#        password -> the remote password
			#        suffix -> the suffix file
			# @rtrn: false if the connection fail
			def connect(host, user, password, path, port=nil)
				@host     = host
				@port     = !port.instance_of?(Integer) ? 2201 : port
				@gpg_key  = user
				@password = password
				@suffix   = path
		
				Timeout.timeout(10) do
					begin
						TCPSocket.open(@host, @port) do 
							@enable = true
						end
                    rescue Errno::ENETUNREACH
							retry
					end
				end
			rescue Timeout::Error
				puts 'timeout'
				@error_msg = "#{I18n.t('error.timeout')}\n#{e}"
				@enable    = false
			rescue Exception => e
				@error_msg = "#{I18n.t('error.sync.connection')}\n#{e}"
				@enable    = false
			else
				return @enable
			end
		
			# Get data on server
			# @args: gpg_password -> the gpg password
			# @rtrn: nil if nothing data or error
			def get(gpg_password)
				if !@enable
					return nil
				end
				
				msg = nil
				TCPSocket.open(@host, @port) do |socket|
					send_msg = {action:  'get',
					            gpg_key:  @gpg_key,
					            password: @password,
					            suffix:   @suffix
					           }
					
					socket.puts send_msg.to_json
					msg = JSON.parse(socket.gets)
				end

				if !defined?(msg['error'])
					@error_msg = I18n.t('error.sync.communication')
					return nil
				elsif !msg['error'].nil?
					@error_msg = I18n.t(msg['error'])
					return nil
				elsif msg['data'].nil? || msg['data'].empty?
					return []
				else
					tmp_file = tmpfile
					File.open(tmp_file, 'w') do |file|
						file << msg['data']
					end
					
					mpw = MPW.new(tmp_file)
					if !mpw.decrypt(gpg_password)
						@error_msg = mpw.error_msg
						return nil
					end
					
					File.unlink(tmp_file)
					return mpw.search
				end
			end
		
			# Update the remote data
			# @args: data -> the data to send on server
			# @rtrn: false if there is a problem
			def update(data)
				if !@enable
					return true
				end
		
				msg = nil
				TCPSocket.open(@host, @port) do |socket|
					send_msg = {action:   'update',
					            gpg_key:  @gpg_key,
					            password: @password,
					            suffix:   @suffix,
					            data:     data
					           }
					
					socket.puts send_msg.to_json
					msg = JSON.parse(socket.gets)
				end
		
				if !defined?(msg['error'])
					@error_msg = I18n.t('error.sync.communication')
					return false
				elsif msg['error'].nil?
					return true
				else
					@error_msg = I18n.t(msg['error'])
					return false
				end
			end
		
			# Generate a random string
			# @rtrn: a random string
			def tmpfile
				result = ''
				result << ([*('A'..'Z'),*('a'..'z'),*('0'..'9')]).sample(6).join
		
				return "/tmp/mpw-#{result}"
			end
	
		end

	end

end
