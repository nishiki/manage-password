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
