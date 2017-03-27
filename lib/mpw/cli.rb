#!/usr/bin/ruby
# MPW is a software to crypt and manage your passwords
# Copyright (C) 2016  Adrien Waksberg <mpw@yae.im>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require 'readline'
require 'locale'
require 'i18n'
require 'colorize'
require 'highline/import'
require 'clipboard'
require 'tmpdir'
require 'mpw/item'
require 'mpw/mpw'

module MPW
class Cli

  # Constructor
  # @args: config -> the config
  def initialize(config)
    @config = config
  end

  # Change a parameter int the config after init
  # @args: options -> param to change
  def set_config(options)
    @config.setup(options)

    puts "#{I18n.t('form.set_config.valid')}".green
  rescue Exception => e
    puts "#{I18n.t('display.error')} #15: #{e}".red
    exit 2
  end

  # Create a new config file
  # @args: options -> set param
  def setup(options)
    options[:lang] = options[:lang] || Locale::Tag.parse(ENV['LANG']).to_simple.to_s[0..1]

    I18n.locale = options[:lang].to_sym

    @config.setup(options)

    load_config

    puts "#{I18n.t('form.setup_config.valid')}".green
  rescue Exception => e
    puts "#{I18n.t('display.error')} #8: #{e}".red
    exit 2
  end

  # Setup a new GPG key
  # @args: gpg_key -> the key name
  def setup_gpg_key(gpg_key)
    return if @config.check_gpg_key?

    password = ask(I18n.t('form.setup_gpg_key.password')) {|q| q.echo = false}
    confirm  = ask(I18n.t('form.setup_gpg_key.confirm_password')) {|q| q.echo = false}

    if password != confirm
      raise I18n.t('form.setup_gpg_key.error_password')
    end

    @password = password.to_s

    puts I18n.t('form.setup_gpg_key.wait')

    @config.setup_gpg_key(@password, gpg_key)

    puts "#{I18n.t('form.setup_gpg_key.valid')}".green
  rescue Exception => e
    puts "#{I18n.t('display.error')} #8: #{e}".red
    exit 2
  end

  # List gpg keys in wallet
  def list_keys
    table_list('keys', @mpw.list_keys)
  end

  # Load config
  def load_config
    @config.load_config

  rescue Exception => e
    puts "#{I18n.t('display.error')} #10: #{e}".red
    exit 2
  end

  # Request the GPG password and decrypt the file
  def decrypt
    unless defined?(@mpw)
      @password = ask(I18n.t('display.gpg_password')) {|q| q.echo = false}
      @mpw      = MPW.new(@config.gpg_key, @wallet_file, @password, @config.gpg_exe)
    end

    @mpw.read_data
  rescue Exception => e
    puts "#{I18n.t('display.error')} #11: #{e}".red
    exit 2
  end

  # Format list on a table
  def table_list(title, list)
    i      = 1
    length = 0

    list.each do |item|
      length = item.length if length < item.length
    end
    length += 7

    puts "\n#{I18n.t("display.#{title}")}".red
    print ' '
    length.times { print '=' }
    print "\n"

    list.each do |item|
      print "  #{i}".cyan
      (3 - i.to_s.length).times { print ' ' }
      puts "| #{item}"
      i += 1
    end

    print "\n"
  end

  # Format items on a table
  def table_items(items=[])
    group        = '.'
    i            = 1
    length_total = 10
    data         = { id:       { length: 3,  color: 'cyan' },
                     host:     { length: 9,  color: 'yellow' },
                     user:     { length: 7,  color: 'green' },
                     protocol: { length: 9,  color: 'white' },
                     port:     { length: 5,  color: 'white' },
                     otp:      { length: 4,  color: 'white' },
                     comment:  { length: 14, color: 'magenta' },
                   }

    items.each do |item|
      data.each do |k, v|
        next if k == :id or k == :otp

        v[:length] = item.send(k.to_s).to_s.length + 3 if item.send(k.to_s).to_s.length >= v[:length]
      end
    end
    data[:id][:length]  = items.length.to_s.length + 2 if items.length.to_s.length > data[:id][:length]

    data.each_value { |v| length_total += v[:length] }
    items.sort!     { |a, b| a.group.to_s.downcase <=> b.group.to_s.downcase }

    items.each do |item|
      if group != item.group
        group = item.group

        if group.to_s.empty?
          puts "\n#{I18n.t('display.no_group')}".red
        else
          puts "\n#{group}".red
        end

        print ' '
        length_total.times { print '=' }
        print "\n "
        data.each do |k, v|
          case k
          when :id
            print ' ID'
          when :otp
            print '| OTP'
          else
            print "| #{k.to_s.capitalize}"
          end

          (v[:length] - k.to_s.length).times { print ' ' }
        end
        print "\n "
        length_total.times { print '=' }
        print "\n"
      end

      print "  #{i}".send(data[:id][:color])
      (data[:id][:length] - i.to_s.length).times { print ' ' }
      data.each do |k, v|
        next if k == :id

        if k == :otp
          print '| '
          if item.otp;  print ' X  ' else 4.times { print ' ' } end

          next
        end

        print '| '
        print "#{item.send(k.to_s)}".send(v[:color])
        (v[:length] - item.send(k.to_s).to_s.length).times { print ' ' }
      end
      print "\n"

      i += 1
    end

    print "\n"
  end

  # Display the query's result
  # @args: options -> the option to search
  def list(options={})
    result = @mpw.list(options)

    if result.length == 0
      puts I18n.t('display.nothing')
    else
      table_items(result)
    end
  end

  # Get an item when multiple choice
  # @args: items -> array of items
  # @rtrn: item
  def get_item(items)
    return items[0] if items.length == 1

    items.sort! { |a,b| a.group.to_s.downcase <=> b.group.to_s.downcase }
    choice = ask(I18n.t('form.select')).to_i

    if choice >= 1 and choice <= items.length
      return items[choice-1]
    else
      return nil
    end
  end

  # Copy in clipboard the login and password
  # @args: item -> the item
  #        clipboard -> enable clipboard
  def clipboard(item, clipboard=true)
    pid = nil

    # Security: force quit after 90s
    Thread.new do
      sleep 90
      exit
    end

    while true
      choice = ask(I18n.t('form.clipboard.choice')).to_s

      case choice
      when 'q', 'quit'
        break

      when 'l', 'login'
        if clipboard
          Clipboard.copy(item.user)
          puts I18n.t('form.clipboard.login').green
        else
          puts item.user
        end

      when 'p', 'password'
        if clipboard
          Clipboard.copy(@mpw.get_password(item.id))
          puts I18n.t('form.clipboard.password').yellow

          Thread.new do
            sleep 30

            Clipboard.clear
          end
        else
          puts @mpw.get_password(item.id)
        end

      when 'o', 'otp'
        if clipboard
          Clipboard.copy(@mpw.get_otp_code(item.id))
        else
          puts @mpw.get_otp_code(item.id)
        end
        puts I18n.t('form.clipboard.otp', time: @mpw.get_otp_remaining_time).yellow

      else
        puts "----- #{I18n.t('form.clipboard.help.name')} -----".cyan
        puts I18n.t('form.clipboard.help.login')
        puts I18n.t('form.clipboard.help.password')
        puts I18n.t('form.clipboard.help.otp_code')
        puts I18n.t('form.clipboard.help.quit')
        next
      end
    end

    Clipboard.clear
  rescue SystemExit, Interrupt
    Clipboard.clear
  end

  # List all wallets
  def list_wallet
    wallets = []
    Dir.glob("#{@config.wallet_dir}/*.mpw").each do |f|
      wallet = File.basename(f, '.mpw')
      wallet += ' *'.green if wallet == @config.default_wallet
      wallets << wallet
    end

    table_list('wallets', wallets)
  end

  # Display the wallet
  # @args: wallet -> the wallet name
  def get_wallet(wallet=nil)
    if wallet.to_s.empty?
      wallets = Dir.glob("#{@config.wallet_dir}/*.mpw")

      if wallets.length == 1
        @wallet_file = wallets[0]
      elsif not @config.default_wallet.to_s.empty?
        @wallet_file = "#{@config.wallet_dir}/#{@config.default_wallet}.mpw"
      else
        @wallet_file = "#{@config.wallet_dir}/default.mpw"
      end
    else
      @wallet_file = "#{@config.wallet_dir}/#{wallet}.mpw"
    end
  end

  # Add a new public key
  # args: key -> the key name or key file to add
  def add_key(key)
    @mpw.add_key(key)
    @mpw.write_data

    puts "#{I18n.t('form.add_key.valid')}".green
  rescue Exception => e
    puts "#{I18n.t('display.error')} #13: #{e}".red
  end

  # Add new public key
  # args: key -> the key name to delete
  def delete_key(key)
    @mpw.delete_key(key)
    @mpw.write_data

    puts "#{I18n.t('form.delete_key.valid')}".green
  rescue Exception => e
    puts "#{I18n.t('display.error')} #15: #{e}".red
  end

  # Text editor interface
  # @args: template -> template name
  #        item -> the item to edit
  #        password -> disable field password
  def text_editor(template_name, item=nil, password=false)
    editor        = ENV['EDITOR'] || 'nano'
    options       = {}
    opts          = {}
    template_file = "#{File.expand_path('../../../templates', __FILE__)}/#{template_name}.erb"
    template      = ERB.new(IO.read(template_file))

    Dir.mktmpdir do |dir|
      tmp_file = "#{dir}/#{template_name}.yml"

      File.open(tmp_file, 'w') do |f|
        f << template.result(binding)
      end

      system("#{editor} #{tmp_file}")

      opts = YAML::load_file(tmp_file)
    end

    opts.delete_if { |k,v| v.to_s.empty? }

    opts.each do |k,v|
      options[k.to_sym] = v
    end

    return options
  end

  # Form to add a new item
  # @args: password -> generate a random password
  def add(password=false)
    options            = text_editor('add_form', nil, password)
    item               = Item.new(options)
    options[:password] = MPW::password(@config.password) if password

    @mpw.add(item)
    @mpw.set_password(item.id, options[:password]) if options.has_key?(:password)
    @mpw.set_otp_key(item.id, options[:otp_key])   if options.has_key?(:otp_key)
    @mpw.write_data

    puts "#{I18n.t('form.add_item.valid')}".green
  rescue Exception => e
    puts "#{I18n.t('display.error')} #13: #{e}".red
  end

  # Update an item
  # @args: password -> generate a random password
  #        options -> the option to search
  def update(password=false, options={})
    items = @mpw.list(options)

    if items.length == 0
      puts "#{I18n.t('display.warning')}: #{I18n.t('warning.select')}".yellow
    else
      table_items(items) if items.length > 1

      item               = get_item(items)
      options            = text_editor('update_form', item, password)
            options[:password] = MPW::password(@config.password) if password

      item.update(options)
      @mpw.set_password(item.id, options[:password]) if options.has_key?(:password)
      @mpw.set_otp_key(item.id, options[:otp_key])   if options.has_key?(:otp_key)
      @mpw.write_data

      puts "#{I18n.t('form.update_item.valid')}".green
    end
  rescue Exception => e
    puts "#{I18n.t('display.error')} #14: #{e}".red
  end

  # Remove an item
  # @args: options -> the option to search
  def delete(options={})
    items = @mpw.list(options)

    if items.length == 0
      puts "#{I18n.t('display.warning')}: #{I18n.t('warning.select')}".yellow
    else
      table_items(items)

      item    = get_item(items)
      confirm = ask("#{I18n.t('form.delete_item.ask')} (y/N) ").to_s

      return false unless confirm =~ /^(y|yes|YES|Yes|Y)$/

      item.delete
      @mpw.write_data

      puts "#{I18n.t('form.delete_item.valid')}".green
    end
  rescue Exception => e
    puts "#{I18n.t('display.error')} #16: #{e}".red
  end

  # Copy a password, otp, login
  # @args: clipboard -> enable clipboard
  #        options -> the option to search
  def copy(clipboard=true, options={})
    items = @mpw.list(options)

    if items.length == 0
      puts I18n.t('display.nothing')
    else
      table_items(items)

      item = get_item(items)
      clipboard(item, clipboard)
    end
  rescue Exception => e
    puts "#{I18n.t('display.error')} #14: #{e}".red
  end

  # Export the items in a CSV file
  # @args: file -> the destination file
  #        options -> option to search
  def export(file, options)
    file  = 'export-mpw.yml' if file.to_s.empty?
    items = @mpw.list(options)
    data  = {}

    items.each do |item|
      data.merge!(item.id => { 'host'      => item.host,
                               'user'      => item.user,
                               'group'     => item.group,
                               'password'  => @mpw.get_password(item.id),
                               'protocol'  => item.protocol,
                               'port'      => item.port,
                               'otp_key'   => @mpw.get_otp_key(item.id),
                               'comment'   => item.comment,
                               'last_edit' => item.last_edit,
                               'created'   => item.created,
                             }
                  )
    end

    File.open(file, 'w') {|f| f << data.to_yaml}

    puts "#{I18n.t('form.export.valid', file: file)}".green
  rescue Exception => e
    puts "#{I18n.t('display.error')} #17: #{e}".red
  end

  # Import items from a YAML file
  # @args: file -> the import file
  def import(file)
    raise I18n.t('form.import.file_empty')     if file.to_s.empty?
    raise I18n.t('form.import.file_not_exist') unless File.exist?(file)

    YAML::load_file(file).each_value do |row|
      item = Item.new(group:    row['group'],
                      host:     row['host'],
                      protocol: row['protocol'],
                      user:     row['user'],
                      port:     row['port'],
                      comment:  row['comment'],
                     )

      next if item.empty?

      @mpw.add(item)
      @mpw.set_password(item.id, row['password']) unless row['password'].to_s.empty?
      @mpw.set_otp_key(item.id, row['otp_key'])   unless row['otp_key'].to_s.empty?
    end

    @mpw.write_data

    puts "#{I18n.t('form.import.valid')}".green
  rescue Exception => e
    puts "#{I18n.t('display.error')} #18: #{e}".red
  end
end
end
