#!/usr/bin/ruby
# author: nishiki
# mail: nishiki@yaegashi.fr
# info: a simple script who manage your passwords

require 'rubygems'
require 'i18n'
require 'yaml'
require 'tempfile'
require "#{APP_ROOT}/lib/Item"
require "#{APP_ROOT}/lib/MPW"
	
module MPW
	class Sync

		attr_accessor :error_msg

		def initialize(config, local, password=nil)
			@error_msg = nil
			@config    = config
			@local     = local
			@password  = password

			raise I18n.t('error.class') if not @local.instance_of?(MPW)
		end

		def get_remote
			case @config.sync_type
			when 'mpw'
				require "#{APP_ROOT}/lib/Sync/SyncMPW"
				@sync = SyncMPW.new(@config.sync_host, @config.sync_user, @config.sync_pwd, @config.sync_path, @config.sync_port)
			when 'sftp', 'scp', 'ssh'
				require "#{APP_ROOT}/lib/Sync/SSH"
				@sync = SyncSSH.new(@config.sync_host, @config.sync_user, @config.sync_pwd, @config.sync_path, @config.sync_port)
			when 'ftp'
				require "#{APP_ROOT}/lib/Sync/FTP"
				@sync = SyncFTP.new
			else
				@error_msg =  I18n.t('error.unknown_type')
				return false
			end

			if not @sync.connect
				@error_msg = @sync.error_msg
				return false
			end

			
			file_tmp = Tempfile.new('mpw-')
			raise @sync.error_msg if not @sync.get(file_tmp.path)	

			@remote = MPW.new(file_tmp.path, @config.key)
			raise @remote.error_msg if not @remote.decrypt(@password)

			file_tmp.close(true)
			return true
		rescue Exception => e
			@error_msg = "#{I18n.t('error.sync')} #{e}"
			file_tmp.close(true)
			return false
		end

		# Sync remote data and local data
		# @args: data_remote -> array with the data remote
		#        last_update -> last update
		# @rtrn: false if data_remote is nil
		def sync
			if not @remote.to_s.empty?
				@local.list.each do |item|
					j      = 0
					update = false
		
					# Update item
					@remote.list.each do |r|
						if item.id == r.id
							if item.last_edit < r.last_edit
								raise item.error_msg if not item.update(r.name, r.group, r.host, r.protocol, r.user, r.password, r.port, r.comment)
							end

							update = true
							data_remote.delete(j)

							break
						end

						j += 1
					end
		
					# Delete an old item
					if not update and item.last_edit < @config.last_update
						item.delete
					end
				end
			end
	
			# Add item
			@remote.list.each do |r|
				if r.last_edit > @config.last_update
					item = Item.new(r.name, r.group, r.host, r.protocol, r.user, r.password, r.port, r.comment)
					raise @local.error_msg if not @local.add(item)
				end
			end
	
			raise @sync.error_msg if not @sync.update(@config.file_gpg)
			raise @mpw.error_msg  if not @local.encrypt 

			return true
		rescue Exception => e
			@error_msg = "#{I18n.t('error.sync')} #{e}"
			return false
		end
	end
end
