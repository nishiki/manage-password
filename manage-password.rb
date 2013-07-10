#!/usr/bin/ruby
require 'rubygems'
require 'gpgme'

FILE_GPG    = './pass.gpg'
KEY         = 'adrien.waksberg@believedigital.com'
FILE_PWD    = './tmp_passwd'
TIMEOUT_PWD = 10

class ManagePasswd
	
	ID      = 0
	TYPE    = 1
	SERVER  = 2
	LOGIN   = 3
	PASSWD  = 4
	PORT    = 5
	COMMENT = 6

	def initialize(key, file_gpg, file_pwd, timeout_pwd=300)
		@key = key
		@file_gpg = file_gpg
		@file_pwd = file_pwd
		@timeout_pwd = timeout_pwd

		if File.exist?(@file_gpg)
			self.decrypt()
		else
			@data = ""
		end
	end

	def decrypt()

		if File.exist?(@file_pwd) && File.stat(@file_pwd).mtime.to_i + @timeout_pwd < Time.now.to_i
			File.delete(@file_pwd)
		end

		begin
			passwd = IO.read(@file_pwd)
		rescue
			puts "Password GPG: "
			passwd = gets
			file_pwd = File.new(@file_pwd, 'w')
			file_pwd << passwd
			file_pwd.close
		end
		
		crypto = GPGME::Crypto.new(:armor => true)
		@data = crypto.decrypt(IO.read(@file_gpg), :password => passwd).read

	end

	def encrypt()
		crypto = GPGME::Crypto.new(:armor => true)
		crypto.encrypt(@data, :recipients => @key, :output => @file_gpg)
	end

end

manage = ManagePasswd.new(KEY, FILE_GPG, FILE_PWD)
