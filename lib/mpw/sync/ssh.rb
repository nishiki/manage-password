#!/usr/bin/ruby
# MPW is a software to crypt and manage your passwords
# Copyright (C) 2016  Adrien Waksberg <mpw@yae.im>
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

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
	def connect
		Net::SSH.start(@host, @user, password: @password, port: @port) do
			break
		end
	rescue Exception => e
		raise "#{I18n.t('error.sync.connection')}\n#{e}"
	end

	# Get data on server
	# @args: file_tmp -> the path where download the file
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
	def update(file_gpg)
		Net::SFTP.start(@host, @user, password: @password, port: @port) do |sftp|
			sftp.upload!(file_gpg, @path)
		end
	rescue Exception => e
		raise "#{I18n.t('error.sync.upload')}\n#{e}"
	end
end
end
