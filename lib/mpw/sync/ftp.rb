#!/usr/bin/ruby
# author: nishiki
# mail: nishiki@yaegashi.fr

require 'i18n'
require 'net/ftp'
		
module MPW
class FTP

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
	def connect
		Net::FTP.open(@host) do |ftp|
			ftp.login(@user, @password)
			break
		end
	rescue Exception => e
		raise "#{I18n.t('error.sync.connection')}\n#{e}"
	end

	# Get data on server
	# @args: file_tmp -> the path where download the file
	def get(file_tmp)
		Net::FTP.open(@host) do |ftp|
			ftp.login(@user, @password)
			ftp.gettextfile(@path, file_tmp)
		end
	rescue Exception => e
		raise "#{I18n.t('error.sync.download')}\n#{e}"
	end

	# Update the remote data
	# @args: file_gpg -> the data to send on server
	def update(file_gpg)
		Net::FTP.open(@host) do |ftp|
			ftp.login(@user, @password)
			ftp.puttextfile(file_gpg, @path)
		end
	rescue Exception => e
		raise "#{I18n.t('error.sync.upload')}\n#{e}"
	end
end
end
