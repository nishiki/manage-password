require 'mpw/mpw'
require 'mpw/item'
require 'test/unit'
require 'yaml'
require 'csv'

class TestMPW < Test::Unit::TestCase
  def setup
    wallet_file = 'default.gpg'
    key         = 'test@example.com'
    password    = 'password'

    if defined?(I18n.enforce_available_locales)
      I18n.enforce_available_locales = false
    end

    @mpw      = MPW::MPW.new(key, wallet_file, password)
    @fixtures = YAML.load_file('./test/files/fixtures.yml')
  end

  def test_00_decrypt_empty_file
    @mpw.read_data
    assert_equal(0, @mpw.list.length)
  end

  def test_01_encrypt_empty_file
    @mpw.read_data
    @mpw.write_data
  end

  def test_02_add_item
    data = {
      group:    @fixtures['add']['group'],
      user:     @fixtures['add']['user'],
      url:      @fixtures['add']['url'],
      comment:  @fixtures['add']['comment']
    }

    item = MPW::Item.new(data)

    assert(!item.nil?)
    assert(!item.empty?)

    @mpw.read_data
    @mpw.add(item)
    @mpw.set_password(item.id, @fixtures['add']['password'])

    assert_equal(1, @mpw.list.length)

    item = @mpw.list[0]
    @fixtures['add'].each do |k, v|
      if k == 'password'
        assert_equal(v, @mpw.get_password(item.id))
      else
        assert_equal(v, item.send(k).to_s)
      end
    end

    @mpw.write_data
  end

  def test_03_decrypt_file
    @mpw.read_data
    assert_equal(1, @mpw.list.length)

    item = @mpw.list[0]
    @fixtures['add'].each do |k, v|
      if k == 'password'
        assert_equal(v, @mpw.get_password(item.id))
      else
        assert_equal(v, item.send(k).to_s)
      end
    end
  end

  def test_04_delete_item
    @mpw.read_data
    assert_equal(1, @mpw.list.length)

    @mpw.list.each(&:delete)
    assert_equal(0, @mpw.list.length)

    @mpw.write_data
  end

  def test_05_search
    @mpw.read_data

    @fixtures.each_value do |v|
      data = {
        group:    v['group'],
        user:     v['user'],
        url:      v['url'],
        comment:  v['comment']
      }

      item = MPW::Item.new(data)

      assert(!item.nil?)
      assert(!item.empty?)

      @mpw.add(item)
      @mpw.set_password(item.id, v['password'])
    end

    assert_equal(3, @mpw.list.length)
    assert_equal(1, @mpw.list(group:   @fixtures['add']['group']).length)
    assert_equal(1, @mpw.list(pattern: 'gogole').length)
    assert_equal(2, @mpw.list(pattern: 'example[2\.]').length)
  end

  def test_06_add_gpg_key
    @mpw.read_data

    @mpw.add_key('test2@example.com')
    assert_equal(2, @mpw.list_keys.length)

    @mpw.write_data
  end

  def test_07_delete_gpg_key
    @mpw.read_data
    assert_equal(2, @mpw.list_keys.length)

    @mpw.delete_key('test2@example.com')
    assert_equal(1, @mpw.list_keys.length)

    @mpw.write_data
  end
end
