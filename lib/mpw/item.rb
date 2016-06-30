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

	attr_accessor :error_msg

	attr_accessor :id
	attr_accessor :name
	attr_accessor :group
	attr_accessor :host
	attr_accessor :protocol
	attr_accessor :user
	attr_accessor :port
	attr_accessor :comment
	attr_accessor :last_edit
	attr_accessor :last_sync
	attr_accessor :created

	# Constructor
	# Create a new item
	# @args: options -> a hash of parameter
	# raise an error if the hash hasn't the key name 
	def initialize(options={})
		if not options.has_key?(:name) or options[:name].to_s.empty?
			@error_msg = I18n.t('error.update.name_empty')
			raise @error_msg
		end

		if not options.has_key?(:id) or options[:id].to_s.empty? or not options.has_key?(:created) or options[:created].to_s.empty?  
			@id      = generate_id
			@created = Time.now.to_i
		else
			@id        = options[:id]
			@created   = options[:created]
			@last_edit = options[:last_edit]
			options[:no_update_last_edit] = true
		end

		update(options)
	end

	# Update the item
	# @args: options -> a hash of parameter
	# @rtrn: true if the item is update
	def update(options={})
		if options.has_key?(:name) and options[:name].to_s.empty?
			@error_msg = I18n.t('error.update.name_empty')
			return false
		end

		@name      = options[:name]       if options.has_key?(:name)
		@group     = options[:group]      if options.has_key?(:group)
		@host      = options[:host]       if options.has_key?(:host)
		@protocol  = options[:protocol]   if options.has_key?(:protocol)
		@user      = options[:user]       if options.has_key?(:user)
		@port      = options[:port].to_i  if options.has_key?(:port) and not options[:port].to_s.empty?
		@comment   = options[:comment]    if options.has_key?(:comment)
		@last_edit = Time.now.to_i        if not options.has_key?(:no_update_last_edit)

		return true
	end

	# Update last_sync
	def set_last_sync
		@last_sync = Time.now.to_i
	end

	# Delete all data
	# @rtrn: true
	def delete
		@id        = nil
		@name      = nil
		@group     = nil
		@host      = nil
		@protocol  = nil
		@user      = nil
		@port      = nil
		@comment   = nil
		@created   = nil
		@last_edit = nil
		@last_sync = nil

		return true
	end

	def empty?
		return @name.to_s.empty?
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
