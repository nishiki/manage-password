# File:  tc_simple_number.rb
 
require_relative "../lib/MPW"
require "test/unit"
 
class TestMPW < Test::Unit::TestCase

	def setup
		@file_gpg = 'test.gpg'
		@key      = 'test-mpw@test-mpw.local'

		if defined?(I18n.enforce_available_locales)
			I18n.enforce_available_locales = false
		end

		File.delete(@file_gpg) if File.exist?(@file_gpg)
		@mpw = MPW::MPW.new(@file_gpg, @key)
	end
	
	def test_load_empty_file
		assert(@mpw.decrypt)
		assert_equal(0, @mpw.search.length)
	end

	def test_add
		name     = 'test_name'
		group    = 'test_group'
		host     = 'test_host'
		protocol = 'test_protocol'
		login    = 'test_login'
		password = 'test_password'
		port     = '42'
		comment  = 'test_comment'

		assert(@mpw.update(name, group, host, protocol, login, password, port, comment))

		assert_equal(1, @mpw.search.length)

		result = @mpw.search[0]
		assert_equal('test_name',     result['name'])
		assert_equal('test_group',    result['group'])
		assert_equal('test_host',     result['host'])
		assert_equal('test_protocol', result['protocol'])
		assert_equal('test_login',    result['login'])
		assert_equal('test_password', result['password'])
		assert_equal(42,              result['port'])
		assert_equal('test_comment',  result['comment'])

		assert(@mpw.update(name, group, host, protocol, login, password, port, comment))

		assert_equal(2, @mpw.search.length)
	end

	def test_add_empty_name
		name     = ''
		group    = 'test_group'
		host     = 'test_host'
		protocol = 'test_protocol'
		login    = 'test_login'
		password = 'test_password'
		port     = '42'
		comment  = 'test_comment'

		assert(!@mpw.update(name, group, host, protocol, login, password, port, comment))

		assert_equal(0, @mpw.search.length)
	end

	def test_update
		name     = 'test_name'
		group    = 'test_group'
		host     = 'test_host'
		protocol = 'test_protocol'
		login    = 'test_login'
		password = 'test_password'
		port     = '42'
		comment  = 'test_comment'

		assert(@mpw.update(name, group, host, protocol, login, password, port, comment))

		id       = @mpw.search[0]['id']
		name     = 'test_name_update'
		group    = 'test_group_update'
		host     = 'test_host_update'
		protocol = 'test_protocol_update'
		login    = 'test_login_update'
		password = 'test_password_update'
		port     = '43'
		comment  = 'test_comment_update'

		assert(@mpw.update(name, group, host, protocol, login, password, port, comment, id))
		assert_equal(1, @mpw.search.length)

		result = @mpw.search_by_id(id)
		assert_equal('test_name_update',     result['name'])
		assert_equal('test_group_update',    result['group'])
		assert_equal('test_host_update',     result['host'])
		assert_equal('test_protocol_update', result['protocol'])
		assert_equal('test_login_update',    result['login'])
		assert_equal('test_password_update', result['password'])
		assert_equal(43,                     result['port'])
		assert_equal('test_comment_update',  result['comment'])
	end
 
end
