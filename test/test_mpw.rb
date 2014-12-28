# File:  tc_simple_number.rb
 
require_relative '../lib/MPW'
require 'test/unit'
require 'yaml'
require 'csv'
 
class TestMPW < Test::Unit::TestCase

	def setup
		@fixture_file = 'fixtures.yml'

		file_gpg = 'test.gpg'
		key      = 'test-mpw@test-mpw.local'

		if defined?(I18n.enforce_available_locales)
			I18n.enforce_available_locales = false
		end

		File.delete(file_gpg) if File.exist?(file_gpg)
		@mpw = MPW::MPW.new(file_gpg, key)
		@fixtures = YAML.load_file(@fixture_file)
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
		assert_equal(@fixtures['add']['name'],      result['name'])
		assert_equal(@fixtures['add']['group'],     result['group'])
		assert_equal(@fixtures['add']['host'],      result['host'])
		assert_equal(@fixtures['add']['protocol'],  result['protocol'])
		assert_equal(@fixtures['add']['login'],     result['login'])
		assert_equal(@fixtures['add']['password'],  result['password'])
		assert_equal(@fixtures['add']['port'].to_i, result['port'])
		assert_equal(@fixtures['add']['comment'],   result['comment'])

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

		# Test empty update
		assert(@mpw.update('','', '','','','','', '', id))

		result = @mpw.search_by_id(id)
		assert_equal(@fixtures['add']['name'],      result['name'])
		assert_equal(@fixtures['add']['group'],     result['group'])
		assert_equal(@fixtures['add']['host'],      result['host'])
		assert_equal(@fixtures['add']['protocol'],  result['protocol'])
		assert_equal(@fixtures['add']['login'],     result['login'])
		assert_equal(@fixtures['add']['password'],  result['password'])
		assert_equal(@fixtures['add']['port'].to_i, result['port'])
		assert_equal(@fixtures['add']['comment'],   result['comment'])


		# Test real update
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
		assert_equal(@fixtures['update']['name'],      result['name'])
		assert_equal(@fixtures['update']['group'],     result['group'])
		assert_equal(@fixtures['update']['host'],      result['host'])
		assert_equal(@fixtures['update']['protocol'],  result['protocol'])
		assert_equal(@fixtures['update']['login'],     result['login'])
		assert_equal(@fixtures['update']['password'],  result['password'])
		assert_equal(@fixtures['update']['port'].to_i, result['port'])
		assert_equal(@fixtures['update']['comment'],   result['comment'])
	end
 
 	def test_import_yaml
		assert(@mpw.import(@fixture_file, :yaml))
		assert_equal(2, @mpw.search.length)

		result = @mpw.search[0]
		assert_equal(@fixtures['add']['name'],      result['name'])
		assert_equal(@fixtures['add']['group'],     result['group'])
		assert_equal(@fixtures['add']['host'],      result['host'])
		assert_equal(@fixtures['add']['protocol'],  result['protocol'])
		assert_equal(@fixtures['add']['login'],     result['login'])
		assert_equal(@fixtures['add']['password'],  result['password'])
		assert_equal(@fixtures['add']['port'].to_i, result['port'])
		assert_equal(@fixtures['add']['comment'],   result['comment'])
	end

	def test_export_yaml
		assert(@mpw.import(@fixture_file))
		assert_equal(2, @mpw.search.length)
		assert(@mpw.export('export.yml', :yaml))
		export = YAML::load_file('export.yml')
		assert_equal(2, export.length)

		result = export.values[0]
		assert_equal(@fixtures['add']['name'],      result['name'])
		assert_equal(@fixtures['add']['group'],     result['group'])
		assert_equal(@fixtures['add']['host'],      result['host'])
		assert_equal(@fixtures['add']['protocol'],  result['protocol'])
		assert_equal(@fixtures['add']['login'],     result['login'])
		assert_equal(@fixtures['add']['password'],  result['password'])
		assert_equal(@fixtures['add']['port'].to_i, result['port'])
		assert_equal(@fixtures['add']['comment'],   result['comment'])
	end

	def test_export_csv
		assert(@mpw.import(@fixture_file))
		assert_equal(2, @mpw.search.length)
		assert(@mpw.export('export.csv', :csv))
		export = CSV.parse(File.read('export.csv'), headers: true)
		assert_equal(2, export.length)

		result = export[0]
		assert_equal(@fixtures['add']['name'],     result['name'])
		assert_equal(@fixtures['add']['group'],    result['group'])
		assert_equal(@fixtures['add']['host'],     result['host'])
		assert_equal(@fixtures['add']['protocol'], result['protocol'])
		assert_equal(@fixtures['add']['login'],    result['login'])
		assert_equal(@fixtures['add']['password'], result['password'])
		assert_equal(@fixtures['add']['port'],     result['port'])
		assert_equal(@fixtures['add']['comment'],  result['comment'])

	end

	def test_import_csv
		assert(@mpw.import(@fixture_file))
		assert_equal(2, @mpw.search.length)
		assert(@mpw.export('export.csv', :csv))
		assert(@mpw.import('export.csv', :csv))
		assert_equal(4, @mpw.search.length)

		result = @mpw.search[2]
		assert_equal(@fixtures['add']['name'],      result['name'])
		assert_equal(@fixtures['add']['group'],     result['group'])
		assert_equal(@fixtures['add']['host'],      result['host'])
		assert_equal(@fixtures['add']['protocol'],  result['protocol'])
		assert_equal(@fixtures['add']['login'],     result['login'])
		assert_equal(@fixtures['add']['password'],  result['password'])
		assert_equal(@fixtures['add']['port'].to_i, result['port'])
		assert_equal(@fixtures['add']['comment'],   result['comment'])
	
	end
end
