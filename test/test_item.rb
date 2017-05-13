#!/usr/bin/ruby

require 'mpw/item'
require 'test/unit'
require 'yaml'

class TestItem < Test::Unit::TestCase
  def setup
    if defined?(I18n.enforce_available_locales)
      I18n.enforce_available_locales = false
    end

    I18n.load_path      = Dir['./i18n/cli/*.yml']
    I18n.default_locale = :en

    @fixtures = YAML.load_file('./test/files/fixtures.yml')
  end

  def test_00_add_without_name
    assert_raise(RuntimeError) { MPW::Item.new }
  end

  def test_01_add
    data = {
      group:    @fixtures['add']['group'],
      host:     @fixtures['add']['host'],
      protocol: @fixtures['add']['protocol'],
      user:     @fixtures['add']['user'],
      port:     @fixtures['add']['port'],
      comment:  @fixtures['add']['comment']
    }

    item = MPW::Item.new(data)

    assert(!item.nil?)
    assert(!item.empty?)

    assert_equal(@fixtures['add']['group'],     item.group)
    assert_equal(@fixtures['add']['host'],      item.host)
    assert_equal(@fixtures['add']['protocol'],  item.protocol)
    assert_equal(@fixtures['add']['user'],      item.user)
    assert_equal(@fixtures['add']['port'].to_i, item.port)
    assert_equal(@fixtures['add']['comment'],   item.comment)
  end

  def test_02_import
    data = {
      id:       @fixtures['import']['id'],
      group:    @fixtures['import']['group'],
      host:     @fixtures['import']['host'],
      protocol: @fixtures['import']['protocol'],
      user:     @fixtures['import']['user'],
      port:     @fixtures['import']['port'],
      comment:  @fixtures['import']['comment'],
      created:  @fixtures['import']['created']
    }

    item = MPW::Item.new(data)

    assert(!item.nil?)
    assert(!item.empty?)

    assert_equal(@fixtures['import']['id'],        item.id)
    assert_equal(@fixtures['import']['group'],     item.group)
    assert_equal(@fixtures['import']['host'],      item.host)
    assert_equal(@fixtures['import']['protocol'],  item.protocol)
    assert_equal(@fixtures['import']['user'],      item.user)
    assert_equal(@fixtures['import']['port'].to_i, item.port)
    assert_equal(@fixtures['import']['comment'],   item.comment)
    assert_equal(@fixtures['import']['created'],   item.created)
  end

  def test_03_update
    data = {
      group:    @fixtures['add']['group'],
      host:     @fixtures['add']['host'],
      protocol: @fixtures['add']['protocol'],
      user:     @fixtures['add']['user'],
      port:     @fixtures['add']['port'],
      comment:  @fixtures['add']['comment']
    }

    item = MPW::Item.new(data)

    assert(!item.nil?)
    assert(!item.empty?)

    created   = item.created
    last_edit = item.last_edit

    data = {
      group:    @fixtures['update']['group'],
      host:     @fixtures['update']['host'],
      protocol: @fixtures['update']['protocol'],
      user:     @fixtures['update']['user'],
      port:     @fixtures['update']['port'],
      comment:  @fixtures['update']['comment']
    }

    sleep(1)
    assert(item.update(data))

    assert(!item.empty?)

    assert_equal(@fixtures['update']['group'],     item.group)
    assert_equal(@fixtures['update']['host'],      item.host)
    assert_equal(@fixtures['update']['protocol'],  item.protocol)
    assert_equal(@fixtures['update']['user'],      item.user)
    assert_equal(@fixtures['update']['port'].to_i, item.port)
    assert_equal(@fixtures['update']['comment'],   item.comment)

    assert_equal(created, item.created)
    assert_not_equal(last_edit, item.last_edit)
  end

  def test_05_update_one_element
    data = {
      group:    @fixtures['add']['group'],
      host:     @fixtures['add']['host'],
      protocol: @fixtures['add']['protocol'],
      user:     @fixtures['add']['user'],
      port:     @fixtures['add']['port'],
      comment:  @fixtures['add']['comment']
    }

    item = MPW::Item.new(data)

    assert(!item.nil?)
    assert(!item.empty?)

    last_edit = item.last_edit

    sleep(1)
    assert(item.update(comment: @fixtures['update']['comment']))

    assert_equal(@fixtures['add']['group'],      item.group)
    assert_equal(@fixtures['add']['host'],       item.host)
    assert_equal(@fixtures['add']['protocol'],   item.protocol)
    assert_equal(@fixtures['add']['user'],       item.user)
    assert_equal(@fixtures['add']['port'].to_i,  item.port)
    assert_equal(@fixtures['update']['comment'], item.comment)

    assert_not_equal(last_edit, item.last_edit)
  end

  def test_05_delete
    data = {
      group:    @fixtures['add']['group'],
      host:     @fixtures['add']['host'],
      protocol: @fixtures['add']['protocol'],
      user:     @fixtures['add']['user'],
      port:     @fixtures['add']['port'],
      comment:  @fixtures['add']['comment']
    }

    item = MPW::Item.new(data)

    assert(!item.nil?)
    assert(!item.empty?)

    item.delete
    assert(!item.nil?)
    assert(item.empty?)

    assert_equal(nil, item.id)
    assert_equal(nil, item.group)
    assert_equal(nil, item.host)
    assert_equal(nil, item.protocol)
    assert_equal(nil, item.user)
    assert_equal(nil, item.port)
    assert_equal(nil, item.comment)
    assert_equal(nil, item.created)
  end
end
