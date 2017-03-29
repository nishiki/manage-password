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

require 'i18n'

module MPW
class Item
  attr_accessor :id
  attr_accessor :group
  attr_accessor :host
  attr_accessor :protocol
  attr_accessor :user
  attr_accessor :port
  attr_accessor :otp
  attr_accessor :comment
  attr_accessor :last_edit
  attr_accessor :created

  # Constructor
  # Create a new item
  # @args: options -> a hash of parameter
  # raise an error if the hash hasn't the key name
  def initialize(options = {})
    if !options.key?(:host) || options[:host].to_s.empty?
      raise I18n.t('error.update.host_empty')
    end

    if !options.key?(:id) || options[:id].to_s.empty? || !options.key?(:created) || options[:created].to_s.empty?
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
  # @args: options -> a hash of parameter
  def update(options = {})
    if options.key?(:host) && options[:host].to_s.empty?
      raise I18n.t('error.update.host_empty')
    end

    @group     = options[:group]      if options.key?(:group)
    @host      = options[:host]       if options.key?(:host)
    @protocol  = options[:protocol]   if options.key?(:protocol)
    @user      = options[:user]       if options.key?(:user)
    @port      = options[:port].to_i  if options.key?(:port) && !options[:port].to_s.empty?
    @otp       = options[:otp]        if options.key?(:otp)
    @comment   = options[:comment]    if options.key?(:comment)
    @last_edit = Time.now.to_i        unless options.key?(:no_update_last_edit)
  end

  # Delete all data
  def delete
    @id        = nil
    @group     = nil
    @host      = nil
    @protocol  = nil
    @user      = nil
    @port      = nil
    @otp       = nil
    @comment   = nil
    @created   = nil
    @last_edit = nil
  end

  def empty?
    @id.to_s.empty?
  end

  def nil?
    false
  end

  private

  # Generate an random id
  def generate_id
    ([*('A'..'Z'), *('a'..'z'), *('0'..'9')]).sample(16).join
  end
end
end
