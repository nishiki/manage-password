# File:  tc_simple_number.rb
 
require_relative '../lib/MPW'
require 'test/unit'
require 'yaml'
 
class TestMPW < Test::Unit::TestCase

	#@@mpw = MPW::MPW.new('test.gpg', 'a.waksberg@yaegashi.fr')
	def setup
		file_gpg = 'test.gpg'
		key      = 'test-mpw@test-mpw.local'

		if defined?(I18n.enforce_available_locales)
			I18n.enforce_available_locales = false
		end

		File.delete(file_gpg) if File.exist?(file_gpg)
		@mpw = MPW::MPW.new(file_gpg, key)
		@fixtures = YAML.load_file('fixtures.yml')
	end
	
	def test_load_empty_file
		assert(@mpw.decrypt)
		assert_equal(0, @mpw.search.length)
	end

	def test_add
		assert(@mpw.update(@fixtures['add']['name'], 
		                   @fixtures['add']['group'], 
		                   @fixtures['add']['host'],
		                   @fixtures['add']['protocol'],
		                   @fixtures['add']['login'],
		                   @fixtures['add']['password'],
		                   @fixtures['add']['port'],
		                   @fixtures['add']['comment']))

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

		assert(@mpw.update(@fixtures['add']['name'], 
		                   @fixtures['add']['group'], 
		                   @fixtures['add']['host'],
		                   @fixtures['add']['protocol'],
		                   @fixtures['add']['login'],
		                   @fixtures['add']['password'],
		                   @fixtures['add']['port'],
		                   @fixtures['add']['comment']))


		assert_equal(2, @mpw.search.length)
	end

	def test_add_empty_name
		assert(!@mpw.update('', 
		                   @fixtures['add']['group'], 
		                   @fixtures['add']['host'],
		                   @fixtures['add']['protocol'],
		                   @fixtures['add']['login'],
		                   @fixtures['add']['password'],
		                   @fixtures['add']['port'],
		                   @fixtures['add']['comment']))

		assert_equal(0, @mpw.search.length)
	end

	def test_update
		assert(@mpw.update(@fixtures['add']['name'], 
		                   @fixtures['add']['group'], 
		                   @fixtures['add']['host'],
		                   @fixtures['add']['protocol'],
		                   @fixtures['add']['login'],
		                   @fixtures['add']['password'],
		                   @fixtures['add']['port'],
		                   @fixtures['add']['comment']))

		id = @mpw.search[0]['id']

		assert(@mpw.update(@fixtures['update']['name'], 
		                   @fixtures['update']['group'], 
		                   @fixtures['update']['host'],
		                   @fixtures['update']['protocol'],
		                   @fixtures['update']['login'],
		                   @fixtures['update']['password'],
		                   @fixtures['update']['port'],
		                   @fixtures['update']['comment'],
		                   id))

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
 
 	def test_import
		assert(@mpw.import('fixtures.yml'))
		assert_equal(2, @mpw.search.length)
	end
end
