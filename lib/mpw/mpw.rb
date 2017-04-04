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

require 'rubygems/package'
require 'gpgme'
require 'i18n'
require 'yaml'
require 'rotp'
require 'mpw/item'

module MPW
  class MPW
    # Constructor
    def initialize(key, wallet_file, gpg_pass = nil, gpg_exe = nil, pinmode = false)
      @key         = key
      @gpg_pass    = gpg_pass
      @gpg_exe     = gpg_exe
      @wallet_file = wallet_file
      @pinmode     = pinmode

      GPGME::Engine.set_info(GPGME::PROTOCOL_OpenPGP, @gpg_exe, "#{Dir.home}/.gnupg") unless @gpg_exe.to_s.empty?
    end

    # Read mpw file
    def read_data
      @config    = {}
      @data      = []
      @keys      = {}
      @passwords = {}
      @otp_keys  = {}

      data       = nil

      return unless File.exist?(@wallet_file)

      Gem::Package::TarReader.new(File.open(@wallet_file)) do |tar|
        tar.each do |f|
          case f.full_name
          when 'wallet/config.gpg'
            @config = YAML.safe_load(decrypt(f.read))

          when 'wallet/meta.gpg'
            data = decrypt(f.read)

          when %r{^wallet/keys/(?<key>.+)\.pub$}
            key = Regexp.last_match('key')

            if GPGME::Key.find(:public, key).empty?
              GPGME::Key.import(f.read, armor: true)
            end

            @keys[key] = f.read

          when %r{^wallet/passwords/(?<id>[a-zA-Z0-9]+)\.gpg$}
            @passwords[Regexp.last_match('id')] = f.read

          when %r{^wallet/otp_keys/(?<id>[a-zA-Z0-9]+)\.gpg$}
            @otp_keys[Regexp.last_match('id')] = f.read

          else
            next
          end
        end
      end

      unless data.to_s.empty?
        YAML.safe_load(data).each_value do |d|
          @data.push(
            Item.new(
              id:        d['id'],
              group:     d['group'],
              host:      d['host'],
              protocol:  d['protocol'],
              user:      d['user'],
              port:      d['port'],
              otp:       @otp_keys.key?(d['id']),
              comment:   d['comment'],
              last_edit: d['last_edit'],
              created:   d['created'],
            )
          )
        end
      end

      add_key(@key) if @keys[@key].nil?
    rescue => e
      raise "#{I18n.t('error.mpw_file.read_data')}\n#{e}"
    end

    # Encrypt a file
    def write_data
      data     = {}
      tmp_file = "#{@wallet_file}.tmp"

      @data.each do |item|
        next if item.empty?

        data.merge!(
          item.id => {
            'id'        => item.id,
            'group'     => item.group,
            'host'      => item.host,
            'protocol'  => item.protocol,
            'user'      => item.user,
            'port'      => item.port,
            'comment'   => item.comment,
            'last_edit' => item.last_edit,
            'created'   => item.created,
          }
        )
      end

      @config['last_update'] = Time.now.to_i

      Gem::Package::TarWriter.new(File.open(tmp_file, 'w+')) do |tar|
        data_encrypt = encrypt(data.to_yaml)
        tar.add_file_simple('wallet/meta.gpg', 0400, data_encrypt.length) do |io|
          io.write(data_encrypt)
        end

        config = encrypt(@config.to_yaml)
        tar.add_file_simple('wallet/config.gpg', 0400, config.length) do |io|
          io.write(config)
        end

        @passwords.each do |id, password|
          tar.add_file_simple("wallet/passwords/#{id}.gpg", 0400, password.length) do |io|
            io.write(password)
          end
        end

        @otp_keys.each do |id, key|
          tar.add_file_simple("wallet/otp_keys/#{id}.gpg", 0400, key.length) do |io|
            io.write(key)
          end
        end

        @keys.each do |id, key|
          tar.add_file_simple("wallet/keys/#{id}.pub", 0400, key.length) do |io|
            io.write(key)
          end
        end
      end

      File.rename(tmp_file, @wallet_file)
    rescue => e
      File.unlink(tmp_file) if File.exist?(tmp_file)

      raise "#{I18n.t('error.mpw_file.write_data')}\n#{e}"
    end

    # Get a password
    # args: id -> the item id
    def get_password(id)
      password = decrypt(@passwords[id])

      if /^\$[a-zA-Z0-9]{4,9}::(?<password>.+)$/ =~ password
        Regexp.last_match('password')
      else
        password
      end
    end

    # Set a password
    # args: id -> the item id
    #       password -> the new password
    def set_password(id, password)
      salt     = MPW.password(length: Random.rand(4..9))
      password = "$#{salt}::#{password}"

      @passwords[id] = encrypt(password)
    end

    # Return the list of all gpg keys
    # rtrn: an array with the gpg keys name
    def list_keys
      @keys.keys
    end

    # Add a public key
    # args: key ->  new public key file or name
    def add_key(key)
      if File.exist?(key)
        data       = File.open(key).read
        key_import = GPGME::Key.import(data, armor: true)
        key        = GPGME::Key.get(key_import.imports[0].fpr).uids[0].email
      else
        data = GPGME::Key.export(key, armor: true).read
      end

      raise I18n.t('error.export_key') if data.to_s.empty?

      @keys[key] = data
      @passwords.each_key { |id| set_password(id, get_password(id)) }
      @otp_keys.each_key { |id| set_otp_key(id, get_otp_key(id)) }
    end

    # Delete a public key
    # args: key ->  public key to delete
    def delete_key(key)
      @keys.delete(key)
      @passwords.each_key { |id| set_password(id, get_password(id)) }
      @otp_keys.each_key { |id| set_otp_key(id, get_otp_key(id)) }
    end

    # Set config
    # args: config -> a hash with config options
    def set_config(**options)
      @config              = {} if @config.nil?

      @config['protocol']  = options[:protocol] if options.key?(:protocol)
      @config['host']      = options[:host]     if options.key?(:host)
      @config['port']      = options[:port]     if options.key?(:port)
      @config['user']      = options[:user]     if options.key?(:user)
      @config['password']  = options[:password] if options.key?(:password)
      @config['path']      = options[:path]     if options.key?(:path)
    end

    # Add a new item
    # @args: item -> Object MPW::Item
    def add(item)
      raise I18n.t('error.bad_class') unless item.instance_of?(Item)
      raise I18n.t('error.empty')     if item.empty?

      @data.push(item)
    end

    # Search in some csv data
    # @args: options -> a hash with paramaters
    # @rtrn: a list with the resultat of the search
    def list(**options)
      result = []

      search = options[:pattern].to_s.downcase
      group  = options[:group].to_s.downcase

      @data.each do |item|
        next if item.empty?
        next unless group.empty? || group.eql?(item.group.to_s.downcase)

        host    = item.host.to_s.downcase
        comment = item.comment.to_s.downcase

        next unless host =~ /^.*#{search}.*$/ || comment =~ /^.*#{search}.*$/

        result.push(item)
      end

      result
    end

    # Search in some csv data
    # @args: id -> the id item
    # @rtrn: a row with the result of the search
    def search_by_id(id)
      @data.each do |item|
        return item if item.id == id
      end

      nil
    end

    # Set an opt key
    # args: id -> the item id
    #       key -> the new key
    def set_otp_key(id, key)
      @otp_keys[id] = encrypt(key.to_s) unless key.to_s.empty?
    end

    # Get an opt key
    # args: id -> the item id
    #       key -> the new key
    def get_otp_key(id)
      @otp_keys.key?(id) ? decrypt(@otp_keys[id]) : nil
    end

    # Get an otp code
    # @args: id -> the item id
    # @rtrn: an otp code
    def get_otp_code(id)
      @otp_keys.key?(id) ? 0 : ROTP::TOTP.new(decrypt(@otp_keys[id])).now
    end

    # Get remaining time before expire otp code
    # @rtrn: return time in seconde
    def get_otp_remaining_time
      (Time.now.utc.to_i / 30 + 1) * 30 - Time.now.utc.to_i
    end

    # Generate a random password
    # @args: options -> :length, :special, :alpha, :numeric
    # @rtrn: a random string
    def self.password(**options)
      length =
        if !options.include?(:length) || options[:length].to_i <= 0
          8
        elsif options[:length].to_i >= 32_768
          32_768
        else
          options[:length].to_i
        end

      chars = []
      chars += [*('!'..'?')] - [*('0'..'9')]          if options[:special]
      chars += [*('A'..'Z'), *('a'..'z')]             if options[:alpha]
      chars += [*('0'..'9')]                          if options[:numeric]
      chars = [*('A'..'Z'), *('a'..'z'), *('0'..'9')] if chars.empty?

      result = ''
      while length > 62
        result << chars.sample(62).join
        length -= 62
      end
      result << chars.sample(length).join

      result
    end

    private

    # Decrypt a gpg file
    # @args: data -> string to decrypt
    def decrypt(data)
      return nil if data.to_s.empty?

      password =
        if /^(1\.[0-9.]+|2\.0)(\.[0-9]+)?/ =~ GPGME::Engine.info.first.version || @pinmode
          { password: @gpg_pass }
        else
          { password: @gpg_pass,
            pinentry_mode: GPGME::PINENTRY_MODE_LOOPBACK }
        end

      crypto = GPGME::Crypto.new(armor: true)
      crypto
        .decrypt(data, password)
        .read.force_encoding('utf-8')
    rescue => e
      raise "#{I18n.t('error.gpg_file.decrypt')}\n#{e}"
    end

    # Encrypt a file
    # args: data -> string to encrypt
    def encrypt(data)
      recipients = []
      crypto     = GPGME::Crypto.new(armor: true, always_trust: true)

      recipients.push(@key)
      @keys.each_key do |key|
        next if key == @key
        recipients.push(key)
      end

      crypto.encrypt(data, recipients: recipients).read
    rescue => e
      raise "#{I18n.t('error.gpg_file.encrypt')}\n#{e}"
    end
  end
end
