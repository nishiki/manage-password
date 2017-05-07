#!/usr/bin/ruby

require 'fileutils'
require 'test/unit'

class TestConfig < Test::Unit::TestCase
  def setup
    @password = 'password'
  end

  def test_00_init_config
    FileUtils.rm_rf("#{Dir.home}/.config/mpw")
    FileUtils.rm_rf("#{Dir.home}/.gnupg")

    output = `echo "#{@password}\n#{@password}" | mpw config --init test@example.com`
    assert_match('The config file has been created', output)
    assert_match('Your GPG key has been created ;-)', output)
  end

  def test_01_add_item
    host  = 'example.com'

    output = `echo #{@password} | mpw add --host #{host} -r`
    assert_match('Item has been added!', output)
    
    output = `echo #{@password} | mpw list`
    assert_match(host, output)
  end

  def test_02_update_item
    host_old = 'example.com'
    host_new = 'example2.com'

    output = `echo #{@password} | mpw update -p #{host_old} --host #{host_new}`
    assert_match('Item has been updated!', output)
    
    output = `echo #{@password} | mpw list`
    assert_match(host_new, output)
  end

  def test_03_delete_item
    host = 'example2.com'

    output = `echo "#{@password}\ny" | mpw delete -p #{host}`
    assert_match('The item has been removed!', output)
    
    output = `echo #{@password} | mpw list`
    assert_no_match(/#{host}/, output)
  end
end
