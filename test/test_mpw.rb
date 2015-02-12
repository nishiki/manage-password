#!/usr/bin/ruby
 
require_relative '../lib/MPW'
require_relative '../lib/Item'
require 'test/unit'
require 'yaml'
require 'csv'
 
class TestMPW < Test::Unit::TestCase
	def setup
		fixture_file = 'files/fixtures.yml'

		file_gpg = 'test.gpg'
		key      = ENV['MPW_TEST_KEY']

		puts

		if defined?(I18n.enforce_available_locales)
			I18n.enforce_available_locales = false
		end

		File.delete(file_gpg) if File.exist?(file_gpg)

		@mpw      = MPW::MPW.new(file_gpg, key)
		@fixtures = YAML.load_file(fixture_file)
	end
 
 	def test_01_import_yaml
		import_file = 'files/test_import.yml'

		assert(@mpw.import(import_file, :yaml))
		assert_equal(2, @mpw.list.length)

		item = @mpw.list[0]
		assert_equal(@fixtures['add_new']['name'],      item.name)
		assert_equal(@fixtures['add_new']['group'],     item.group)
		assert_equal(@fixtures['add_new']['host'],      item.host)
		assert_equal(@fixtures['add_new']['protocol'],  item.protocol)
		assert_equal(@fixtures['add_new']['user'],      item.user)
		assert_equal(@fixtures['add_new']['password'],  item.password)
		assert_equal(@fixtures['add_new']['port'].to_i, item.port)
		assert_equal(@fixtures['add_new']['comment'],   item.comment)
	end

	def test_02_export_yaml
		import_file = 'files/test_import.yml'
		export_file = 'test_export.yml'

		assert(@mpw.import(import_file))
		assert_equal(2, @mpw.list.length)
		assert(@mpw.export(export_file, :yaml))
		export = YAML::load_file(export_file)
		assert_equal(2, export.length)

		result = export.values[0]
		assert_equal(@fixtures['add_new']['name'],      result['name'])
		assert_equal(@fixtures['add_new']['group'],     result['group'])
		assert_equal(@fixtures['add_new']['host'],      result['host'])
		assert_equal(@fixtures['add_new']['protocol'],  result['protocol'])
		assert_equal(@fixtures['add_new']['user'],      result['user'])
		assert_equal(@fixtures['add_new']['password'],  result['password'])
		assert_equal(@fixtures['add_new']['port'].to_i, result['port'])
		assert_equal(@fixtures['add_new']['comment'],   result['comment'])

		File.unlink(export_file)
	end

	def test_03_import_csv
		import_file = 'files/test_import.csv'

		assert(@mpw.import(import_file, :csv))
		assert_equal(2, @mpw.list.length)

		import = CSV.parse(File.read(import_file), headers: true)

		item = @mpw.list[0]
		assert_equal(import[0]['name'],      item.name)
		assert_equal(import[0]['group'],     item.group)
		assert_equal(import[0]['host'],      item.host)
		assert_equal(import[0]['protocol'],  item.protocol)
		assert_equal(import[0]['user'],      item.user)
		assert_equal(import[0]['password'],  item.password)
		assert_equal(import[0]['port'].to_i, item.port)
		assert_equal(import[0]['comment'],   item.comment)
	end

	def test_04_export_csv
		import_file = 'files/test_import.csv'
		export_file = 'test_export.csv'

		assert(@mpw.import(import_file, :csv))
		assert_equal(2, @mpw.list.length)
		assert(@mpw.export(export_file, :csv))
		export = CSV.parse(File.read(export_file), headers: true)
		assert_equal(2, export.length)

		result = export[0]
		assert_equal(@fixtures['add_new']['name'],     result['name'])
		assert_equal(@fixtures['add_new']['group'],    result['group'])
		assert_equal(@fixtures['add_new']['host'],     result['host'])
		assert_equal(@fixtures['add_new']['protocol'], result['protocol'])
		assert_equal(@fixtures['add_new']['user'],     result['user'])
		assert_equal(@fixtures['add_new']['password'], result['password'])
		assert_equal(@fixtures['add_new']['port'],     result['port'])
		assert_equal(@fixtures['add_new']['comment'],  result['comment'])

		File.unlink(export_file)
	end

	def test_05_add_item
		data = {name:     @fixtures['add_new']['name'],
		        group:    @fixtures['add_new']['group'],
		        host:     @fixtures['add_new']['host'],
		        protocol: @fixtures['add_new']['protocol'],
		        user:     @fixtures['add_new']['user'],
		        password: @fixtures['add_new']['password'],
		        port:     @fixtures['add_new']['port'],
		        comment:  @fixtures['add_new']['comment'],
		       }
		
		item = MPW::Item.new(data)

		assert(!item.nil?)
		assert(!item.empty?)

		assert(@mpw.add(item))

		assert_equal(1, @mpw.list.length)

		item = @mpw.list[0]
		assert_equal(@fixtures['add_new']['name'],      item.name)
		assert_equal(@fixtures['add_new']['group'],     item.group)
		assert_equal(@fixtures['add_new']['host'],      item.host)
		assert_equal(@fixtures['add_new']['protocol'],  item.protocol)
		assert_equal(@fixtures['add_new']['user'],      item.user)
		assert_equal(@fixtures['add_new']['password'],  item.password)
		assert_equal(@fixtures['add_new']['port'].to_i, item.port)
		assert_equal(@fixtures['add_new']['comment'],   item.comment)
	end

	def test_11_encrypt_empty_file
		assert(@mpw.encrypt)	
	end

	def test_12_encrypt
		import_file = 'files/test_import.yml'

		assert(@mpw.import(import_file, :yaml))
		assert_equal(2, @mpw.list.length)

		assert(@mpw.encrypt)	
	end

	def test_13_decrypt_empty_file
		assert(@mpw.decrypt)
		assert_equal(0, @mpw.list.length)
	end

	def test_14_decrypt
		import_file = 'files/test_import.yml'

		assert(@mpw.import(import_file, :yaml))
		assert_equal(2, @mpw.list.length)

		assert(@mpw.encrypt)	

		assert(@mpw.decrypt)
		assert_equal(2, @mpw.list.length)

		item = @mpw.list[0]
		assert_equal(@fixtures['add_new']['name'],      item.name)
		assert_equal(@fixtures['add_new']['group'],     item.group)
		assert_equal(@fixtures['add_new']['host'],      item.host)
		assert_equal(@fixtures['add_new']['protocol'],  item.protocol)
		assert_equal(@fixtures['add_new']['user'],      item.user)
		assert_equal(@fixtures['add_new']['password'],  item.password)
		assert_equal(@fixtures['add_new']['port'].to_i, item.port)
		assert_equal(@fixtures['add_new']['comment'],   item.comment)
	end
end
