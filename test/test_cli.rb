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

    output = %x(echo "#{@password}\n#{@password}" | mpw config --init test@example.com)
    assert_match('The config file has been created', output)
    assert_match('Your GPG key has been created ;-)', output)
  end

  def test_01_add_item
    host    = 'example.com'
    port    = 1234
    proto   = 'http'
    user    = 'root'
    comment = 'the super website'
    group   = 'Bank'

    output = %x(
      echo #{@password} | mpw add \
      --host #{host} \
      --port #{port} \
      --protocol #{proto} \
      --user #{user} \
      --comment '#{comment}' \
      --group #{group} \
      --random)
    puts output
    assert_match('Item has been added!', output)

    output = %x(echo #{@password} | mpw list)
    puts output
    assert_match(%r{#{proto}://.+#{host}.+:#{port}}, output)
    assert_match(user, output)
    assert_match(comment, output)
    assert_match(group, output)
  end

  def test_02_update_item
    host_old    = 'example.com'
    host_new    = 'example2.com'
    port_new    = 4321
    proto_new   = 'ssh'
    user_new    = 'tortue'
    comment_new = 'my account'
    group_new   = 'Assurance'

    output = %x(
      echo #{@password} | mpw update \
      -p #{host_old} \
      --host #{host_new} \
      --port #{port_new} \
      --protocol #{proto_new} \
      --user #{user_new} \
      --comment '#{comment_new}' \
      --new-group #{group_new}
    )
    puts output
    assert_match('Item has been updated!', output)

    output = %x(echo #{@password} | mpw list)
    puts output
    assert_match(%r{#{proto_new}://.+#{host_new}.+:#{port_new}}, output)
    assert_match(user_new, output)
    assert_match(comment_new, output)
    assert_match(group_new, output)
  end

  def test_03_delete_item
    host = 'example2.com'

    output = %x(echo "#{@password}\ny" | mpw delete -p #{host})
    puts output
    assert_match('The item has been removed!', output)

    output = %x(echo #{@password} | mpw list)
    puts output
    assert_no_match(/#{host}/, output)
  end
end
