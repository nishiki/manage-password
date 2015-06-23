#!/usr/bin/ruby
# author: nishiki
# mail: nishiki@yaegashi.fr
# info: a simple script who manage your passwords

require 'mpw/ui/cli'

class CliSSH < Cli

	attr_accessor :server, :port, :login

	# Connect to SSH
	# args: search -> string to search
	def ssh(search)
		result = @mpw.list(search: search, protocol: 'ssh')

		if result.length > 0
			result.each do |item|
				server = @server.nil? ? item.host : @server
				port   = @port.nil?   ? item.port : @port
				login  = @login.nil?  ? item.user : @login

				passwd = item.password

				if port.nil? and port.empty?
					port = 22
				end

				puts "#{I18n.t('ssh.display.connect')} ssh #{login}@#{server} -p #{port}"
				if passwd.empty?
					system("ssh #{login}@#{server} -p #{port}")
				else
					system("sshpass -p '#{passwd}' ssh #{login}@#{server} -p #{port}")
				end
			end

		else
			puts I18n.t('ssh.display.nothing')
		end
	end
end

