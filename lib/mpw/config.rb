#!/usr/bin/ruby
# MPW is a software to crypt and manage your passwords
# Copyright (C) 2017  Adrien Waksberg <mpw@yae.im>
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

require 'gpgme'
require 'yaml'
require 'i18n'
require 'fileutils'

module MPW
  class Config
    attr_accessor :error_msg

    attr_accessor :gpg_key
    attr_accessor :lang
    attr_accessor :config_dir
    attr_accessor :default_wallet
    attr_accessor :wallet_dir
    attr_accessor :wallet_paths
    attr_accessor :gpg_exe
    attr_accessor :password
    attr_accessor :pinmode

    # @param config_file [String] path of config file
    def initialize(config_file = nil)
      @config_file = config_file
      @config_dir  =
        if /darwin/ =~ RUBY_PLATFORM
          "#{Dir.home}/Library/Preferences/mpw"
        elsif /cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM
          "#{Dir.home}/AppData/Local/mpw"
        else
          "#{Dir.home}/.config/mpw"
        end

      @config_file = "#{@config_dir}/mpw.cfg" if @config_file.to_s.empty?
    end

    # Create a new config file
    # @param options [Hash] the value to set the config file
    def setup(**options)
      gpg_key        = options[:gpg_key]        || @gpg_key
      lang           = options[:lang]           || @lang
      wallet_dir     = options[:wallet_dir]     || @wallet_dir
      default_wallet = options[:default_wallet] || @default_wallet
      gpg_exe        = options[:gpg_exe]        || @gpg_exe
      pinmode        = options.key?(:pinmode) ? options[:pinmode] : @pinmode
      password       = {
        numeric: true,
        alpha:   true,
        special: false,
        length:  16
      }

      %w[numeric special alpha length].each do |k|
        if options.key?("pwd_#{k}".to_sym)
          password[k.to_sym] = options["pwd_#{k}".to_sym]
        elsif !@password.nil? && @password.key?(k.to_sym)
          password[k.to_sym] = @password[k.to_sym]
        end
      end

      unless gpg_key =~ /[a-zA-Z0-9.-_]+\@[a-zA-Z0-9]+\.[a-zA-Z]+/
        raise I18n.t('error.config.key_bad_format')
      end

      wallet_dir = "#{@config_dir}/wallets" if wallet_dir.to_s.empty?
      config     = { 'gpg_key'        => gpg_key,
                     'lang'           => lang,
                     'wallet_dir'     => wallet_dir,
                     'default_wallet' => default_wallet,
                     'gpg_exe'        => gpg_exe,
                     'password'       => password,
                     'pinmode'        => pinmode,
                     'wallet_paths'   => @wallet_paths }

      FileUtils.mkdir_p(@config_dir, mode: 0700)
      FileUtils.mkdir_p(wallet_dir,  mode: 0700)

      File.open(@config_file, 'w') do |file|
        file << config.to_yaml
      end
    rescue => e
      raise "#{I18n.t('error.config.write')}\n#{e}"
    end

    # Setup a new gpg key
    # @param password [String] gpg key password
    # @param name [String] the name of user
    # @param length [Integer] length of the gpg key
    # @param expire [Integer] time of expire to gpg key
    def setup_gpg_key(password, name, length = 4096, expire = 0)
      raise I18n.t('error.config.genkey_gpg.name') if name.to_s.empty?
      raise I18n.t('error.config.genkey_gpg.password') if password.to_s.empty?

      param = ''
      param << '<GnupgKeyParms format="internal">' + "\n"
      param << "Key-Type: RSA\n"
      param << "Key-Length: #{length}\n"
      param << "Subkey-Type: ELG-E\n"
      param << "Subkey-Length: #{length}\n"
      param << "Name-Real: #{name}\n"
      param << "Name-Comment: #{name}\n"
      param << "Name-Email: #{@gpg_key}\n"
      param << "Expire-Date: #{expire}\n"
      param << "Passphrase: #{password}\n"
      param << "</GnupgKeyParms>\n"

      ctx = GPGME::Ctx.new
      ctx.genkey(param, nil, nil)
    rescue => e
      raise "#{I18n.t('error.config.genkey_gpg.exception')}\n#{e}"
    end

    # Load the config file
    def load_config
      config          = YAML.load_file(@config_file)
      @gpg_key        = config['gpg_key']
      @lang           = config['lang']
      @wallet_dir     = config['wallet_dir']
      @wallet_paths   = config['wallet_paths'] || {}
      @default_wallet = config['default_wallet']
      @gpg_exe        = config['gpg_exe']
      @password       = config['password'] || {}
      @pinmode        = config['pinmode'] || false

      raise if @gpg_key.empty? || @wallet_dir.empty?

      I18n.locale = @lang.to_sym
    rescue => e
      raise "#{I18n.t('error.config.load')}\n#{e}"
    end

    # Check if private key exist
    # @return [Boolean] true if the key exist, else false
    def check_gpg_key?
      ctx = GPGME::Ctx.new
      ctx.each_key(@gpg_key, true) do
        return true
      end

      false
    end

    # Change the path of one wallet
    # @param path [String]new directory path
    # @param wallet [String] wallet name
    def set_wallet_path(path, wallet)
      path = @wallet_dir if path == 'default'

      return if path == @wallet_dir && File.exist?("#{@wallet_dir}/#{wallet}.mpw")
      return if path == @wallet_paths[wallet]

      old_wallet_file =
        if @wallet_paths.key?(wallet)
          "#{@wallet_paths[wallet]}/#{wallet}.mpw"
        else
          "#{@wallet_dir}/#{wallet}.mpw"
        end

      FileUtils.mkdir_p(path) unless Dir.exist?(path)
      FileUtils.mv(old_wallet_file, "#{path}/#{wallet}.mpw") if File.exist?(old_wallet_file)

      if path == @wallet_dir
        @wallet_paths.delete(wallet)
      else
        @wallet_paths[wallet] = path
      end

      setup
    end
  end
end
