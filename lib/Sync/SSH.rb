#!/usr/bin/ruby
# author: nishiki
# mail: nishiki@yaegashi.fr

require 'rubygems'
require 'i18n'
require 'net/ssh'
require 'net/sftp'
	
module MPW
	class SyncSSH
	
		attr_accessor :error_msg
		attr_accessor :enable
	
		# Constructor
		# @args: host -> the server host
		#        port -> ther connection port
		#        gpg_key -> the gpg key
		#        password -> the remote password
		def initialize(host, user, password, path, port=nil)
			@error_msg = nil
			@enable    = false

			@host      = host
			@user      = user
			@password  = password
			@path      = path
			@port      = port.instance_of?(Integer) ? 22 : port
		end
	
		# Connect to server
		# @rtrn: false if the connection fail
		def connect
			Net::SSH.start(@host, @user, password: @password, port: @port) do |ssh|
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
		def get(file_tmp)
			return false if not @enable
			
			Net::SFTP.start(@host, @user, password: @password, port: @port) do |sftp|
				sftp.lstat(@path) do |response|
					sftp.download!(@path, file_tmp) if response.ok?
				end
			end

			return true
		rescue Exception => e
			@error_msg = "#{I18n.t('error.sync.download')}\n#{e}"
			return false
		end
	
		# Update the remote data
		# @args: file_gpg -> the data to send on server
		# @rtrn: false if there is a problem
		def update(file_gpg)
			return true if not @enable
	
			Net::SFTP.start(@host, @user, password: @password, port: @port) do |sftp|
				sftp.upload!(file_gpg, @path)
			end

			return true
		rescue Exception => e
			@error_msg = "#{I18n.t('error.sync.upload')}\n#{e}"
			return false
		end

	end
end
