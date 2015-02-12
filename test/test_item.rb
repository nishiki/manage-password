#!/usr/bin/ruby
 
require_relative '../lib/Item'
require 'test/unit'
require 'yaml'
 
class TestItem < Test::Unit::TestCase
	def setup
		@fixture_file = 'files/fixtures.yml'
		@fixtures = YAML.load_file(@fixture_file)
		
		if defined?(I18n.enforce_available_locales)
			I18n.enforce_available_locales = false
		end

		puts
	end

	def test_01_add_new
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

		assert_equal(@fixtures['add_new']['name'],      item.name)
		assert_equal(@fixtures['add_new']['group'],     item.group)
		assert_equal(@fixtures['add_new']['host'],      item.host)
		assert_equal(@fixtures['add_new']['protocol'],  item.protocol)
		assert_equal(@fixtures['add_new']['user'],      item.user)
		assert_equal(@fixtures['add_new']['password'],  item.password)
		assert_equal(@fixtures['add_new']['port'].to_i, item.port)
		assert_equal(@fixtures['add_new']['comment'],   item.comment)
	end

	def test_02_add_existing
		data = {id:       @fixtures['add_existing']['id'],
		        name:     @fixtures['add_existing']['name'],
		        group:    @fixtures['add_existing']['group'],
		        host:     @fixtures['add_existing']['host'],
		        protocol: @fixtures['add_existing']['protocol'],
		        user:     @fixtures['add_existing']['user'],
		        password: @fixtures['add_existing']['password'],
		        port:     @fixtures['add_existing']['port'],
		        comment:  @fixtures['add_existing']['comment'],
		        created:  @fixtures['add_existing']['created'],
		       }

		item = MPW::Item.new(data)

		assert(!item.nil?)
		assert(!item.empty?)

		assert_equal(@fixtures['add_existing']['id'],        item.id)
		assert_equal(@fixtures['add_existing']['name'],      item.name)
		assert_equal(@fixtures['add_existing']['group'],     item.group)
		assert_equal(@fixtures['add_existing']['host'],      item.host)
		assert_equal(@fixtures['add_existing']['protocol'],  item.protocol)
		assert_equal(@fixtures['add_existing']['user'],      item.user)
		assert_equal(@fixtures['add_existing']['password'],  item.password)
		assert_equal(@fixtures['add_existing']['port'].to_i, item.port)
		assert_equal(@fixtures['add_existing']['comment'],   item.comment)
		assert_equal(@fixtures['add_existing']['created'],   item.created)
	end

	def test_03_update
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

		created   = item.created
		last_edit = item.last_edit

		data = {name:     @fixtures['update']['name'],
		        group:    @fixtures['update']['group'],
		        host:     @fixtures['update']['host'],
		        protocol: @fixtures['update']['protocol'],
		        user:     @fixtures['update']['user'],
		        password: @fixtures['update']['password'],
		        port:     @fixtures['update']['port'],
		        comment:  @fixtures['update']['comment'],
		       }
		
		sleep(1)
		assert(item.update(data))

		assert(!item.empty?)

		assert_equal(@fixtures['update']['name'],      item.name)
		assert_equal(@fixtures['update']['group'],     item.group)
		assert_equal(@fixtures['update']['host'],      item.host)
		assert_equal(@fixtures['update']['protocol'],  item.protocol)
		assert_equal(@fixtures['update']['user'],      item.user)
		assert_equal(@fixtures['update']['password'],  item.password)
		assert_equal(@fixtures['update']['port'].to_i, item.port)
		assert_equal(@fixtures['update']['comment'],   item.comment)

		assert_equal(created, item.created)
		assert_not_equal(last_edit, item.last_edit)
	end

	def test_04_update_with_empty_name
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

		last_edit = item.last_edit

		sleep(1)
		assert(!item.update({name: ''}))

		assert_equal(last_edit, item.last_edit)
	end

	def test_05_update_one_element
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

		last_edit = item.last_edit

		sleep(1)
		assert(item.update({comment: @fixtures['update']['comment']}))

		assert_equal(@fixtures['add_new']['name'],      item.name)
		assert_equal(@fixtures['add_new']['group'],     item.group)
		assert_equal(@fixtures['add_new']['host'],      item.host)
		assert_equal(@fixtures['add_new']['protocol'],  item.protocol)
		assert_equal(@fixtures['add_new']['user'],      item.user)
		assert_equal(@fixtures['add_new']['password'],  item.password)
		assert_equal(@fixtures['add_new']['port'].to_i, item.port)
		assert_equal(@fixtures['update']['comment'],    item.comment)
	
		assert_not_equal(last_edit, item.last_edit)
	end

	def test_04_delete
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

		assert(item.delete)
		assert(!item.nil?)
		assert(item.empty?)

		assert_equal(nil, item.id)
		assert_equal(nil, item.name)
		assert_equal(nil, item.group)
		assert_equal(nil, item.host)
		assert_equal(nil, item.protocol)
		assert_equal(nil, item.user)
		assert_equal(nil, item.password)
		assert_equal(nil, item.port)
		assert_equal(nil, item.comment)
		assert_equal(nil, item.created)
	end
end 
