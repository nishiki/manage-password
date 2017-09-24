require 'yaml'
require 'test/unit'

class TestTranslate < Test::Unit::TestCase
  def test_00_check_translate
    missing = 0

    Dir.glob('i18n/*.yml').each do |yaml|
      lang      = File.basename(yaml, '.yml')
      translate = YAML.load_file(yaml)

      %x(grep -r -o "I18n.t('.*)" bin/ lib/ | cut -d"'" -f2).each_line do |line|
        begin
          t = translate[lang]
          line.strip.split('.').each do |v|
            t = t[v]
          end

          assert(!t.to_s.empty?)
        rescue
          puts "#{lang}.#{line}"
          missing = 1
        end
      end
    end

    assert_equal(0, missing)
  end
end
