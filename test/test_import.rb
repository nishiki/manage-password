require 'i18n'
require 'test/unit'

class TestImport < Test::Unit::TestCase
  def setup
    if defined?(I18n.enforce_available_locales)
      I18n.enforce_available_locales = true
    end

    I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)
    I18n.load_path = ["#{File.expand_path('../../i18n', __FILE__)}/en.yml"]
    I18n.locale    = :en

    @password = 'password'
  end

  def test_00_import
    Dir['./test/files/import-*.txt'].each do |file|
      format = File.basename(file, '.txt').partition('-').last

      puts format

      output = %x(
          mpw import \
          --file #{file} \
          --format #{format} \
          --wallet #{format}
        )
      assert_match(I18n.t('form.import.valid'), output)

      output = %x(echo #{@password} | mpw list --group Bank --wallet #{format})
      assert_match(%r{http://.*fric\.com.*12345.*Fric money money}, output)

      output = %x(echo #{@password} | mpw list --group Cloud --wallet #{format})
      assert_match(%r{ssh://.*fric\.com.*:4333.*username.*bastion}, output)

      output = %x(echo #{@password} | mpw list --wallet #{format})
      assert_match(/server\.com.*My little server/, output)
    end
  end
end
