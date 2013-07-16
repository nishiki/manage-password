#!/usr/bin/ruby
# author: nishiki
# mail: nishiki@yaegashi.fr
# info: a simple script who manage your passwords

require 'rubygems'
require 'highline/import'
require 'yaml'

class Cli

	attr_accessor :key
	attr_accessor :file_gpg
	attr_accessor :file_pwd
	attr_accessor :timeout_pwd

	def initialize()
		@file_config = "#{Dir.home()}/.mpw.cfg"

		if !File.exist?(@file_config) || !self.checkconfig()
			self.setup()
			if not self.checkconfig()
				puts "Error during the checkconfig post setup!"
				exit 2
			end
		end
	end

	# Create a new config file
	def setup()
		key         = ask("Enter the GPG key: ")
		file_gpg    = ask("Enter the path to encrypt file [default=#{Dir.home()}/.mpw.gpg]: ")
		file_pwd    = ask("Enter te path to password file [default=#{Dir.home()}/.mpw.pwd]: ")
		timeout_pwd = ask("Enter the timeout (in seconde) to GPG password [default=300]: ")

		if not key =~ /[a-zA-Z0-9.-_]*\@[a-zA-Z0-9]*\.[a-zA-Z]*/
			puts "GPG key is invalid!"
			exit 2
		end
		
		if file_gpg.empty?
			file_gpg = "#{Dir.home()}/.mpw.gpg"
		end

		if file_pwd.empty?
			file_pwd = "#{Dir.home()}/.mpw.pwd"
		end

		timeout_pwd.empty? ? (timeout_pwd = 300) : (timeout_pwd = timeout_pwd.to_i)

		config = {'config' => {'key'         => key,
		                       'file_gpg'    => file_gpg,
		                       'timeout_pwd' => timeout_pwd,
		                       'file_pwd'    => file_pwd}}
		
		File.open(@file_config, 'w') do |file|
			file << config.to_yaml
		end
	end

	# Check the config file
	# @rtrn: true if the config file is correct
	def checkconfig()
		begin
			config = YAML::load_file(@file_config)
			@key         = config['config']['key']
			@file_gpg    = config['config']['file_gpg']
			@file_pwd    = config['config']['file_pwd']
			@timeout_pwd = config['config']['timeout_pwd'].to_i

			if @key.empty? || @file_gpg.empty? || @file_pwd.empty? 
				return false
			end

		rescue
			return false
		end

		return true
	end
end
