#!/usr/bin/ruby
# author: nishiki
# mail: nishiki@yaegashi.fr

require 'rubygems'
require 'i18n'
require 'yaml'
require 'tempfile'
require 'net/ssh'
require 'net/scp'
	
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
			Net::SSH.start(@host, @user, password: @password, port: @port) do
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
		def get(gpg_key, gpg_password)
			return nil if not @enable
			
			file_tmp = Tempfile.new('mpw')
			Net::SCP.start(@host, @user, password: @password, port: @port) do |scp|
				scp.download!(@path, file_tmp.path)
			end
		
			mpw = MPW.new(file_tmp, gpg_key)
			raise mpw.error_msg if not mpw.decrypt(gpg_password)
	
			file_tmp.close(true)

			return mpw.list
		rescue Exception => e
			@error_msg = "#{I18n.t('error.sync.download')}\n#{e}"
			file_tmp.close(true)
			return nil
		end
	
		# Update the remote data
		# @args: items -> the data to send on server
		# @rtrn: false if there is a problem
		def update(items)
			return true if not @enable
	
			file_tmp = Tempfile.new('mpw')

			mpw = MPW.new(file_tmp, gpg_key)
			items.each do |item|
				mpw.add(item)
			end

			raise(mpw.error_msg) if not mpw.encrypt

			Net::SCP.start(@host, @user, password: @password, port: @port) do |scp|
				scp.upload!(file_tmp, @path)
			end

			file_tmp.close(true)

			return true
		rescue Exception => e
			@error_msg = "#{I18n.t('error.sync.upload')}\n#{e}"
			file_tmp.close(true)
			return false
		end

	end
end
