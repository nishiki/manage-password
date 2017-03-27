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
  def initialize(options={})
    if not options.has_key?(:host) or options[:host].to_s.empty?
      raise I18n.t('error.update.host_empty')
    end

    if not options.has_key?(:id) or options[:id].to_s.empty? or not options.has_key?(:created) or options[:created].to_s.empty?
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
  def update(options={})
    if options.has_key?(:host) and options[:host].to_s.empty?
      raise I18n.t('error.update.host_empty')
    end

    @group     = options[:group]      if options.has_key?(:group)
    @host      = options[:host]       if options.has_key?(:host)
    @protocol  = options[:protocol]   if options.has_key?(:protocol)
    @user      = options[:user]       if options.has_key?(:user)
    @port      = options[:port].to_i  if options.has_key?(:port) and not options[:port].to_s.empty?
    @otp       = options[:otp]        if options.has_key?(:otp)
    @comment   = options[:comment]    if options.has_key?(:comment)
    @last_edit = Time.now.to_i        if not options.has_key?(:no_update_last_edit)
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
    return @id.to_s.empty?
  end

  def nil?
    return false
  end

  # Generate an random id
  private
  def generate_id
    return ([*('A'..'Z'),*('a'..'z'),*('0'..'9')]).sample(16).join
  end
end
end
