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
		
		class MPW
		
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
			def connect(host, port, gpg_key, password, suffix=nil)
				@gpg_key  = gpg_key
				@password = password
				@suffix   = suffix
		
				@socket = TCPSocket.new(host, port)
				@enable = true
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
		
				send_msg = {:action   => 'get',
				            :gpg_key  => @gpg_key,
				            :password => @password,
				            :suffix   => @suffix}
				
				@socket.puts send_msg.to_json
				msg = JSON.parse(@socket.gets)
		
				if !defined?(msg['error'])
					@error_msg = I18n.t('error.sync.communication')
					return nil
				elsif msg['error'].nil?
					tmp_file = "/tmp/mpw-#{MPW.password()}.gpg"
					File.open(tmp_file, 'w') do |file|
						file << msg['data']
					end
					
					@mpw = MPW.new(tmp_file)
					if !@mpw.decrypt(gpg_password)
						puts @mpw.error_msg
						return nil
					end
		
					File.unlink(tmp_file)
					return @mpw.search()
				else
					@error_msg = I18n.t(msg['error'])
					return nil
				end
		
			end
		
			# Update the remote data
			# @args: data -> the data to send on server
			# @rtrn: false if there is a problem
			def update(data)
				if !@enable
					return true
				end
		
				send_msg = {:action   => 'update',
				            :gpg_key  => @gpg_key,
				            :password => @password,
				            :suffix   => @suffix,
				            :data     => data}
				
				@socket.puts send_msg.to_json
				msg = JSON.parse(@socket.gets)
		
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
		
			# Close the connection
			def close
				if !@enable
					return
				end
		
				send_msg = {:action => 'close'}
				@socket.puts send_msg.to_json
			end
		end

	end

end
