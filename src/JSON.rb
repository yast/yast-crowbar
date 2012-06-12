#--
# Copyright (c) 2009-2010 Novell, Inc.
# 
# All Rights Reserved.
# 
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License
# as published by the Free Software Foundation.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact Novell, Inc.
# 
# To contact Novell about this file by physical or electronic mail,
# you may find current contact information at www.novell.com
#++

require 'rubygems'
require 'json'

module JSON

  # read given json file and return the content as a map
  def self.read(file_name)
    ret = {}
    if File.exists?(file_name)
      ret = JSON.parse(File.read(file_name));
      ret = {} unless ret.is_a? Hash
    end
    return ret
  end

  # write whole json map into new file
  def self.write(json,file_name)
    if json.is_a? Hash
      File.open(file_name, 'w') do |f|  
        f.puts JSON.pretty_generate json
      end
    end
  end

end
