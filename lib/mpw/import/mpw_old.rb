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

require 'yaml'

module MPW
  module Import
    # Import an export mpw file
    # @param file [String] the file path to import
    def self.mpw_old(file)
      data = {}
      YAML.load_file(file).each do |id, item|
        url = ''
        url += "#{item['protocol']}://" if item['protocol']
        url += item['host']
        url += ":#{item['port']}" if item['port']

        data[id] = {
          'comment'  => item['comment'],
          'group'    => item['group'],
          'otp'      => item['otp'],
          'password' => item['password'],
          'url'      => url,
          'user'     => item['user']
        }
      end

      data
    end
  end
end
