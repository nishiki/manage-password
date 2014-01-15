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

	def initialize()
		@error_msg = nil
	end

	def disable()
		@sync = false
	end

	def connect(host, port, gpg_key, password, suffix=nil)
		@gpg_key     = gpg_key
		@password    = password
		@suffix      = suffix

		begin
			@socket= TCPSocket.new(host, port)
			@sync = true
		rescue Exception => e
			@error_msg = "ERROR: Connection impossible\n#{e}"
			@sync = false
		end

		return @sync
	end

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
			@error_msg = 'not authorized'
		else
			@error_msg = 'error unknow'
		end

		return nil
	end

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
			@error_msg = 'not authorized'
		when 'no_data'
			@error_msg = 'no data'
		else
			@error_msg = 'error unknow'
		end

		return false
	end

	def delete()
	end

	def close()
		if !@sync
			return
		end

		send_msg = {:action => 'close'}
		@socket.puts send_msg.to_json
	end
end
