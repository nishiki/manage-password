#!/usr/bin/ruby
# author: nishiki
# mail: nishiki@yaegashi.fr
# info: a simple script who manage your passwords

module MPW

	module Sync

		require 'rubygems'
		require 'i18n'
		
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
			def connect(host, user, password, path, port=nil)
				@host     = host
				@user     = user
				@password = password
				@path     = path
				@port     = port.nil? || port.empty? ? 22 : port.to_i
					
				Net::SSH.start(@host, @user, :password => @password, :port => @port) do
				end
			rescue
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
				
				tmp_file = "/tmp/mpw-#{MPW.password()}.gpg"
				Net::SCP.start(@host, @user, :password => @password, :port => @port) do |ssh|
					ssh.scp.download(@path, tmp_file)
				end
			
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
		
				tmp_file = "/tmp/mpw-#{MPW.password()}.gpg"
				Net::SCP.start(@host, @user, :password => @password, :port => @port) do |ssh|
					ssh.scp.upload(tmp_file, @path)
				end

				File.unlink(tmp_file)

				return true
			rescue Exception => e
				@error_msg = "#{I18n.t('error.sync.upload')}\n#{e}"
				return false
			end
		
			# Close the connection
			def close
			end
		end

	end

end
