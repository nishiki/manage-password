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

require 'gpgme'
require 'git'
require 'i18n'
require 'yaml'
require 'rotp'
require 'mpw/item'

module MPW
  class MPW
    # @param key [String] gpg key name
    # @param wallet_file [String] path of the wallet file
    # @param gpg_pass [String] password of the gpg key
    # @param gpg_exe [String] path of the gpg executable
    # @param pinmode [Boolean] enable the gpg pinmode
    def initialize(key, wallet_path, gpg_pass = nil, gpg_exe = nil, pinmode = false)
      @key         = key
      @gpg_pass    = gpg_pass
      @gpg_exe     = gpg_exe
      @pinmode     = pinmode
      @wallet_path = wallet_path
      @wallet_name = File.basename(@wallet_path)
      @git         = Git.open(@wallet_path) if Dir.exist?(@wallet_path)
      @data        = []
      @keys        = {}
      @passwords   = {}
      @otp_keys    = {}

      GPGME::Engine.set_info(GPGME::PROTOCOL_OpenPGP, @gpg_exe, "#{Dir.home}/.gnupg") unless @gpg_exe.to_s.empty?
    end

    # Init a wallet folder
    # @param remote_uri [String] the uri of the remote git repository
    def init_wallet(remote_uri)
      Dir.mkdir(@wallet_path) unless Dir.exist?(@wallet_path)
      %w[passwords otp_keys keys].each do |folder|
        Dir.mkdir("#{@wallet_path}/#{folder}") unless Dir.exist?("#{@wallet_path}/#{folder}")
      end

      @git = remote_uri ? Git.clone(remote_uri, @wallet_name, path: @wallet_path) : Git.init(@wallet_path)
      @git.config('user.name', @key.split('@').first)
      @git.config('user.email', @key)
      @git.commit('init wallet', allow_empty: true) unless remote_uri
    rescue => e
      raise "#{I18n.t('error.init_wallet')}\n#{e}"
    end

    # Read mpw file
    def read_data
      return unless Dir.exist?(@wallet_path)

      meta_file = "#{@wallet_path}/meta.gpg"
      data      = File.exist?(meta_file) ? decrypt(File.read(meta_file)) : nil

      Dir["#{@wallet_path}/keys/*.pub"].each do |file|
        key        = File.basename(file, '.pub')
        @keys[key] = File.read(file)

        if GPGME::Key.find(:public, key).empty?
          GPGME::Key.import(@keys[key], armor: true)
        end
      end

      unless data.to_s.empty?
        YAML.safe_load(data).each_value do |d|
          @data.push(
            Item.new(
              id:        d['id'],
              group:     d['group'],
              user:      d['user'],
              url:       d['url'],
              otp:       File.exist?("#{@wallet_path}/otp_keys/#{d['id']}.gpg"),
              comment:   d['comment'],
              last_edit: d['last_edit'],
              created:   d['created']
            )
          )
        end
      end

      add_key(@key) unless @keys.key?(@key)
    rescue => e
      raise "#{I18n.t('error.mpw_file.read_data')}\n#{e}"
    end

    # Encrypt all data in tarball
    def write_data
      data = {}

      @data.each do |item|
        next if item.empty?

        data.merge!(
          item.id => {
            'id'        => item.id,
            'group'     => item.group,
            'user'      => item.user,
            'url'       => item.url,
            'comment'   => item.comment,
            'last_edit' => item.last_edit,
            'created'   => item.created
          }
        )
      end

      File.open("#{@wallet_path}/meta.gpg", 'w') do |file|
        file.chmod(0400)
        file << encrypt(data.to_yaml)
      end

      %w[passwords otp_keys].each do |folder|
        Dir["#{@wallet_path}/#{folder}/*.gpg"].each do |file|
          File.unlink(file) unless data.key?(File.basename(file, '.gpg'))
        end
      end

      @git.add
      @git.commit('wallet updated')
    rescue => e
      raise "#{I18n.t('error.mpw_file.write_data')}\n#{e}"
    end

    # Get a password
    # @param id [String] the item id
    def get_password(id)
      @passwords[id] = File.read("#{@wallet_path}/passwords/#{id}.gpg") unless @passwords[id]

      password = decrypt(@passwords[id])

      if /^\$[a-zA-Z0-9]{4,9}::(?<password>.+)$/ =~ password
        Regexp.last_match('password')
      else
        password
      end
    end

    # Set a new password for an item
    # @param id [String] the item id
    # @param password [String] the new password
    def set_password(id, password)
      salt           = MPW.password(length: Random.rand(4..9))
      @passwords[id] = encrypt("$#{salt}::#{password}")

      File.open("#{@wallet_path}/passwords/#{id}.gpg", 'w') do |file|
        file.chmod(0400)
        file << @passwords[id]
      end
    end

    # Return the list of all gpg keys
    # @return [Array] the gpg keys name
    def list_keys
      @keys.keys
    end

    # Add a public key
    # @param key [String] new public key file or name
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
      File.open("#{@wallet_path}/keys/#{key}.pub", 'w') do |file|
        file.chmod(0400)
        file << data
      end

      @passwords.each_key { |id| set_password(id, get_password(id)) }
      @otp_keys.each_key { |id| set_otp_key(id, get_otp_key(id)) }
    end

    # Delete a public key
    # @param key [String] public key to delete
    def delete_key(key)
      File.unlink("#{@wallet_path}/keys/#{key}.pub")

      @keys.delete(key)
      @passwords.each_key { |id| set_password(id, get_password(id)) }
      @otp_keys.each_key { |id| set_otp_key(id, get_otp_key(id)) }
    end

    # Add a new item
    # @param item [Item]
    def add(item)
      raise I18n.t('error.bad_class') unless item.instance_of?(Item)
      raise I18n.t('error.empty')     if item.empty?

      @data.push(item)
    end

    # Search in some csv data
    # @param options [Hash]
    # @return [Array] a list with the resultat of the search
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

    # Search an item with an id
    # @param id [String]the id item
    # @return [Item] an item or nil
    def search_by_id(id)
      @data.each do |item|
        return item if item.id == id
      end

      nil
    end

    # Set a new opt key
    # @param id [String] the item id
    # @param key [String] the new key
    def set_otp_key(id, key)
      return if key.to_s.empty?

      @otp_keys[id] = encrypt(key.to_s)

      File.open("#{@wallet_path}/otp_keys/#{id}.gpg", 'w') do |file|
        file.chmod(0400)
        file << @otp_keys[id]
      end
    end

    # Get an opt key
    # @param id [String] the item id
    def get_otp_key(id)
      otp_file = "#{@wallet_path}/otp_keys/#{id}.gpg"
      File.exist?(otp_file) ? decrypt(File.read(otp_file)) : nil
    end

    # Get an otp code
    # @param id [String] the item id
    # @return [String] an otp code
    def get_otp_code(id)
      otp_file = "#{@wallet_path}/otp_keys/#{id}.gpg"

      return 0 unless File.exist?(otp_file)

      @otp_keys[id] = File.read(otp_file) unless @otp_keys[id]
      ROTP::TOTP.new(decrypt(@otp_keys[id])).now
    end

    # Get remaining time before expire otp code
    # @return [Integer] time in seconde
    def get_otp_remaining_time
      (Time.now.utc.to_i / 30 + 1) * 30 - Time.now.utc.to_i
    end

    # Generate a random password
    # @param options [Hash] :length, :special, :alpha, :numeric
    # @return [String] a random string
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
      length.times do
        result << chars.sample
      end

      result
    end

    private

    # Decrypt a gpg file
    # @param data [String] data to decrypt
    # @return [String] data decrypted
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
    # @param data [String] data to encrypt
    # @return [String] data encrypted
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
