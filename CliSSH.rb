#!/usr/bin/ruby
# author: nishiki
# mail: nishiki@yaegashi.fr
# info: a simple script who manage your passwords

require 'net/ssh'
require "#{APP_ROOT}/Cli.rb"

class CliSSH < Cli

	def ssh(search)
		result = @m.search(search, 'ssh')

		if result.length > 0
			result.each do |r|
				server = r[MPW::SERVER]
				login  = r[MPW::LOGIN]
				port   = r[MPW::PORT]
				passwd = r[MPW::PASSWORD]

				if port.empty?
					port = 22
				end

				if passwd.empty?
					system("#{passwd} ssh #{login}@#{server} -p #{port}")
				else
					system("sshpass -p #{passwd} ssh #{login}@#{server} -p #{port}")
				end
			end

		else
			puts "Nothing result!"
		end
	end
end

