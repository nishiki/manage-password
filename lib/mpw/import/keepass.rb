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
    # Import an keepass2 export csv file
    # @param file [String] the file path to import
    def self.keepass(file)
      data = {}

      CSV.foreach(file, headers: true) do |row|
        id = "#{row['Group']} #{row['Title']}"
        comment =
          if row['Title'] && row['Notes']
            "#{row['Title']} #{row['Notes']}"
          elsif row['Title']
            row['Title']
          elsif row['Notes']
            row['Notes']
          end

        data[id] = {
          'comment'  => comment,
          'group'    => row['Group'],
          'password' => row['Password'],
          'url'      => row['URL'],
          'user'     => row['Username']
        }
      end

      data
    end
  end
end
