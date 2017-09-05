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

require 'i18n'
require 'uri'

module MPW
  class Item
    attr_accessor :created
    attr_accessor :comment
    attr_accessor :group
    attr_accessor :host
    attr_accessor :id
    attr_accessor :otp
    attr_accessor :port
    attr_accessor :protocol
    attr_accessor :last_edit
    attr_accessor :url
    attr_accessor :user

    # @param options [Hash] the option :host is required
    def initialize(**options)
      @host = ''

      if !options[:id] || !options[:created]
        @id = generate_id
        @created = Time.now.to_i
      else
        @id = options[:id]
        @created   = options[:created]
        @last_edit = options[:last_edit]
        options[:no_update_last_edit] = true
      end

      update(options)
    end

    # Update the item
    # @param options [Hash]
    def update(**options)
      unless options[:url] || options[:comment]
        raise I18n.t('error.update.host_and_comment_empty')
      end

      if options[:url]
        uri       = URI(options[:url])
        @host     = uri.host   || options[:url]
        @port     = uri.port   || nil
        @protocol = uri.scheme || nil
        @url      = options[:url]
      end

      @comment   = options[:comment] if options.key?(:comment)
      @group     = options[:group]   if options.key?(:group)
      @last_edit = Time.now.to_i     unless options.key?(:no_update_last_edit)
      @otp       = options[:otp]     if options.key?(:otp)
      @user      = options[:user]    if options.key?(:user)
    end

    # Delete all data
    def delete
      @id        = nil
      @comment   = nil
      @created   = nil
      @group     = nil
      @host      = nil
      @last_edit = nil
      @otp       = nil
      @port      = nil
      @protocol  = nil
      @url       = nil
      @user      = nil
    end

    def empty?
      @id.to_s.empty?
    end

    def nil?
      false
    end

    private

    # Generate an random id
    # @return [String] random string
    def generate_id
      [*('A'..'Z'), *('a'..'z'), *('0'..'9')].sample(16).join
    end
  end
end
