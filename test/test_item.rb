#!/usr/bin/ruby

require 'mpw/item'
require 'test/unit'
require 'yaml'

class TestItem < Test::Unit::TestCase
  def setup
    @fixture_file = 'test/files/fixtures.yml'
    @fixtures = YAML.load_file(@fixture_file)

    if defined?(I18n.enforce_available_locales)
      I18n.enforce_available_locales = false
    end

    I18n.load_path      = Dir['./i18n/cli/*.yml']
    I18n.default_locale = :en


    puts
  end

  def test_00_add_without_name
    assert_raise(RuntimeError){MPW::Item.new}
  end

  def test_01_add_new
    data = { group:    @fixtures['add_new']['group'],
             host:     @fixtures['add_new']['host'],
             protocol: @fixtures['add_new']['protocol'],
             user:     @fixtures['add_new']['user'],
             port:     @fixtures['add_new']['port'],
             comment:  @fixtures['add_new']['comment'],
           }

    item = MPW::Item.new(data)

    assert(!item.nil?)
    assert(!item.empty?)

    assert_equal(@fixtures['add_new']['group'],     item.group)
    assert_equal(@fixtures['add_new']['host'],      item.host)
    assert_equal(@fixtures['add_new']['protocol'],  item.protocol)
    assert_equal(@fixtures['add_new']['user'],      item.user)
    assert_equal(@fixtures['add_new']['port'].to_i, item.port)
    assert_equal(@fixtures['add_new']['comment'],   item.comment)
  end

  def test_02_add_existing
    data = { id:       @fixtures['add_existing']['id'],
             group:    @fixtures['add_existing']['group'],
             host:     @fixtures['add_existing']['host'],
             protocol: @fixtures['add_existing']['protocol'],
             user:     @fixtures['add_existing']['user'],
             port:     @fixtures['add_existing']['port'],
             comment:  @fixtures['add_existing']['comment'],
             created:  @fixtures['add_existing']['created'],
           }

    item = MPW::Item.new(data)

    assert(!item.nil?)
    assert(!item.empty?)

    assert_equal(@fixtures['add_existing']['id'],        item.id)
    assert_equal(@fixtures['add_existing']['group'],     item.group)
    assert_equal(@fixtures['add_existing']['host'],      item.host)
    assert_equal(@fixtures['add_existing']['protocol'],  item.protocol)
    assert_equal(@fixtures['add_existing']['user'],      item.user)
    assert_equal(@fixtures['add_existing']['port'].to_i, item.port)
    assert_equal(@fixtures['add_existing']['comment'],   item.comment)
    assert_equal(@fixtures['add_existing']['created'],   item.created)
  end

  def test_03_update
    data = { group:    @fixtures['add_new']['group'],
             host:     @fixtures['add_new']['host'],
             protocol: @fixtures['add_new']['protocol'],
             user:     @fixtures['add_new']['user'],
             port:     @fixtures['add_new']['port'],
             comment:  @fixtures['add_new']['comment'],
           }

    item = MPW::Item.new(data)

    assert(!item.nil?)
    assert(!item.empty?)

    created   = item.created
    last_edit = item.last_edit

    data = { group:    @fixtures['update']['group'],
             host:     @fixtures['update']['host'],
             protocol: @fixtures['update']['protocol'],
             user:     @fixtures['update']['user'],
             port:     @fixtures['update']['port'],
             comment:  @fixtures['update']['comment'],
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
    data = { group:    @fixtures['add_new']['group'],
             host:     @fixtures['add_new']['host'],
             protocol: @fixtures['add_new']['protocol'],
             user:     @fixtures['add_new']['user'],
             port:     @fixtures['add_new']['port'],
             comment:  @fixtures['add_new']['comment'],
           }

    item = MPW::Item.new(data)

    assert(!item.nil?)
    assert(!item.empty?)

    last_edit = item.last_edit

    sleep(1)
    assert(item.update({comment: @fixtures['update']['comment']}))

    assert_equal(@fixtures['add_new']['group'],     item.group)
    assert_equal(@fixtures['add_new']['host'],      item.host)
    assert_equal(@fixtures['add_new']['protocol'],  item.protocol)
    assert_equal(@fixtures['add_new']['user'],      item.user)
    assert_equal(@fixtures['add_new']['port'].to_i, item.port)
    assert_equal(@fixtures['update']['comment'],    item.comment)

    assert_not_equal(last_edit, item.last_edit)
  end

  def test_05_delete
    data = { group:    @fixtures['add_new']['group'],
             host:     @fixtures['add_new']['host'],
             protocol: @fixtures['add_new']['protocol'],
             user:     @fixtures['add_new']['user'],
             port:     @fixtures['add_new']['port'],
             comment:  @fixtures['add_new']['comment'],
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
