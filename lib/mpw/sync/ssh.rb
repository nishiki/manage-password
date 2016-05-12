#!/usr/bin/ruby
# author: nishiki
# mail: nishiki@yaegashi.fr

require 'i18n'
require 'net/ssh'
require 'net/sftp'
	
module MPW
class SyncSSH

	# Constructor
	# @args: config -> the config
	def initialize(config)
		@host      = config['host']
		@user      = config['user']
		@password  = config['password']
		@path      = config['path']
		@port      = config['port'].instance_of?(Integer) ? 22 : config['port']
	end

	# Connect to server
	# @rtrn: false if the connection fail
	def connect
		Net::SSH.start(@host, @user, password: @password, port: @port) do
			break
		end
	rescue Exception => e
		raise "#{I18n.t('error.sync.connection')}\n#{e}"
	end

	# Get data on server
	# @args: gpg_password -> the gpg password
	# @rtrn: nil if nothing data or error
	def get(file_tmp)
		Net::SFTP.start(@host, @user, password: @password, port: @port) do |sftp|
			sftp.lstat(@path) do |response|
				sftp.download!(@path, file_tmp) if response.ok?
			end
		end
	rescue Exception => e
		raise "#{I18n.t('error.sync.download')}\n#{e}"
	end

	# Update the remote data
	# @args: file_gpg -> the data to send on server
	# @rtrn: false if there is a problem
	def update(file_gpg)
		Net::SFTP.start(@host, @user, password: @password, port: @port) do |sftp|
			sftp.upload!(file_gpg, @path)
		end
	rescue Exception => e
		raise "#{I18n.t('error.sync.upload')}\n#{e}"
	end

end
end
