#
# Copyright:: 2013, Adrien Waksberg
#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

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
    # @param config [Config]
    def initialize(config)
      @config = config
    end

    # Change a parameter int the config after init
    # @param options [Hash] param to change
    def set_config(options)
      @config.setup(options)

      puts I18n.t('form.set_config.valid').to_s.green
    rescue => e
      puts "#{I18n.t('display.error')} #15: #{e}".red
      exit 2
    end

    # Change the wallet path
    # @param path [String] new path
    def set_wallet_path(path)
      @config.set_wallet_path(path, @wallet)

      puts I18n.t('form.set_wallet_path.valid').to_s.green
    rescue => e
      puts "#{I18n.t('display.error')} #19: #{e}".red
      exit 2
    end

    # Create a new config file
    # @param options [Hash]
    def setup(options)
      options[:lang] = options[:lang] || Locale::Tag.parse(ENV['LANG']).to_simple.to_s[0..1]

      I18n.locale = options[:lang].to_sym

      @config.setup(options)

      load_config

      puts I18n.t('form.setup_config.valid').to_s.green
    rescue => e
      puts "#{I18n.t('display.error')} #8: #{e}".red
      exit 2
    end

    # Setup a new GPG key
    # @param gpg_key [String] gpg key name
    def setup_gpg_key(gpg_key)
      return if @config.check_gpg_key?

      password = ask(I18n.t('form.setup_gpg_key.password')) { |q| q.echo = false }
      confirm  = ask(I18n.t('form.setup_gpg_key.confirm_password')) { |q| q.echo = false }

      raise I18n.t('form.setup_gpg_key.error_password') if password != confirm

      @password = password.to_s

      puts I18n.t('form.setup_gpg_key.wait')

      @config.setup_gpg_key(@password, gpg_key)

      puts I18n.t('form.setup_gpg_key.valid').to_s.green
    rescue => e
      puts "#{I18n.t('display.error')} #8: #{e}".red
      exit 2
    end

    # List gpg keys in wallet
    def list_keys
      table_list('keys', @mpw.list_keys)
    end

    # List config
    def list_config
      config = {
        'lang'           => @config.lang,
        'gpg_key'        => @config.gpg_key,
        'default_wallet' => @config.default_wallet,
        'wallet_dir'     => @config.wallet_dir,
        'pinmode'        => @config.pinmode,
        'gpg_exe'        => @config.gpg_exe
      }

      @config.wallet_paths.each { |k, v| config["path_wallet_#{k}"] = "#{v}/#{k}.mpw" }
      @config.password.each     { |k, v| config["password_#{k}"] = v }

      table_list('config', config)
    end

    # Load config
    def load_config
      @config.load_config
    rescue => e
      puts "#{I18n.t('display.error')} #10: #{e}".red
      exit 2
    end

    # Request the GPG password and decrypt the file
    def decrypt
      if defined?(@mpw)
        @mpw.read_data
      else
        begin
          @mpw = MPW.new(@config.gpg_key, @wallet_file, nil, @config.gpg_exe, @config.pinmode)

          @mpw.read_data
        rescue
          @password = ask(I18n.t('display.gpg_password')) { |q| q.echo = false }
          @mpw      = MPW.new(@config.gpg_key, @wallet_file, @password, @config.gpg_exe, @config.pinmode)

          @mpw.read_data
        end
      end
    rescue => e
      puts "#{I18n.t('display.error')} #11: #{e}".red
      exit 2
    end

    # Format list on a table
    # @param title [String] name of table
    # @param list  an array or hash
    def table_list(title, list)
      length = { k: 0, v: 0 }

      if list.is_a?(Array)
        i    = 0
        list = list.map do |item|
          i += 1
          [i, item]
        end.to_h
      end

      list.each do |k, v|
        length[:k] = k.to_s.length if length[:k] < k.to_s.length
        length[:v] = v.to_s.length if length[:v] < v.to_s.length
      end

      puts "\n#{I18n.t("display.#{title}")}".red
      print ' '
      (length[:k] + length[:v] + 5).times { print '=' }
      print "\n"

      list.each do |k, v|
        print "  #{k}".cyan
        (length[:k] - k.to_s.length + 1).times { print ' ' }
        puts "| #{v}"
      end

      print "\n"
    end

    # Format items on a table
    # @param items [Array]
    def table_items(items = [])
      group        = '.'
      i            = 1
      length_total = 10
      data         = { id:       { length: 3,  color: 'cyan' },
                       host:     { length: 9,  color: 'yellow' },
                       user:     { length: 7,  color: 'green' },
                       otp:      { length: 4,  color: 'white' },
                       comment:  { length: 14, color: 'magenta' } }

      items.each do |item|
        data.each do |k, v|
          case k
          when :id, :otp
            next
          when :host
            v[:length] = item.url.length + 3 if item.url.length >= v[:length]
          else
            v[:length] = item.send(k.to_s).to_s.length + 3 if item.send(k.to_s).to_s.length >= v[:length]
          end
        end
      end
      data[:id][:length] = items.length.to_s.length + 2 if items.length.to_s.length > data[:id][:length]

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

          print '| '

          case k
          when :otp
            item.otp ? (print ' X  ') : 4.times { print ' ' }

          when :host
            print "#{item.protocol}://".light_black if item.protocol
            print item.host.send(v[:color])
            print ":#{item.port}".light_black if item.port
            (v[:length] - item.url.to_s.length).times { print ' ' }

          else
            print item.send(k.to_s).to_s.send(v[:color])
            (v[:length] - item.send(k.to_s).to_s.length).times { print ' ' }
          end
        end
        print "\n"

        i += 1
      end

      print "\n"
    end

    # Display the query's result
    # @param options [Hash] the options to search
    def list(**options)
      result = @mpw.list(options)

      if result.empty?
        puts I18n.t('display.nothing')
      else
        table_items(result)
      end
    end

    # Get an item when multiple choice
    # @param items [Array] list of items
    # @return [Item] an item
    def get_item(items)
      return items[0] if items.length == 1

      items.sort! { |a, b| a.group.to_s.downcase <=> b.group.to_s.downcase }
      choice = ask(I18n.t('form.select.choice')).to_i

      raise I18n.t('form.select.error') unless choice >= 1 && choice <= items.length

      items[choice - 1]
    end

    # Print help message for clipboard mode
    # @param item [Item]
    def clipboard_help(item)
      puts "----- #{I18n.t('form.clipboard.help.name')} -----".cyan
      puts I18n.t('form.clipboard.help.url')
      puts I18n.t('form.clipboard.help.login')
      puts I18n.t('form.clipboard.help.password')
      puts I18n.t('form.clipboard.help.otp_code') if item.otp
      puts I18n.t('form.clipboard.help.quit')
    end

    # Copy in clipboard the login and password
    # @param item [Item]
    # @param clipboard [Boolean] enable clipboard
    def clipboard(item, clipboard = true)
      # Security: force quit after 90s
      Thread.new do
        sleep 90
        exit
      end

      Kernel.loop do
        choice = ask(I18n.t('form.clipboard.choice')).to_s

        case choice
        when 'q', 'quit'
          break

        when 'u', 'url'
          if clipboard
            Clipboard.copy(item.url)
            puts I18n.t('form.clipboard.url').green
          else
            puts item.url
          end

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
          if !item.otp
            clipboard_help(item)
            next
          elsif clipboard
            Clipboard.copy(@mpw.get_otp_code(item.id))
          else
            puts @mpw.get_otp_code(item.id)
          end
          puts I18n.t('form.clipboard.otp', time: @mpw.get_otp_remaining_time).yellow

        else
          clipboard_help(item)
        end
      end

      Clipboard.clear
    rescue SystemExit, Interrupt
      Clipboard.clear
    end

    # List all wallets
    def list_wallet
      wallets = @config.wallet_paths.keys

      Dir.glob("#{@config.wallet_dir}/*.mpw").each do |f|
        wallet = File.basename(f, '.mpw')
        wallet += ' *'.green if wallet == @config.default_wallet
        wallets << wallet
      end

      table_list('wallets', wallets)
    end

    # Display the wallet
    # @param wallet [String] wallet name
    def get_wallet(wallet = nil)
      @wallet =
        if wallet.to_s.empty?
          wallets = Dir.glob("#{@config.wallet_dir}/*.mpw")
          if wallets.length == 1
            File.basename(wallets[0], '.mpw')
          elsif !@config.default_wallet.to_s.empty?
            @config.default_wallet
          else
            'default'
          end
        else
          wallet
        end

      @wallet_file =
        if @config.wallet_paths.key?(@wallet)
          "#{@config.wallet_paths[@wallet]}/#{@wallet}.mpw"
        else
          "#{@config.wallet_dir}/#{@wallet}.mpw"
        end
    end

    # Add a new public key
    # @param key [String] key name or key file to add
    def add_key(key)
      @mpw.add_key(key)
      @mpw.write_data

      puts I18n.t('form.add_key.valid').to_s.green
    rescue => e
      puts "#{I18n.t('display.error')} #13: #{e}".red
    end

    # Add new public key
    # @param key [String] key name to delete
    def delete_key(key)
      @mpw.delete_key(key)
      @mpw.write_data

      puts I18n.t('form.delete_key.valid').to_s.green
    rescue => e
      puts "#{I18n.t('display.error')} #15: #{e}".red
    end

    # Text editor interface
    # @param template_name [String] template name
    # @param item [Item] the item to edit
    # @param password [Boolean] disable field password
    # @return [Hash] the values for an item
    def text_editor(template_name, password = false, item = nil, **options)
      editor        = ENV['EDITOR'] || 'nano'
      opts          = {}
      template_file = "#{File.expand_path('../../../templates', __FILE__)}/#{template_name}.erb"
      template      = ERB.new(IO.read(template_file))

      Dir.mktmpdir do |dir|
        tmp_file = "#{dir}/#{template_name}.yml"

        File.open(tmp_file, 'w') do |f|
          f << template.result(binding)
        end

        system("#{editor} #{tmp_file}")

        opts = YAML.load_file(tmp_file)
      end

      opts.delete_if { |_, v| v.to_s.empty? }

      opts.each do |k, v|
        options[k.to_sym] = v
      end

      options
    end

    # Form to add a new item
    # @param password [Boolean] generate a random password
    # @param text_editor [Boolean] enable text editor mode
    # @param values [Hash] multiples value to set the item
    def add(password = false, text_editor = false, **values)
      options            = text_editor('add_form', password, nil, values) if text_editor
      item               = Item.new(options)
      options[:password] = MPW.password(@config.password) if password

      @mpw.add(item)
      @mpw.set_password(item.id, options[:password]) if options.key?(:password)
      @mpw.set_otp_key(item.id, options[:otp_key])   if options.key?(:otp_key)
      @mpw.write_data

      puts I18n.t('form.add_item.valid').to_s.green
    rescue => e
      puts "#{I18n.t('display.error')} #13: #{e}".red
    end

    # Update an item
    # @param password [Boolean] generate a random password
    # @param text_editor [Boolean] enable text editor mode
    # @param options [Hash] the options to search
    # @param values [Hash] multiples value to set the item
    def update(password = false, text_editor = false, options = {}, **values)
      items = @mpw.list(options)

      if items.empty?
        puts I18n.t('display.nothing')
      else
        table_items(items) if items.length > 1

        item              = get_item(items)
        values            = text_editor('update_form', password, item, values) if text_editor
        values[:password] = MPW.password(@config.password) if password

        item.update(values)
        @mpw.set_password(item.id, values[:password]) if values.key?(:password)
        @mpw.set_otp_key(item.id, values[:otp_key])   if values.key?(:otp_key)
        @mpw.write_data

        puts I18n.t('form.update_item.valid').to_s.green
      end
    rescue => e
      puts "#{I18n.t('display.error')} #14: #{e}".red
    end

    # Remove an item
    # @param options [Hash] the options to search
    def delete(**options)
      items = @mpw.list(options)

      if items.empty?
        puts I18n.t('display.nothing')
      else
        table_items(items)

        item    = get_item(items)
        confirm = ask("#{I18n.t('form.delete_item.ask')} (y/N) ").to_s

        return unless confirm =~ /^(y|yes|YES|Yes|Y)$/

        item.delete
        @mpw.write_data

        puts I18n.t('form.delete_item.valid').to_s.green
      end
    rescue => e
      puts "#{I18n.t('display.error')} #16: #{e}".red
    end

    # Copy a password, otp, login
    # @param clipboard [Boolean] enable clipboard
    # @param options [Hash] the options to search
    def copy(clipboard = true, **options)
      items = @mpw.list(options)

      if items.empty?
        puts I18n.t('display.nothing')
      else
        table_items(items)

        item = get_item(items)
        clipboard(item, clipboard)
      end
    rescue => e
      puts "#{I18n.t('display.error')} #14: #{e}".red
    end

    # Export the items in an yaml file
    # @param file [String] the path of destination file
    # @param options [Hash] options to search
    def export(file, options)
      file  = 'export-mpw.yml' if file.to_s.empty?
      items = @mpw.list(options)
      data  = {}

      items.each do |item|
        data.merge!(
          item.id => {
            'comment'   => item.comment,
            'created'   => item.created,
            'group'     => item.group,
            'last_edit' => item.last_edit,
            'otp_key'   => @mpw.get_otp_key(item.id),
            'password'  => @mpw.get_password(item.id),
            'url'       => item.url,
            'user'      => item.user
          }
        )
      end

      File.open(file, 'w') { |f| f << data.to_yaml }

      puts I18n.t('form.export.valid', file: file).to_s.green
    rescue => e
      puts "#{I18n.t('display.error')} #17: #{e}".red
    end

    # Import items from an yaml file
    # @param file [String] path of import file
    # @param format [String] the software import file format
    def import(file, format = 'mpw')
      raise I18n.t('form.import.file_empty')     if file.to_s.empty?
      raise I18n.t('form.import.file_not_exist') unless File.exist?(file)

      begin
        require "mpw/import/#{format}"
      rescue LoadError
        raise I18n.t('form.import.format_unknown', file_format: format)
      end

      Import.send(format, file).each_value do |row|
        item = Item.new(
          comment:  row['comment'],
          group:    row['group'],
          url:      row['url'],
          user:     row['user']
        )

        next if item.empty?

        @mpw.add(item)
        @mpw.set_password(item.id, row['password']) unless row['password'].to_s.empty?
        @mpw.set_otp_key(item.id, row['otp_key'])   unless row['otp_key'].to_s.empty?
      end

      @mpw.write_data

      puts I18n.t('form.import.valid').to_s.green
    rescue => e
      puts "#{I18n.t('display.error')} #18: #{e}".red
    end
  end
end
