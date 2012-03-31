#!/usr/bin/ruby
#
# Author:: xbrlware@bitstat.com
#
# Copyright:: 2009, 2010 bitstat (http://www.bitstat.com). All Rights Reserved.
#
# License:: Licensed under the Apache License, Version 2.0 (the "License");
#           you may not use this file except in compliance with the License.
#           You may obtain a copy of the License at
#
#           http://www.apache.org/licenses/LICENSE-2.0
#
#           Unless required by applicable law or agreed to in writing, software
#           distributed under the License is distributed on an "AS IS" BASIS,
#           WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
#           implied.
#           See the License for the specific language governing permissions and
#           limitations under the License.
#
module Xbrlware
  module MetaUtil # :nodoc:
    def self.introduce_instance_var(o, i_var_name, i_var_value)
      o.instance_variable_set("@#{i_var_name}", i_var_value)
      o.instance_eval %{
            def #{i_var_name}
              self.instance_variable_get("@#{i_var_name}")
            end
    }
    end

    def self.introduce_instance_writer(o, method_name, i_var_name)
      o.instance_eval %{
            def #{method_name}=(value)
              self.instance_variable_set("@#{i_var_name}", value)
            end
    }
    end

    def self.introduce_instance_alias(o, alias_name, actual_name)
      o.instance_eval %{
            alias :#{alias_name} :#{actual_name}
      }
    end

    def self.eval_on_instance(o, method_block)
      p "#{o.class}"
      o.instance_eval method_block
    end
  end
end