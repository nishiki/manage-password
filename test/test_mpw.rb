#!/usr/bin/ruby
 
require_relative '../lib/MPW'
require 'test/unit'
require 'yaml'
require 'csv'
 
class TestMPW < Test::Unit::TestCase
	def setup
		@fixture_file = 'files/fixtures.yml'

		file_gpg = 'test.gpg'
		key      = ENV['MPW_TEST_KEY']

		puts

		if defined?(I18n.enforce_available_locales)
			I18n.enforce_available_locales = false
		end

		File.delete(file_gpg) if File.exist?(file_gpg)
		@mpw = MPW::MPW.new(file_gpg, key)
		@fixtures = YAML.load_file(@fixture_file)
	end
 
 	def test_01_import_yaml
		import_file = 'files/test_import.yml'

		assert(@mpw.import(import_file, :yaml))
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

	def test_02_export_yaml
		export_file = 'test_export.yml'

		assert(@mpw.import(@fixture_file))
		assert_equal(2, @mpw.search.length)
		assert(@mpw.export(export_file, :yaml))
		export = YAML::load_file(export_file)
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

		File.unlink(export_file)
	end

	def test_03_import_csv
		import_file = 'files/test_import.csv'

		assert(@mpw.import(import_file, :csv))
		assert_equal(2, @mpw.search.length)

		import = CSV.parse(File.read(import_file), headers: true)

		result = @mpw.search[0]
		assert_equal(import[0]['name'],      result['name'])
		assert_equal(import[0]['group'],     result['group'])
		assert_equal(import[0]['host'],      result['host'])
		assert_equal(import[0]['protocol'],  result['protocol'])
		assert_equal(import[0]['login'],     result['login'])
		assert_equal(import[0]['password'],  result['password'])
		assert_equal(import[0]['port'].to_i, result['port'])
		assert_equal(import[0]['comment'],   result['comment'])
	end

	def test_04_export_csv
		export_file = 'test_export.csv'
		assert(@mpw.import(@fixture_file))
		assert_equal(2, @mpw.search.length)
		assert(@mpw.export(export_file, :csv))
		export = CSV.parse(File.read(export_file), headers: true)
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

		File.unlink(export_file)
	end

	def test_05_add
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

	def test_06_add_empty_name
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

	def test_07_update_empty
		assert(@mpw.import(@fixture_file, :yaml))
		assert_equal(2, @mpw.search.length)

		id = @mpw.search[0]['id']

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
	end

	def test_08_update
		assert(@mpw.import(@fixture_file, :yaml))
		assert_equal(2, @mpw.search.length)

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

		assert_equal(2, @mpw.search.length)

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

	def test_09_remove
		assert(@mpw.import(@fixture_file, :yaml))
		assert_equal(2, @mpw.search.length)

		id = @mpw.search[0]['id']
		assert(@mpw.remove(id)) 

		assert_equal(1, @mpw.search.length)
	end

	def test_10_remove_noexistent
		assert(@mpw.import(@fixture_file, :yaml))
		assert_equal(2, @mpw.search.length)

		assert(!@mpw.remove('TEST_NOEXISTENT_ID')) 

		assert_equal(2, @mpw.search.length)
	end

	def test_11_encrypt_empty_file
		assert(@mpw.encrypt)	
	end

	def test_12_encrypt
		assert(@mpw.import(@fixture_file, :yaml))
		assert_equal(2, @mpw.search.length)

		assert(@mpw.encrypt)	
	end

	def test_13_decrypt_empty_file
		assert(@mpw.decrypt)
		assert_equal(0, @mpw.search.length)
	end

	def test_14_decrypt
		assert(@mpw.import(@fixture_file, :yaml))
		assert_equal(2, @mpw.search.length)

		assert(@mpw.encrypt)	

		assert(@mpw.decrypt)
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
end
