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
    @gpg_key  = 'test@example.com'
  end

  def test_00_init_config
    output = %x(
      echo "#{@password}\n#{@password}" | mpw config \
      --init #{@gpg_key} \
      2>/dev/null
    )
    assert_match(I18n.t('form.setup_config.valid'), output)
    assert_match(I18n.t('form.setup_gpg_key.valid'), output)
  end

  def test_01_add_item
    data = @fixtures['add']

    output = %x(
      echo #{@password} | mpw add \
      --url #{data['url']} \
      --user #{data['user']} \
      --comment '#{data['comment']}' \
      --group #{data['group']} \
      --random \
      2>/dev/null
    )
    assert_match(I18n.t('form.add_item.valid'), output)

    output = %x(echo #{@password} | mpw list 2>/dev/null)
    assert_match(%r{#{data['protocol']}://.+#{data['host']}.+:#{data['port']}}, output)
    assert_match(data['user'], output)
    assert_match(data['comment'], output)
    assert_match(data['group'], output)
  end

  def test_02_search
    data = @fixtures['add']

    output = %x(echo #{@password} | mpw list --group #{data['group']} 2>/dev/null)
    assert_match(%r{#{data['protocol']}://.+#{data['host']}.+:#{data['port']}}, output)

    output = %x(echo #{@password} | mpw list --pattern #{data['host']} 2>/dev/null)
    assert_match(%r{#{data['protocol']}://.+#{data['host']}.+:#{data['port']}}, output)

    output = %x(echo #{@password} | mpw list --pattern #{data['comment']} 2>/dev/null)
    assert_match(%r{#{data['protocol']}://.+#{data['host']}.+:#{data['port']}}, output)

    output = %x(echo #{@password} | mpw list --group R1Pmfbp626TFpjlr 2>/dev/null)
    assert_match(I18n.t('display.nothing'), output)

    output = %x(echo #{@password} | mpw list --pattern h1IfnKqamaGM9oEX 2>/dev/null)
    assert_match(I18n.t('display.nothing'), output)
  end

  def test_03_update_item
    data = @fixtures['update']

    output = %x(
      echo #{@password} | mpw update \
      -p #{@fixtures['add']['host']} \
      --url #{data['url']} \
      --user #{data['user']} \
      --comment '#{data['comment']}' \
      --new-group #{data['group']} \
      2>/dev/null
    )
    assert_match(I18n.t('form.update_item.valid'), output)

    output = %x(echo #{@password} | mpw list 2>/dev/null)
    assert_match(%r{#{data['protocol']}://.+#{data['host']}.+:#{data['port']}}, output)
    assert_match(data['user'], output)
    assert_match(data['comment'], output)
    assert_match(data['group'], output)
  end

  def test_04_delete_item
    output = %x(
      echo "#{@password}\ny" | mpw delete \
      -p #{@fixtures['update']['host']} \
      2>/dev/null
    )
    assert_match(I18n.t('form.delete_item.valid'), output)

    output = %x(echo #{@password} | mpw list 2>/dev/null)
    assert_match(I18n.t('display.nothing'), output)
  end

  def test_05_import_export
    file_import = './test/files/fixtures-import.yml'
    file_export = '/tmp/test-mpw.yml'

    output = %x(echo #{@password} | mpw import --file #{file_import} 2>/dev/null)
    assert_match(I18n.t('form.import.valid', file: file_import), output)

    output = %x(echo #{@password} | mpw export --file #{file_export} 2>/dev/null)
    assert_match(I18n.t('form.export.valid', file: file_export), output)
    assert(File.exist?(file_export))
    assert_equal(YAML.load_file(file_export).length, 2)

    YAML.load_file(file_import).each_value do |import|
      error = true

      YAML.load_file(file_export).each_value do |export|
        next if import['url'] != export['url']

        %w[user group password protocol port otp_key comment].each do |key|
          assert_equal(import[key].to_s, export[key].to_s)
        end

        error = false
        break
      end

      assert(!error)
    end
  end

  def test_06_copy
    data = YAML.load_file('./test/files/fixtures-import.yml')[2]

    output = %x(
      echo "#{@password}\np\nq" | mpw copy \
      --disable-clipboard \
      -p #{data['host']} \
      2>/dev/null
    )
    assert_match(data['password'], output)
  end

  def test_07_setup_wallet
    gpg_key = 'test2@example.com'

    output = %x(echo #{@password} | mpw wallet --add-gpg-key #{gpg_key} 2>/dev/null)
    assert_match(I18n.t('form.add_key.valid'), output)

    output = %x(echo #{@password} | mpw wallet --list-keys 2>/dev/null)
    assert_match("| #{@gpg_key}", output)
    assert_match("| #{gpg_key}", output)

    output = %x(echo #{@password} | mpw wallet --delete-gpg-key #{gpg_key} 2>/dev/null)
    assert_match(I18n.t('form.delete_key.valid'), output)

    output = %x(echo #{@password} | mpw wallet --list-keys 2>/dev/null)
    assert_match("| #{@gpg_key}", output)
    assert_no_match(/\| #{gpg_key}/, output)

    output = %x(mpw wallet)
    assert_match('| default', output)
  end

  def test_08_setup_config
    gpg_key    = 'test2@example.com'
    gpg_exe    = '/usr/bin/gpg2'
    wallet_dir = '/tmp'
    length     = 24
    wallet     = 'work'

    output = %x(
      mpw config \
      --gpg-exe #{gpg_exe} \
      --key #{gpg_key} \
      --enable-pinmode \
      --disable-alpha \
      --disable-special-chars \
      --disable-numeric \
      --length #{length} \
      --wallet-dir #{wallet_dir} \
      --default-wallet #{wallet}
    )
    assert_match(I18n.t('form.set_config.valid'), output)

    output = %x(mpw config)
    assert_match(/gpg_key.+\| #{gpg_key}/, output)
    assert_match(/gpg_exe.+\| #{gpg_exe}/, output)
    assert_match(/pinmode.+\| true/, output)
    assert_match(/default_wallet.+\| #{wallet}/, output)
    assert_match(/wallet_dir.+\| #{wallet_dir}/, output)
    assert_match(/password_length.+\| #{length}/, output)
    %w[numeric alpha special].each do |k|
      assert_match(/password_#{k}.+\| false/, output)
    end

    output = %x(
      mpw config \
      --gpg-exe '' \
      --key #{@gpg_key} \
      --alpha \
      --special-chars \
      --numeric \
      --disable-pinmode
    )
    assert_match(I18n.t('form.set_config.valid'), output)

    output = %x(mpw config)
    assert_match(/gpg_key.+\| #{@gpg_key}/, output)
    assert_match(/pinmode.+\| false/, output)
    %w[numeric alpha special].each do |k|
      assert_match(/password_#{k}.+\| true/, output)
    end
  end

  def test_09_generate_password
    length = 24

    output = %x(
      mpw genpwd \
      --length #{length} \
      --alpha
    )
    assert_match(/[a-zA-Z]{#{length}}/, output)

    output = %x(
      mpw genpwd \
      --length #{length} \
      --numeric
    )
    assert_match(/[0-9]{#{length}}/, output)

    output = %x(
      mpw genpwd \
      --length #{length} \
      --special-chars
    )
    assert_no_match(/[a-zA-Z0-9]/, output)
  end
end
