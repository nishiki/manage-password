#!/usr/bin/ruby
# author: nishiki
# mail: nishiki@yaegashi.fr
# info: a simple script who manage your passwords

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
			if not defined?(options[:id]) or not options[:id].to_s.empty? or 
			   not defined?(options[:created]) or not options[:created].to_s.empty?  
				@id      = generate_id
				@created = Time.now.to_i
			else
				@id      = options[:id]
				@created = options[:created]
			end

			update(options)
		end

		def update(options={})
			if defined?(options[:name]) and options[:name].to_s.empty?
				@error_msg = I18n.t('error.update.name_empty')
				return false
			end

			@name      = options[:name]       if defined?(options[:name])
			@group     = options[:group]      if defined?(options[:group])
			@host      = options[:host]       if defined?(options[:host])
			@protocol  = options[:protocol]   if defined?(options[:protocol])
			@user      = options[:user]       if defined?(options[:user])
			@password  = options[:password]   if defined?(options[:password])
			@port      = options[:port].to_i  if defined?(options[:port])
			@comment   = options[:comment]    if defined?(options[:comment])
			@last_edit = Time.now.to_i

			return true
		end

		def empty?
			return @name.to_s.empty?
		end

		def nil?
			return false
		end

		private
		def set_name(name)
			if name.to_s.empty?
				return false

			@name = name
			return true
		end

		private
		def generate_id
			return ([*('A'..'Z'),*('a'..'z'),*('0'..'9')]).sample(16).join
		end
	end
end	
