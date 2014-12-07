# File:  tc_simple_number.rb
 
require_relative "../lib/MPW"
require "test/unit"
 
class TestMPW < Test::Unit::TestCase


	def test_initialize
		File.delete('test.gpg') if File.exist?('test.gpg')
	end
	
	def test_load_empty_file
		mpw = MPW::MPW.new('test.cfg')
		mpw.decrypt

		assert_equal(0, mpw.search.length)
	end

	def test_add
		mpw = MPW::MPW.new('test.cfg')

		name     = 'test_name'
		group    = 'test_group'
		host     = 'test_host'
		protocol = 'test_protocol'
		login    = 'test_login'
		password = 'test_password'
		port     = '42'
		comment  = 'test_comment'

		mpw.update(name, group, host, protocol, login, password, port, comment)

		assert_equal(1, mpw.search.length)
		assert_equal('test_name', mpw.search[0]['name'])
		assert_equal('test_group', mpw.search[0]['group'])
		assert_equal('test_host', mpw.search[0]['host'])
		assert_equal('test_protocol', mpw.search[0]['protocol'])
		assert_equal('test_login', mpw.search[0]['login'])
		assert_equal('test_password', mpw.search[0]['password'])
		assert_equal(42, mpw.search[0]['port'])
		assert_equal('test_comment', mpw.search[0]['comment'])
	end
 
end
