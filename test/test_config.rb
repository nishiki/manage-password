#!/usr/bin/ruby

require 'mpw/config'
require 'test/unit'
require 'locale'
require 'i18n'

class TestConfig < Test::Unit::TestCase
  def setup
    lang = Locale::Tag.parse(ENV['LANG']).to_simple.to_s[0..1]

    if defined?(I18n.enforce_available_locales)
      I18n.enforce_available_locales = true
    end

    I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)
    I18n.load_path      = Dir["#{File.expand_path('../../i18n', __FILE__)}/*.yml"]
    I18n.default_locale = :en
    I18n.locale         = lang.to_sym
  end

  def test_00_config
    data = {
      gpg_key: 'test@example.com',
      lang: 'en',
      wallet_dir: '/tmp/test',
      gpg_exe: ''
    }

    @config = MPW::Config.new
    @config.setup(data)
    @config.load_config

    data.each do |k, v|
      assert_equal(v, @config.send(k))
    end

    @config.setup_gpg_key('password', 'test@example.com', 2048)
    assert(@config.check_gpg_key?)
  end

  def test_01_password
    data = {
      pwd_alpha: false,
      pwd_numeric: false,
      pwd_special: true,
      pwd_length: 32
    }

    @config = MPW::Config.new
    @config.load_config

    assert_equal(@config.password[:length], 16)
    assert(@config.password[:alpha])
    assert(@config.password[:numeric])
    assert(!@config.password[:special])

    @config.setup(data)
    @config.load_config

    assert_equal(@config.password[:length], data[:pwd_length])
    assert(!@config.password[:alpha])
    assert(!@config.password[:numeric])
    assert(@config.password[:special])
  end

  def test_02_wallet_paths
    new_path = '/tmp/mpw-test'

    @config = MPW::Config.new
    @config.load_config

    assert(!@config.wallet_paths['default'])

    @config.set_wallet_path(new_path, 'default')
    assert_equal(@config.wallet_paths['default'], new_path)

    @config.set_wallet_path('default', 'default')
    assert(!@config.wallet_paths['default'])
  end
end
