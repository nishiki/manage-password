#!/usr/bin/ruby
# author: nishiki
# mail: nishiki@yaegashi.fr
# info: a simple script who manage your passwords

require 'rubygems'
require 'i18n'
require 'socket'
require 'json'

require "#{APP_ROOT}/lib/MPW.rb"

class Sync

	attr_accessor :error_msg

	# Constructor
	def initialize()
		@error_msg = nil
	end

	# Disable the sync
	def disable()
		@sync = false
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

		begin
			@socket= TCPSocket.new(host, port)
			@sync = true
		rescue Exception => e
			@error_msg = "#{I18n.t('error.sync.connection')}\n#{e}"
			@sync = false
		end

		return @sync
	end

	# Get data on server
	# @args: gpg_password -> the gpg password
	# @rtrn: nil if nothing data or error
	def get(gpg_password)
		if !@sync
			return nil
		end

		send_msg = {:action      => 'get',
		            :gpg_key     => @gpg_key,
		            :password    => @password,
		            :suffix      => @suffix}
		
		@socket.puts send_msg.to_json
		msg = JSON.parse(@socket.gets)

		puts msg
		case msg['error']
		when nil, 'file_not_exist'
			tmp_file = "/tmp/mpw-#{MPW.generatePassword()}.gpg"
			File.open(tmp_file, 'w') do |file|
				file << msg['data']
			end
			
			@mpw = MPW.new(tmp_file)
			if !@mpw.decrypt(gpg_password)
				return nil
			end

			File.unlink(tmp_file)
			
			return @mpw.search()
		when 'not_authorized'
			@error_msg = "#{I18n.t('error.sync.not_authorized')}\n#{e}"
		else
			@error_msg = "#{I18n.t('error.sync.unknown')}\n#{e}"
		end

		return nil
	end

	# Update the remote data
	# @args: data -> the data to send on server
	# @rtrn: false if there is a problem
	def update(data)
		if !@sync
			return true
		end

		send_msg = {:action      => 'update',
		            :gpg_key     => @gpg_key,
		            :password    => @password,
		            :suffix      => @suffix,
		            :data        => data}
		
		@socket.puts send_msg.to_json
		msg = JSON.parse(@socket.gets)

		case msg['error']
		when nil
			return true
		when 'not_authorized'
			@error_msg = "#{I18n.t('error.sync.not_authorized')}\n#{e}"
		when 'no_data'
			@error_msg = "#{I18n.t('error.sync.no_data')}\n#{e}"
		else
			@error_msg = "#{I18n.t('error.sync.unknown')}\n#{e}"
		end

		return false
	end

	def delete()
	end

	# Close the connection
	def close()
		if !@sync
			return
		end

		send_msg = {:action => 'close'}
		@socket.puts send_msg.to_json
	end
end
