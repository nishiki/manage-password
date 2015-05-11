#!/usr/bin/ruby
# author: nishiki
# mail: nishiki@yaegashi.fr
# info: a simple script who manage your passwords

require 'rubygems'
require 'i18n'
require 'yaml'
require 'tempfile'

require_relative './MPW'
require_relative './Item'
	
module MPW
	class Sync

		attr_accessor :error_msg

		# Constructor
		# raise an exception if there is a bad parameter
		def initialize(config, local, password=nil)
			@error_msg = nil
			@config    = config
			@local     = local
			@password  = password

			raise I18n.t('error.class') if not @local.instance_of?(MPW)
		end

		# Get the data on remote host
		# @rtrn: true if get the date, else false
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
				@sync = SyncFTP.new(@config.sync_host, @config.sync_user, @config.sync_pwd, @config.sync_path, @config.sync_port)
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
			@error_msg = "#{I18n.t('error.sync.download')} #{e}"
			file_tmp.close(true)
			return false
		end

		# Sync remote data and local data
		# raise an exception if there is a problem
		def sync
			
			if not @remote.to_s.empty?
				@local.list.each do |item|
					update = true
					@remote.list.each do |r|

						# Update item
						if item.id == r.id
							if item.last_edit < r.last_edit
								raise item.error_msg if not item.update(name:      r.name,
								                                        group:     r.group,
								                                        host:      r.host,
								                                        protocol:  r.protocol,
								                                        user:      r.user,
								                                        password:  r.password,
								                                        port:      r.port,
								                                        comment:   r.comment
								                                       )
							end

							r.delete
							update = true

							break
						end
					end

					# Remove an old item
					if not update and item.last_sync.to_i < @config.last_sync and item.last_edit < @config.last_sync
						item.delete
					end
				end
			end
	
			# Add item
			@remote.list.each do |r|
				if r.last_edit > @config.last_sync
					item = Item.new(id:        r.id,
					                name:      r.name,
					                group:     r.group,
					                host:      r.host,
					                protocol:  r.protocol,
					                user:      r.user,
					                password:  r.password,
					                port:      r.port,
					                comment:   r.comment,
					                created:   r.created,
					                last_edit: r.last_edit
					               )
					raise @local.error_msg if not @local.add(item)
				end
			end

			@local.list.each do |item|
				item.set_last_sync
			end

			raise @mpw.error_msg  if not @local.encrypt 
			raise @sync.error_msg if not @sync.update(@config.file_gpg)
			
			@config.set_last_sync

			return true
		rescue Exception => e
			@error_msg = "#{I18n.t('error.sync.unknown')} #{e}"
			return false
		end
	end
end
