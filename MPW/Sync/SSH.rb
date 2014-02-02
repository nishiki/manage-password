#!/usr/bin/ruby
# author: nishiki
# mail: nishiki@yaegashi.fr
# info: a simple script who manage your passwords

module MPW

	module Sync

		require 'rubygems'
		require 'i18n'
		require 'net/ssh'
		require 'net/scp'
		
		class SSH
		
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
				@user     = user
				@password = password
				@path     = path
				@port     = port.instance_of?(Integer) ? 22 : port
					
				Net::SSH.start(@host, @user, :password => @password, :port => @port) do
					@enable = true
				end
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
				
				tmp_file = tmpfile
				Net::SCP.start(@host, @user, :password => @password, :port => @port) do |scp|
					scp.download!(@path, tmp_file)
				end
			
				mpw = MPW.new(tmp_file)
				if !mpw.decrypt(gpg_password)
					@error_msg = mpw.error_msg
					return nil
				end
		
				File.unlink(tmp_file)
				return mpw.search
			rescue Exception => e
				@error_msg = "#{I18n.t('error.sync.download')}\n#{e}"
				return nil
			end
		
			# Update the remote data
			# @args: data -> the data to send on server
			# @rtrn: false if there is a problem
			def update(data)
				if !@enable
					return true
				end
		
				tmp_file = tmpfile
				File.open(tmp_file, "w") do |file|
					file << data
				end

				Net::SCP.start(@host, @user, :password => @password, :port => @port) do |scp|
					scp.upload!(tmp_file, @path)
				end

				File.unlink(tmp_file)

				return true
			rescue Exception => e
				@error_msg = "#{I18n.t('error.sync.upload')}\n#{e}"
				return false
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
