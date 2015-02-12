#!/usr/bin/ruby
# author: nishiki
# mail: nishiki@yaegashi.fr

require 'rubygems'
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
		attr_accessor :password
		attr_accessor :port
		attr_accessor :comment
		attr_accessor :last_edit
		attr_accessor :created

		def initialize(options={})
			if not options.has_key?(:name) or options[:name].to_s.empty?
				@error_msg = I18n.t('error.update.name_empty')
				raise ExceptionMPW @error_msg
			end

			if not options.has_key?(:id) or options[:id].to_s.empty? or not options.has_key?(:created) or options[:created].to_s.empty?  
				@id      = generate_id
				@created = Time.now.to_i
			else
				@id      = options[:id]
				@created = options[:created]
			end

			update(options)
		end

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
			@password  = options[:password]   if options.has_key?(:password)
			@port      = options[:port].to_i  if options.has_key?(:port) and not options[:port].to_s.empty?
			@comment   = options[:comment]    if options.has_key?(:comment)
			@last_edit = Time.now.to_i

			return true
		end

		def delete
			@id        = nil
			@name      = nil
			@group     = nil
			@host      = nil
			@protocol  = nil
			@user      = nil
			@password  = nil
			@port      = nil
			@comment   = nil
			@created   = nil
			@last_edit = nil

			return true
		end

		def empty?
			return @name.to_s.empty?
		end

		def nil?
			return false
		end

		private
		def generate_id
			return ([*('A'..'Z'),*('a'..'z'),*('0'..'9')]).sample(16).join
		end
	end
end	
