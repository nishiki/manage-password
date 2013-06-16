#!/usr/bin/python
# author: nishiki
# mail: nishiki@yaegashi.fr
# date: 16/06/2013
# info: a simple script who manage your passwords

import csv
import re
import os
import sys
import gnupg
import getpass 
import StringIO
import tempfile
import time
import datetime

FILE_GPG    = '/home/nishiki/.password-manager'
KEY         = 'nishiki@yaegashi.fr'
FILE_PWD    = '/tmp/.tmp_passwd'
TIMEOUT_PWD = 300


class ManagePasswd:

	ID      = 0
	TYPE    = 1
	SERVER  = 2
	LOGIN   = 3
	PASSWD  = 4
	PORT    = 5
	COMMENT = 6


	def __init__(self, key, file_gpg, file_pwd, timeout_pwd=300):
		self.KEY         = key
		self.FILE_PWD    = file_pwd
		self.FILE_GPG    = file_gpg
		self.TIMEOUT_PWD = timeout_pwd

		if os.path.isfile(self.FILE_GPG):
			self.decrypt()
		else:
			self.data = ''
		
	def __del__(self):
		try: 
			self.file_tmp_name
		except:
			self.file_tmp_name = ''

		if os.path.isfile(self.file_tmp_name):
			os.remove(self.file_tmp_name)
		
	# Decrypt a gpg file
	# @rtrn: true if data is decrypted
	def decrypt(self):
		gpg = gnupg.GPG(verbose=False)

		# Manage the passphrase
		if os.path.isfile(self.FILE_PWD):
			stat_file = os.stat(self.FILE_PWD)
			if stat_file.st_mtime + self.TIMEOUT_PWD < time.time():
				open(self.FILE_PWD, 'w').close()
		else:
			open(self.FILE_PWD, 'w').close()

		file_pwd = open(self.FILE_PWD, 'r+')
		os.chmod(self.FILE_PWD, 0600)
		passwd  = file_pwd.readline()
		if not passwd:
			passwd = getpass.getpass('Password GPG: ')
			self.FILE_PWD.write(passwd)

		file_pwd.close()

		file_gpg = open(self.FILE_GPG, 'rb')
		self.data = gpg.decrypt_file(file_gpg, passphrase=passwd)
		file_gpg.close()

		if not self.data.ok:
			print 'Error: Your passphrase is probably wrong!'
			os.remove(self.FILE_PWD)
			return False
		else:
			os.utime(self.FILE_PWD, None)
			return True

	# Encrypt a file
	def encrypt(self):
		if os.path.isfile(self.file_tmp_name):
			self.file_tmp.close()
			os.system('gpg -r ' + self.KEY + ' --yes --output ' + self.FILE_GPG + ' --encrypt ' + self.file_tmp_name)
			return True
		else:
			return False

	# Search in some csv data
	# @args: search -> the string to search
	#        type -> the connection type (ssh, web, other)
	# @rtrn: a list with the resultat of the search
	def search(self, search, type=''):
		result = list()
		regex = re.compile('^.*' + search + '.*$')
		regex_type = re.compile('^' + type + '$')

		file_csv = StringIO.StringIO(self.data)
		reader = csv.reader(file_csv, delimiter=';', quotechar='|')
		for row in reader:
			if regex.match(row[self.SERVER]) or regex.match(row[self.COMMENT]):
				if type == '':
					result.append(row)
				else:
					if regex_type.match(row[self.TYPE]):
						result.append(row)
		file_csv.close()
		
		return result

	# Connect to ssh and display the password
	# @args: search -> 
	def ssh(self, search):
		result = self.search(search, 'ssh')
		num = len(result)
		if num > 0:
			for i in range(num): 
				server = result[i][self.SERVER]
				login  = result[i][self.LOGIN]
				port   = result[i][self.PORT]
				passwd = result[i][self.PASSWD]
				if passwd:
					os.system('sshpass -p ' + passwd + ' ssh ' + login + '@' + server + ' -p ' + str(port))
				else:
					os.system('ssh ' + login + '@' + server + ' -p ' + str(port))
		else:
			print 'No result!'


	# Display the connections informations for a server
	def display(self, search, type=''):
		result = self.search(search, type)
		num = len(result)
		if num > 0:
			for i in range(num): 
				print '# --------------------'
				print '# Id: '       + result[i][self.ID]
				print '# Server: '   + result[i][self.SERVER]
				print '# Type: '     + result[i][self.TYPE]
				print '# Login: '    + result[i][self.LOGIN]
				print '# Password: ' + result[i][self.PASSWD]
				print '# Port: '     + result[i][self.PORT]
				print '# Comment: '  + result[i][self.COMMENT]
		else:
			print 'No result!'


	# Display help
	def help(self):
		print '# HELP'
		print '# --------------------'
		print 'Add a new item: -a'
		print 'Remove an item: -r ID'
		print 'Show a item: -d search [type]'
		print 'Connect ssh: -s search'
		

	# Add a new item
	def add(self):
		print '# Add a new password'
		print '# --------------------'
		id      = hex(int(time.time()))
		server  = raw_input('Enter the server name or ip: ')
		type    = raw_input('Enter the type of connection (ssh, web, other): ')
		login   = raw_input('Enter the login connection: ')
		passwd  = raw_input('Enter the the password: ')
		port    = raw_input('Enter the connection port (optinal): ')
		comment = raw_input('Enter a comment (optinal): ')
		
		self.generateTmpFile()
		writer = csv.writer(self.file_tmp, delimiter=';', quotechar='|')
		file_csv = StringIO.StringIO(self.data)
		reader = csv.reader(file_csv, delimiter=';', quotechar='|')
		for row in reader:
			writer.writerow(row)
		file_csv.close()
		writer.writerow([id, type, server, login, passwd, port, comment])
		print 'Item has been added!'

	# Remove a item item
	# @args: id -> the unique identifiant
	def remove(self, id):
		self.generateTmpFile()
		writer = csv.writer(self.file_tmp, delimiter=';', quotechar='|')
		file_csv = StringIO.StringIO(self.data)
		reader = csv.reader(file_csv, delimiter=';', quotechar='|')
		for row in reader:
			if row[self.ID] != id:
				writer.writerow(row)
			else:
				print 'The item has been removed!'
		file_csv.close()

	def generateTmpFile(self):
		try:
			self.file_tmp_name
		except:
			self.file_tmp_name = ''

		if not os.path.isfile(self.file_tmp_name):
			(file_tmp_fd, self.file_tmp_name) = tempfile.mkstemp()
			self.file_tmp = os.fdopen(file_tmp_fd, 'r+')
			return True
		else:
			try:
				self.file_tmp = open(file_tmp_name, 'r+')
				return True
			except:
				return False


################
# BEGIN SCRIPT #
################

num_argv = len(sys.argv)

manage = ManagePasswd(KEY, FILE_GPG, FILE_PWD, TIMEOUT_PWD)

# Display the item's informations
if num_argv >= 3 and sys.argv[1] == '-d':
	if num_argv == 4:
		manage.display(sys.argv[2], sys.argv[3])
	else:
		manage.display(sys.argv[2])

# Remove an item
elif num_argv == 3 and sys.argv[1] == '-r':
	manage.remove(sys.argv[2]) 
	manage.encrypt()

# Connect to ssh
elif num_argv == 3 and sys.argv[1] == '-s':
	manage.ssh(sys.argv[2])

# Add a new item
elif num_argv == 2 and sys.argv[1] == '-a':
	manage.add()
	manage.encrypt()

# Display help
else:
	manage.help()
