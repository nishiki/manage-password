#!/usr/bin/ruby
# author: nishiki
# mail: nishiki@yaegashi.fr
# info: a simple script who manage your passwords

require "#{APP_ROOT}/lib/Cli.rb"

class CliSSH < Cli

	attr_accessor :server, :port, :login

	# Connect to SSH
	# args: search -> string to search
	def ssh(search)
		result = @mpw.search(search, nil, 'ssh')

		if result.length > 0
			result.each do |r|
				@server.nil? ? (server = r[MPW::SERVER]) : (server = @server)
				@port.nil?   ? (port   = r[MPW::PORT])   : (port   = @port)
				@login.nil?  ? (login  = r[MPW::LOGIN])  : (login  = @login)

				passwd = r[MPW::PASSWORD]

				if port.nil? || port.empty?
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

