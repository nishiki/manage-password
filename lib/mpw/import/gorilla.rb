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

require 'csv'

module MPW
  module Import
    # Import an export mpw file
    # @param file [String] the file path to import
    def self.gorilla(file)
      data = {}

      CSV.foreach(file, headers: true) do |row|
        id = row['uuid']
        comment =
          if row['title'] && row['notes']
            "#{row['title']} #{row['notes']}"
          elsif row['title']
            row['title']
          elsif row['notes']
            row['notes']
          end

        data[id] = {
          'group'    => row['group'],
          'host'     => row['url'],
          'user'     => row['user'],
          'password' => row['password'],
          'comment'  => comment
        }

        if row['url'] =~ %r{^((?<protocol>[a-z]+)://)?(?<host>[a-zA-Z0-9_.-]+)(:(?<port>[0-9]{1,5}))?$}
          data[id]['protocol'] = Regexp.last_match(:protocol)
          data[id]['port']     = Regexp.last_match(:port)
          data[id]['host']     = Regexp.last_match(:host)
        end
      end

      data
    end
  end
end
