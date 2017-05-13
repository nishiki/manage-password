#!/usr/bin/ruby

require 'fileutils'
require 'i18n'
require 'test/unit'

class TestConfig < Test::Unit::TestCase
  def setup
    if defined?(I18n.enforce_available_locales)
      I18n.enforce_available_locales = true
    end

    I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)
    I18n.load_path = ["#{File.expand_path('../../i18n', __FILE__)}/en.yml"]
    I18n.locale    = :en

    @password = 'password'
    @fixtures = YAML.load_file('./test/files/fixtures.yml')
  end

  def test_00_init_config
    FileUtils.rm_rf("#{Dir.home}/.config/mpw")
    FileUtils.rm_rf("#{Dir.home}/.gnupg")

    output = %x(echo "#{@password}\n#{@password}" | mpw config --init test@example.com)
    assert_match(I18n.t('form.setup_config.valid'), output)
    assert_match(I18n.t('form.setup_gpg_key.valid'), output)
  end

  def test_01_add_item
    data = @fixtures['add']

    output = %x(
      echo #{@password} | mpw add \
      --host #{data['host']} \
      --port #{data['port']} \
      --protocol #{data['protocol']} \
      --user #{data['user']} \
      --comment '#{data['comment']}' \
      --group #{data['group']} \
      --random)
    puts output
    assert_match(I18n.t('form.add_item.valid'), output)

    output = %x(echo #{@password} | mpw list)
    puts output
    assert_match(%r{#{data['protocol']}://.+#{data['host']}.+:#{data['port']}}, output)
    assert_match(data['user'], output)
    assert_match(data['comment'], output)
    assert_match(data['group'], output)
  end

  def test_02_search
    data = @fixtures['add']

    output = %x(echo #{@password} | mpw list --group #{data['group']})
    assert_match(%r{#{data['protocol']}://.+#{data['host']}.+:#{data['port']}}, output)

    output = %x(echo #{@password} | mpw list --pattern #{data['host']})
    assert_match(%r{#{data['protocol']}://.+#{data['host']}.+:#{data['port']}}, output)

    output = %x(echo #{@password} | mpw list --pattern #{data['comment']})
    assert_match(%r{#{data['protocol']}://.+#{data['host']}.+:#{data['port']}}, output)

    output = %x(echo #{@password} | mpw list --group R1Pmfbp626TFpjlr)
    assert_match(I18n.t('display.nothing'), output)

    output = %x(echo #{@password} | mpw list --pattern h1IfnKqamaGM9oEX)
    assert_match(I18n.t('display.nothing'), output)
  end

  def test_03_update_item
    data = @fixtures['update']

    output = %x(
      echo #{@password} | mpw update \
      -p #{@fixtures['add']['host']} \
      --host #{data['host']} \
      --port #{data['port']} \
      --protocol #{data['protocol']} \
      --user #{data['user']} \
      --comment '#{data['comment']}' \
      --new-group #{data['group']}
    )
    puts output
    assert_match(I18n.t('form.update_item.valid'), output)

    output = %x(echo #{@password} | mpw list)
    puts output
    assert_match(%r{#{data['protocol']}://.+#{data['host']}.+:#{data['port']}}, output)
    assert_match(data['user'], output)
    assert_match(data['comment'], output)
    assert_match(data['group'], output)
  end

  def test_04_delete_item
    output = %x(echo "#{@password}\ny" | mpw delete -p #{@fixtures['update']['host']})
    puts output
    assert_match(I18n.t('form.delete_item.valid'), output)

    output = %x(echo #{@password} | mpw list)
    puts output
    assert_match(I18n.t('display.nothing'), output)
  end
end
